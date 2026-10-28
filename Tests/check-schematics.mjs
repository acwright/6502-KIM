#!/usr/bin/env node
// check-schematics — evaluate the KIM Board's address decoding from its schematic.
//
// Built on 6502-ACE's Tests/check-schematics.mjs, for the same reason: the ACE's bank latch was
// wrong twice, and both times the logic looked right on paper. So this does not trust anyone's
// reading of the gates. It asks KiCad for the KIM Board's netlist, builds the glue logic from
// the parts it finds there, and drives every address, as a read and as a write, with PHI2 high
// and low, the KIM enable jumper fitted and open, a cartridge in the card slot and out, and the
// IO ENABLE switches all on and then each one off: 9,437,184 bus states. Every select, strobe
// and enable is compared with the memory map below (KIM-PLAN.md section 2). Nets nobody drives
// come out as unknown, so a missing wire fails too.
//
// Usage:  node Tests/check-schematics.mjs [schematic]
// The schematic defaults to the KIM Board Rev 1.0's.
// Needs kicad-cli: on the PATH, at the macOS default, or named by KICAD_CLI.

import { execFileSync } from 'node:child_process'
import { mkdtempSync, readFileSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..')
const BOARD = process.argv[2] ?? join(ROOT, 'Hardware', 'KIM Board', 'Rev 1.0', 'KIM Board.kicad_sch')

// ---- The board, as built --------------------------------------------------------------

// The parts the checks read, by designator, with the value each must have. The value is checked
// before anything else, so a schematic that has been re-annotated since this table was written
// fails with the part it moved, rather than checking the wrong chip.
const PARTS = {
  cpu: ['U1', '65C02'],
  ram: ['U2', 'AS6C62256'],
  rom: ['U3', 'AT28C256'],
  pia: ['U8', 'W65C21N'],
  monitor: ['U9', 'AT28C64'],
  acia: ['U15', 'R6551AP'],
  osc: ['X1', '1 MHz'],
  kim: ['J1', 'KIM ENABLE'],
  slot: ['J4', 'CART'],
  bus: ['J5', 'BUS'],
  headers: ['J6', 'BREADBOARD HEADERS'],
  resetQ: ['Q1', '2N3904'],
  ioEnable: ['SW25', 'IO ENABLE']
}

// ---- The memory map -------------------------------------------------------------------
//
// a = address, r = 1 for a read, p = PHI2, j = 1 with the KIM enable jumper fitted, c = 1 with a
// cartridge in the card slot, sw[k] = 1 while IO ENABLE switch k+1 is on. A cartridge grounds
// EXP0 and EXP1 (HRDB) and answers $C000-$FFFF, as the VCS ROM Cart and Flash Cart do.

const io = (a, k) => a >= 0x8000 + k * 0x400 && a < 0x8400 + k * 0x400   // IO k+1
const low = (cond) => cond ? 0 : 1
const RB = (s) => low(s.r && s.p)
const WB = (s) => low(!s.r && s.p)
const romHigh = (s) => !s.j && !s.c                                         // HRDB high

const PINS = [
  ['ram', 20, 'RAM /CE', s => low(s.a < 0x8000)],
  ['ram', 22, 'RAM /OE', RB],
  ['ram', 27, 'RAM /WE', WB],
  // the BIOS ROM: $A000-$FFFF, or $A000-$BFFF while HRDB is low
  ['rom', 20, 'ROM /CE', s => low(s.a >= 0xA000 && (s.a < 0xC000 || romHigh(s)))],
  ['rom', 22, 'ROM /OE', RB],
  ['rom', 27, 'ROM /WE (tied high)', () => 1],
  // the KIM: the PIA at $C000-$DFFF and the KC Monitor ROM at $E000-$FFFF, only with the jumper fitted
  ['pia', 23, 'PIA CS2B', s => low(s.j && s.a >= 0xC000 && s.a < 0xE000)],
  ['pia', 22, 'PIA CS0', () => 1],
  ['pia', 24, 'PIA CS1', () => 1],
  ['monitor', 20, 'Keypad ROM /CE', s => low(s.j && s.a >= 0xE000 && s.r && s.p)],
  ['monitor', 22, 'Keypad ROM /OE', s => low(s.j && s.a >= 0xE000 && s.r && s.p)],
  ['monitor', 27, 'Keypad ROM /WE (tied high)', () => 1],
  // the serial port on IO5, $9000-$93FF, through DIP switch 5
  ['acia', 3, 'ACIA CS1B', s => low(io(s.a, 4) && s.sw[4])],
  ['acia', 2, 'ACIA CS0', () => 1],
  // the eight selects on the breadboard headers (pads 42-49), after the DIP switch
  ...[0, 1, 2, 3, 4, 5, 6, 7].map(k => ['headers', 42 + k, `IO${k + 1}B on the breadboard headers`, s => low(io(s.a, k) && s.sw[k])]),
  // HRDB on the slot (EXP1, pin 4), and the KIM enable: a cartridge never pulls KIMB low
  ['slot', 4, 'HRDB', s => romHigh(s) ? 1 : 0],
  ['kim', 1, 'KIMB', s => s.j ? 0 : 1]
]

// What drives the data bus on a read, and what takes it on a write.
const READERS = [
  ['RAM', v => v('ram', 20) === 0 && v('ram', 22) === 0],
  ['ROM', v => v('rom', 20) === 0 && v('rom', 22) === 0],
  ['PIA', (v, s) => v('pia', 22) === 1 && v('pia', 24) === 1 && v('pia', 23) === 0 && s.r && s.p],
  ['Keypad ROM', v => v('monitor', 20) === 0 && v('monitor', 22) === 0],
  ['ACIA', (v, s) => v('acia', 2) === 1 && v('acia', 3) === 0 && s.r && s.p],
  ['cart', (v, s) => s.c && s.a >= 0xC000 && s.r && s.p]
]
const WRITERS = [
  ['RAM', v => v('ram', 20) === 0 && v('ram', 27) === 0],
  ['ROM', v => v('rom', 20) === 0 && v('rom', 27) === 0],
  ['PIA', (v, s) => v('pia', 22) === 1 && v('pia', 24) === 1 && v('pia', 23) === 0 && !s.r && s.p],
  ['Keypad ROM', v => v('monitor', 20) === 0 && v('monitor', 27) === 0],
  ['ACIA', (v, s) => v('acia', 2) === 1 && v('acia', 3) === 0 && !s.r && s.p]
]

// KIM-PLAN.md section 2's table, read with PHI2 high. A fitted jumper with a cartridge in is two
// devices at once, a user error the plan documents; it is the only state with two.
function expectedReaders(s) {
  if (!s.r || !s.p) return []
  const { a, j, c } = s
  if (a < 0x8000) return ['RAM']
  if (a < 0xA000) return io(a, 4) && s.sw[4] ? ['ACIA'] : []
  if (a < 0xC000) return ['ROM']
  const kim = a < 0xE000 ? 'PIA' : 'Keypad ROM'
  if (j) return c ? [kim, 'cart'] : [kim]
  return c ? ['cart'] : ['ROM']
}
function expectedWriters(s) {
  if (s.r || !s.p) return []
  const { a } = s
  if (a < 0x8000) return ['RAM']
  if (io(a, 4) && s.sw[4]) return ['ACIA']
  if (s.j && a >= 0xC000 && a < 0xE000) return ['PIA']
  return []
}

// ---- Netlist --------------------------------------------------------------------------

function kicadCli() {
  const candidates = [process.env.KICAD_CLI, '/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli', 'kicad-cli']
  for (const c of candidates.filter(Boolean)) {
    try { execFileSync(c, ['version'], { stdio: 'ignore' }); return c } catch {}
  }
  throw new Error('kicad-cli not found; set KICAD_CLI')
}

function sexpr(text) {
  const stack = [[]]
  const re = /\s*(?:(\()|(\))|"((?:[^"\\]|\\.)*)"|([^\s()"]+))/gy
  let m
  while ((m = re.exec(text)) && m[0].length) {
    if (m[1]) stack.push([])
    else if (m[2]) { const x = stack.pop(); stack[stack.length - 1].push(x) }
    else stack[stack.length - 1].push(m[3] !== undefined ? m[3].replace(/\\(.)/g, '$1') : m[4])
  }
  return stack[0][0]
}
const kids = (node, key) => node.filter(c => Array.isArray(c) && c[0] === key)
const kid = (node, key) => kids(node, key)[0]

function netlist(cli, sch, dir) {
  const out = join(dir, 'kim.net')
  execFileSync(cli, ['sch', 'export', 'netlist', '--format', 'kicadsexpr', '-o', out, sch], { stdio: 'ignore' })
  const root = sexpr(readFileSync(out, 'utf8'))
  const comps = new Map()
  for (const c of kids(kid(root, 'components'), 'comp')) comps.set(kid(c, 'ref')[1], kid(c, 'value')[1])
  const nets = []
  for (const n of kids(kid(root, 'nets'), 'net')) {
    nets.push({ name: kid(n, 'name')[1], nodes: kids(n, 'node').map(x => [kid(x, 'ref')[1], Number(kid(x, 'pin')[1])]) })
  }
  return { comps, nets }
}

// Joins nets: switches closed, jumpers fitted.
class Board {
  constructor({ comps, nets }) {
    this.parent = new Map(); this.pinNet = new Map(); this.comps = comps; this.names = new Map()
    for (const n of nets) {
      this.parent.set(n.name, n.name)
      this.names.set(n.name, n.name)
      for (const [ref, pin] of n.nodes) this.pinNet.set(`${ref}.${pin}`, n.name)
    }
    this.parts = {}
    for (const [name, [ref, value]] of Object.entries(PARTS)) {
      const found = comps.get(ref)
      if (found !== value) {
        throw new Error(`the ${name} part should be ${ref}, a ${value}, but ${ref} is ` +
          `${found === undefined ? 'not on the sheet' : `a ${found}`} — re-annotated? Update PARTS.`)
      }
      this.parts[name] = ref
    }
  }
  find(x) { while (this.parent.get(x) !== x) { const p = this.parent.get(this.parent.get(x)); this.parent.set(x, p); x = p } return x }
  union(a, b) { a = this.find(a); b = this.find(b); if (a !== b) this.parent.set(b, a) }
  net(ref, pin) { const n = this.pinNet.get(`${ref}.${pin}`); return n === undefined ? undefined : this.find(n) }
  pin(name, pin) { return this.net(this.parts[name], pin) }
  join(refA, pinA, refB, pinB) {
    const a = this.pinNet.get(`${refA}.${pinA}`), b = this.pinNet.get(`${refB}.${pinB}`)
    if (a === undefined || b === undefined) throw new Error(`cannot join ${refA}.${pinA} and ${refB}.${pinB}`)
    this.union(a, b)
  }
  netNamed(name) { return this.names.has(name) ? this.find(name) : undefined }
}

// The board in one setting: the KIM jumper as given, and IO ENABLE switch k+1 on while sw[k].
// Switch k joins pin k to pin 17-k.
function assemble(net, j, sw) {
  const board = new Board(net)
  if (j) board.join(board.parts.kim, 1, board.parts.kim, 2)
  for (let k = 1; k <= 8; k++) if (sw[k - 1]) board.join(board.parts.ioEnable, k, board.parts.ioEnable, 17 - k)
  return board
}

// ---- The logic ------------------------------------------------------------------------

const X = 2
const nand = ins => ins.includes(0) ? 1 : ins.every(v => v === 1) ? 0 : X
const GATES = {
  '74HC00': { fn: nand, units: [[[1, 2], 3], [[4, 5], 6], [[9, 10], 8], [[12, 13], 11]] }
}
const Y138 = [15, 14, 13, 12, 11, 10, 9, 7]

// Every gate output, pull-up and diode becomes one node; the nodes are sorted so that one pass
// settles the whole board. A loop in the glue logic is reported, not iterated.
function compile(board, inputs) {
  const ids = new Map()
  const id = n => { if (n === undefined) return -1; if (!ids.has(n)) ids.set(n, ids.size); return ids.get(n) }
  const vcc = board.netNamed('VCC'), gnd = board.netNamed('GND')
  const nodes = []   // { out, ins, fn, what }
  for (const [ref, value] of board.comps) {
    const g = GATES[value]
    if (g) {
      for (const [ins, out] of g.units) {
        const o = board.net(ref, out)
        if (o === undefined) continue
        nodes.push({ out: o, ins: ins.map(p => board.net(ref, p)), fn: g.fn, what: `${ref}.${out}` })
      }
    } else if (value === '74HC138') {
      const ins = [1, 2, 3, 4, 5, 6].map(p => board.net(ref, p))
      Y138.forEach((pin, k) => {
        const o = board.net(ref, pin)
        if (o === undefined) return
        nodes.push({
          out: o, ins, what: `${ref}.${pin}`,
          fn: ([a, b, c, e1, e2, e3]) => {
            if (e1 === 1 || e2 === 1 || e3 === 0) return 1
            if ([a, b, c, e1, e2, e3].includes(X)) return X
            return (a | b << 1 | c << 2) === k ? 0 : 1
          }
        })
      })
    }
  }
  // Pull-ups to VCC, and Schottky diodes pulling a pulled-up net low (the KIM enable's BAT85).
  const driven = new Set(nodes.map(n => n.out))
  for (const o of driven) {
    const count = nodes.filter(n => n.out === o).length
    if (count > 1) throw new Error(`net ${o} has ${count} gate outputs driving it`)
  }
  const pulled = new Map()
  for (const [ref, value] of board.comps) {
    if (!/^R\d+$/.test(ref)) continue
    const a = board.net(ref, 1), b = board.net(ref, 2)
    const n = a === vcc ? b : b === vcc ? a : undefined
    // a pull-up on a net a jumper has tied to GND (KIMB with the KIM jumper fitted) does nothing
    if (n !== undefined && n !== gnd && n !== vcc && !driven.has(n) && !inputs.has(n)) pulled.set(n, [])
  }
  for (const [ref, value] of board.comps) {
    if (!/^D\d+$/.test(ref) || !/BAT85/.test(value)) continue
    const k = board.net(ref, 1), a = board.net(ref, 2)
    if (pulled.has(a)) pulled.get(a).push(k)
  }
  for (const [n, cathodes] of pulled) {
    nodes.push({ out: n, ins: cathodes, what: `pull-up on ${n}`, fn: ks => ks.includes(0) ? 0 : ks.includes(X) ? X : 1 })
  }
  // topological order
  const byOut = new Map(nodes.map(n => [n.out, n]))
  const order = [], state = new Map()
  const visit = (n, path) => {
    if (state.get(n) === 2) return
    if (state.get(n) === 1) throw new Error(`the logic has a loop through ${[...path, n.what].join(' -> ')}`)
    state.set(n, 1)
    for (const i of n.ins) { const d = byOut.get(i); if (d) visit(d, [...path, n.what]) }
    state.set(n, 2); order.push(n)
  }
  for (const n of nodes) visit(n, [])
  const fixed = new Map([[vcc, 1], [gnd, 0]])
  return {
    order: order.map(n => ({ out: id(n.out), ins: n.ins.map(id), fn: n.fn })),
    inputs: [...inputs].map(n => id(n)),
    fixed: [...fixed].map(([n, v]) => [id(n), v]),
    id, size: () => ids.size
  }
}

function evaluate(logic, values, inputVals) {
  values.fill(X)
  for (const [i, v] of logic.fixed) if (i >= 0) values[i] = v
  logic.inputs.forEach((i, k) => { values[i] = inputVals[k] })
  for (const g of logic.order) {
    const ins = g.ins.map(i => i < 0 ? X : values[i])
    values[g.out] = g.fn(ins)
  }
}

// ---- Rules ----------------------------------------------------------------------------

const hex = a => '$' + a.toString(16).toUpperCase().padStart(4, '0')

function checkDecode(net) {
  const failures = new Map()
  const fail = (what, s, got, want) => {
    const f = failures.get(what) ?? { count: 0, examples: [] }
    f.count++
    if (f.examples.length < 6) {
      f.examples.push(`${hex(s.a)} ${s.r ? 'read ' : 'write'} PHI2=${s.p} KIM ${s.j ? 'fitted' : 'open'}${s.c ? ' cart' : ''}` +
        `${s.sw.includes(0) ? ` switch ${s.sw.indexOf(0) + 1} off` : ''}: got ${got}, want ${want}`)
    }
    failures.set(what, f)
  }
  const settings = [[1, 1, 1, 1, 1, 1, 1, 1]]
  for (let k = 0; k < 8; k++) settings.push([1, 1, 1, 1, 1, 1, 1, 1].map((v, i) => i === k ? 0 : 1))
  let states = 0
  for (const sw of settings) for (const j of [0, 1]) {
    const board = assemble(net, j, sw)
    const cpu = pin => board.pin('cpu', pin)
    const addr = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 22, 23, 24, 25].map(cpu)  // A0-A15
    const rwb = cpu(34), phi2 = cpu(37), hrdb = board.pin('slot', 4)
    for (const c of [0, 1]) {
      // a cartridge grounds HRDB; without one, the pull-up and the KIM enable's diode decide it
      const inputs = new Set([...addr, rwb, phi2, ...(c ? [hrdb] : [])])
      const logic = compile(board, inputs)
      const values = new Uint8Array(logic.size() + 1)
      const pins = PINS.map(([part, pin, what, want]) => {
        const n = board.pin(part, pin)
        if (n === undefined) throw new Error(`${board.parts[part]} pin ${pin} (${what}) is not in the netlist`)
        return [logic.id(n), what, want]
      })
      const v = (part, pin) => values[logic.id(board.pin(part, pin))]
      const inputOrder = [...inputs]
      for (let p = 0; p <= 1; p++) for (let r = 0; r <= 1; r++) {
        for (let a = 0; a < 0x10000; a++) {
          const s = { a, r, p, j, c, sw }
          const vals = inputOrder.map(n => {
            const i = addr.indexOf(n)
            return i >= 0 ? a >> i & 1 : n === rwb ? r : n === phi2 ? p : 0
          })
          evaluate(logic, values, vals)
          states++
          for (const [i, what, want] of pins) {
            const w = want(s), got = values[i]
            if (got !== w) fail(what, s, got === X ? 'unknown' : got, w)
          }
          const readers = READERS.filter(([, f]) => f(v, s)).map(([n]) => n)
          const wantR = expectedReaders(s)
          if (readers.join('+') !== wantR.join('+')) fail('devices driving the data bus (section 2\'s table)', s, readers.join('+') || 'none', wantR.join('+') || 'none')
          if (readers.length > 1 && !(j && c && a >= 0xC000)) fail('two devices on the data bus', s, readers.join('+'), 'one')
          const writers = WRITERS.filter(([, f]) => f(v, s)).map(([n]) => n)
          const wantW = expectedWriters(s)
          if (writers.join('+') !== wantW.join('+')) fail('devices taking a write', s, writers.join('+') || 'none', wantW.join('+') || 'none')
        }
      }
    }
  }
  return [states, [...failures].map(([what, f]) => `${what}: wrong in ${f.count} bus states, e.g.\n        ${f.examples.join('\n        ')}`)]
}

// The CPU, the PIA and the ACIA all run from the 1 MHz can.
function checkClock(net) {
  const board = assemble(net, 1, [1, 1, 1, 1, 1, 1, 1, 1])
  const errs = []
  const out = board.pin('osc', 8)
  for (const [part, pin, what] of [['cpu', 37, 'CPU PHI2'], ['pia', 25, 'PIA PHI2'], ['acia', 27, 'ACIA PHI2']]) {
    if (board.pin(part, pin) !== out) errs.push(`${what} (${board.parts[part]}.${pin}) is not on ${board.parts.osc}'s output (pin 8)`)
  }
  return errs
}

// One 10 k pull-up on each shared line, on this board (PLAN.md P1.1); SOB tied to VCC, as the
// W65C02S datasheet asks of an unused input-only pin; and RESB pulled low only by the reset
// transistor, or by whatever is in the slot or wired on the breadboards.
function checkSharedLines(net) {
  const board = new Board(net)
  const errs = []
  const vcc = board.netNamed('VCC'), gnd = board.netNamed('GND')
  const lines = { IRQB: 4, NMIB: 6, RESB: 40, RDY: 2, BE: 36 }
  if (board.pin('cpu', 38) !== vcc) errs.push(`SOB (${board.parts.cpu}.38) is not tied to VCC`)
  for (const [name, pin] of Object.entries(lines)) {
    const n = board.pin('cpu', pin)
    const rs = [...board.comps].filter(([ref]) => /^R\d+$/.test(ref) &&
      ((board.net(ref, 1) === n && board.net(ref, 2) === vcc) || (board.net(ref, 2) === n && board.net(ref, 1) === vcc)))
    if (rs.length !== 1) errs.push(`${name} has ${rs.length} pull-ups to VCC: ${rs.map(([r, v]) => `${r} ${v}`).join(', ') || 'none'}`)
    else if (rs[0][1] !== '10k') errs.push(`${name}'s pull-up ${rs[0][0]} is ${rs[0][1]}, not 10k`)
  }
  const resb = board.pin('cpu', 40)
  const q = board.parts.resetQ
  if (board.net(q, 3) !== resb) errs.push(`the reset transistor's collector (${q}.3) is not on RESB`)
  if (board.net(q, 1) !== gnd) errs.push(`the reset transistor's emitter (${q}.1) is not on GND`)
  const allowed = new Set([
    `${board.parts.cpu}.40`, `${board.parts.pia}.34`, `${board.parts.acia}.4`, `${q}.3`,
    `${board.parts.slot}.3`, `${board.parts.bus}.3`, `${board.parts.headers}.3`
  ])
  for (const [key, n] of board.pinNet) {
    if (board.find(n) !== resb || allowed.has(key)) continue
    const [ref] = key.split('.')
    if (/^R\d+$/.test(ref) && [1, 2].some(p => board.net(ref, p) === vcc)) continue   // the pull-up
    errs.push(`${key} (${board.comps.get(ref)}) is on RESB`)
  }
  return errs
}

// ---- Main -----------------------------------------------------------------------------

const cli = kicadCli()
const dir = mkdtempSync(join(tmpdir(), 'kim-check-'))
let failed = 0
try {
  const net = netlist(cli, BOARD, dir)
  const [states, decode] = checkDecode(net)
  const results = [
    [`address decoding (${states.toLocaleString('en-US')} bus states)`, decode],
    ['clock', checkClock(net)],
    ['shared lines, SOB and RESB', checkSharedLines(net)]
  ]
  console.log('KIM Board Rev 1.0')
  for (const [what, errs] of results) {
    console.log(`  ${errs.length ? 'FAIL' : 'ok  '}  ${what}`)
    for (const e of errs) console.log(`      ${e}`)
    failed += errs.length
  }
} finally {
  rmSync(dir, { recursive: true, force: true })
}
process.exit(failed ? 1 : 0)
