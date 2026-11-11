#!/usr/bin/env node

// kimctl: a KIM from the Mac, over its own serial port, through the KC Monitor's
// Wozmon-compatible console at 19200 8-N-1. No dependencies.
//
//   kimctl info                  the vectors, HW_PRESENT and the two ROMs against their files
//   kimctl read AAAA[.BBBB]      memory, as the monitor shows it
//   kimctl write AAAA HH HH ...  deposit bytes
//   kimctl run AAAA [--ms N]     run a program as a subroutine, then ESC if it hasn't returned
//   kimctl programs [NAME]       build, load and run the series' programs
//   kimctl compare               info and programs on the machine and on the KIMULATOR, side by side
//
//   --port PATH   the serial port (default: KIM_PORT, then the first /dev/cu.usbserial-*)
//   --emu         talk to a headless KIMULATOR instead of a machine
//   --json FILE   also write the result as JSON, to keep as a baseline
//   --rom FILE    the BIOS image: the KIMULATOR boots it, and `info` checks a machine against it
//                 (default: the KIMULATOR's bundled BIOS.bin)
//   --card-rom FILE  the same for the Keypad Card's KC Monitor (default: this repo's build),
//                 so a fresh firmware build can run on the KIMULATOR before an EEPROM is burned
//
// One session drives both machines. Headless, the KIMULATOR's stdin and stdout are its
// serial port, so the same code runs against both and a difference between them is a
// difference in the machines rather than in the test.
//
// What serial can and can't see. The monitor's console reads and writes memory and runs
// programs. It can't see the LED latch, which is write-only, or the LCD, and it can't
// press a key. So `programs` shows that a program loads, runs, prints what it should and
// comes back, and the lamps, the LCD and the keypad are still checked by eye and by hand.

import { execFileSync, spawn } from 'node:child_process'
import { closeSync, constants, existsSync, openSync, readdirSync, readFileSync, readSync, writeFileSync, writeSync } from 'node:fs'
import { basename, dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const DEV = resolve(REPO, '../..')
const KC_MONITOR = join(REPO, 'Firmware/KC Monitor/KC Monitor.bin')
const BIOS = join(DEV, 'NodeJS/6502-KIMULATOR/assets/roms/BIOS.bin')
const PROGRAMS = join(DEV, 'YouTube/6502-ASSEMBLY/01-KIM/Programs')

const BAUD = '19200'
const ESC = '\x1b'
const LOAD_ADDRESS = 0x0800
const DEPOSIT_BYTES = 16
const IRQ_PTR = 0x0300

const sleep = (ms) => new Promise((done) => setTimeout(done, ms))
const hex = (n, width = 2) => n.toString(16).toUpperCase().padStart(width, '0')

class KimError extends Error {}

// ---------------------------------------------------------------- the two links

/** The machine, on a USB serial port. Reads by polling, because a libuv poll on a USB
 *  serial tty never fires on this Mac. Opened first, because a setting made with stty
 *  doesn't outlive the last open descriptor. */
class SerialLink {
  constructor(path) {
    this.name = path
    this.fd = openSync(path, constants.O_RDWR | constants.O_NOCTTY | constants.O_NONBLOCK)
    execFileSync('stty', ['-f', path, BAUD, 'raw', '-echo', '-crtscts', 'clocal', 'cs8', '-cstopb', '-parenb', '-ixon', '-ixoff'])
    this.buffer = Buffer.alloc(4096)
  }

  write(text) {
    writeSync(this.fd, text, null, 'latin1')
  }

  read() {
    let text = ''
    for (;;) {
      try {
        const count = readSync(this.fd, this.buffer, 0, this.buffer.length, null)
        if (count <= 0) return text
        text += this.buffer.toString('latin1', 0, count)
      } catch (error) {
        if (error.code === 'EAGAIN') return text
        throw error
      }
    }
  }

  close() {
    closeSync(this.fd)
  }
}

/** A headless KIMULATOR, in real time, with the LED latch wired in. */
class EmuLink {
  constructor(options = {}) {
    this.name = 'KIMULATOR'
    this.pending = ''
    const roms = []
    if (options.rom) roms.push('--rom', options.rom)
    if (options.cardRom) roms.push('--card-rom', options.cardRom)
    this.child = spawn('6502-kim', ['run', '--headless', '--realtime', '--breadboard', 'led-latch', '--timeout', '30m', ...roms], {
      stdio: ['pipe', 'pipe', 'ignore'],
    })
    this.child.stdout.setEncoding('latin1')
    this.child.stdout.on('data', (data) => {
      this.pending += data
    })
  }

  write(text) {
    this.child.stdin.write(Buffer.from(text, 'latin1'))
  }

  read() {
    const text = this.pending
    this.pending = ''
    return text
  }

  close() {
    this.child.kill()
  }
}

// ---------------------------------------------------------------- the console

class Kim {
  constructor(link) {
    this.link = link
    this.received = ''
  }

  /** Everything that arrives within `ms`, or until `until` matches. */
  async collect(ms, until = null) {
    const end = Date.now() + ms
    for (;;) {
      this.received += this.link.read()
      if (until && until.test(this.received)) {
        const text = this.received
        this.received = ''
        return { text, matched: true }
      }
      if (Date.now() >= end) {
        const text = this.received
        this.received = ''
        return { text, matched: false }
      }
      await sleep(2)
    }
  }

  async command(line, ms = 15000) {
    this.link.write(`${line}\r`)
    const { text, matched } = await this.collect(ms, /> $/)
    if (!matched) throw new KimError(`no prompt after "${line}" within ${ms} ms. Got: ${JSON.stringify(text.slice(-120))}`)
    return text
  }

  /** ESC reaches the monitor from anywhere, the splash included. */
  async enter() {
    if (this.link instanceof EmuLink) {
      const { matched } = await this.collect(15000, /ESC TO START/)
      if (!matched) throw new KimError('the KIMULATOR never showed its splash')
    }
    for (let attempt = 0; attempt < 3; attempt++) {
      this.link.write(ESC)
      const { matched } = await this.collect(2000, /> $/)
      if (matched) return
    }
    throw new KimError(`no monitor prompt on ${this.link.name} after three ESCs. Is it powered, and on the right port?`)
  }

  async examine(start, end = start) {
    const text = await this.command(`${hex(start, 4)}.${hex(end, 4)}`, 120000)
    const bytes = []
    for (const line of text.split(/\r?\n/)) {
      const match = /^([0-9A-F]{4}): ((?:[0-9A-F]{2} ?)+)$/.exec(line.trim())
      if (match) bytes.push(...match[2].trim().split(' ').map((byte) => parseInt(byte, 16)))
    }
    const want = end - start + 1
    if (bytes.length !== want) throw new KimError(`read ${bytes.length} bytes at ${hex(start, 4)}, wanted ${want}`)
    return Uint8Array.from(bytes)
  }

  async deposit(address, bytes) {
    for (let offset = 0; offset < bytes.length; offset += DEPOSIT_BYTES) {
      const chunk = [...bytes.subarray(offset, offset + DEPOSIT_BYTES)].map((byte) => hex(byte)).join(' ')
      await this.command(`${hex(address + offset, 4)}: ${chunk}`)
    }
  }

  /** Run as a subroutine. If it hasn't returned after `ms`, ESC brings the monitor back. */
  async run(address, ms) {
    this.link.write(`${hex(address, 4)} R\r`)
    const { text, matched } = await this.collect(ms, /> $/)
    if (matched) return { output: text, returned: true }
    this.link.write(ESC)
    const after = await this.collect(3000, /> $/)
    if (!after.matched) throw new KimError(`no prompt after ESC at ${hex(address, 4)}: the program may have masked interrupts`)
    return { output: text, returned: false }
  }
}

// ---------------------------------------------------------------- what's checked

const sameBytes = (bytes, expected) => bytes.length === expected.length && bytes.every((byte, index) => byte === expected[index])

function firstDifference(bytes, expected, base) {
  const index = bytes.findIndex((byte, i) => byte !== expected[i])
  return index < 0 ? null : `${hex(base + index, 4)}: ${hex(bytes[index])}, file has ${hex(expected[index])}`
}

async function info(kim, options = {}) {
  const vectors = await kim.examine(0xfffa, 0xffff)
  const word = (at) => vectors[at] | (vectors[at + 1] << 8)
  const result = {
    nmi: hex(word(0), 4),
    reset: hex(word(2), 4),
    irq: hex(word(4), 4),
    hwPresent: hex((await kim.examine(0x030d))[0]),
  }

  const monitor = await kim.examine(0xe000, 0xffff)
  const monitorFile = readFileSync(options.cardRom ?? KC_MONITOR)
  result.kcMonitorMatchesFile = sameBytes(monitor, monitorFile)
  if (!result.kcMonitorMatchesFile) result.kcMonitorDifference = firstDifference(monitor, monitorFile, 0xe000)

  // $A000-$BFFF is the only part of the BIOS ROM showing with the Keypad Card's overlay in.
  const bios = await kim.examine(0xa000, 0xbfff)
  const biosFile = readFileSync(options.rom ?? BIOS).subarray(0x2000, 0x4000)
  result.biosMatchesFile = sameBytes(bios, biosFile)
  if (!result.biosMatchesFile) result.biosDifference = firstDifference(bios, biosFile, 0xa000)
  return result
}

function findPrograms(wanted) {
  const found = []
  for (const episode of readdirSync(PROGRAMS).sort()) {
    const folder = join(PROGRAMS, episode)
    if (!/^\d/.test(episode)) continue
    for (const name of readdirSync(folder)) {
      if (existsSync(join(folder, name, 'Makefile')) && (!wanted || name === wanted)) found.push({ episode, name, folder: join(folder, name) })
    }
  }
  return found
}

function build(program) {
  execFileSync('make', ['build'], { cwd: program.folder, stdio: 'ignore' })
  return readFileSync(join(program.folder, `${program.name}.bin`))
}

async function runProgram(kim, program, image, ms) {
  await kim.deposit(LOAD_ADDRESS, image)
  const loaded = await kim.examine(LOAD_ADDRESS, LOAD_ADDRESS + image.length - 1)
  const outcome = {
    name: program.name,
    bytes: image.length,
    loaded: sameBytes(loaded, image),
  }
  if (!outcome.loaded) {
    outcome.loadDifference = firstDifference(loaded, image, LOAD_ADDRESS)
    return outcome
  }
  const { output, returned } = await kim.run(LOAD_ADDRESS, ms)
  outcome.returned = returned
  // The first line is the monitor echoing the command back, so it isn't the program's.
  outcome.output = output.replace(/^[0-9A-F]{4} R\r?\n?/, '').replace(/\r?\n> $/, '').trim()
  const after = await kim.examine(LOAD_ADDRESS, LOAD_ADDRESS + image.length - 1)
  outcome.imageIntact = sameBytes(after, image)
  return outcome
}

/** ESC doesn't unhook IRQ_PTR, so a program that hooks it and is stopped by ESC leaves the
 *  pointer aimed at its own handler in RAM. The next program loaded over that handler
 *  takes the machine down at the next interrupt. So each one starts from the monitor's. */
async function programs(kim, wanted, ms) {
  const irqPtr = await kim.examine(IRQ_PTR, IRQ_PTR + 1)
  const results = []
  for (const program of findPrograms(wanted)) {
    const result = await runProgram(kim, program, build(program), ms)
    if (!sameBytes(await kim.examine(IRQ_PTR, IRQ_PTR + 1), irqPtr)) {
      await kim.deposit(IRQ_PTR, irqPtr)
      result.leftIrqHooked = true
    }
    results.push(result)
    report(result)
  }
  return results
}

function report(result) {
  const parts = [result.loaded ? 'loaded' : `LOAD FAILED (${result.loadDifference})`]
  if (result.loaded) {
    parts.push(result.returned ? 'returned' : 'still running, ESC came back')
    parts.push(result.imageIntact ? 'image intact' : 'image changed')
    if (result.leftIrqHooked) parts.push('left IRQ_PTR hooked (restored)')
  }
  console.log(`  ${result.name.padEnd(24)} ${String(result.bytes).padStart(5)} bytes  ${parts.join(', ')}`)
  if (result.output) console.log(`    says: ${JSON.stringify(result.output.slice(0, 200))}`)
}

// ---------------------------------------------------------------- the command line

function parse(argv) {
  const options = { args: [] }
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]
    if (arg === '--port') options.port = argv[++i]
    else if (arg === '--emu') options.emu = true
    else if (arg === '--json') options.json = argv[++i]
    else if (arg === '--ms') options.ms = Number(argv[++i])
    else if (arg === '--rom') options.rom = resolve(argv[++i])
    else if (arg === '--card-rom') options.cardRom = resolve(argv[++i])
    else options.args.push(arg)
  }
  return options
}

function findPort(given) {
  if (given) return given
  if (process.env.KIM_PORT) return process.env.KIM_PORT
  const ports = readdirSync('/dev').filter((name) => name.startsWith('cu.usbserial')).sort()
  if (!ports.length) throw new KimError('no /dev/cu.usbserial-* found: is the FTDI cable plugged in?')
  return `/dev/${ports[0]}`
}

function openLink(options) {
  return options.emu ? new EmuLink(options) : new SerialLink(findPort(options.port))
}

async function withKim(link, work) {
  const kim = new Kim(link)
  try {
    await kim.enter()
    return await work(kim)
  } finally {
    link.close()
  }
}

async function compare(options) {
  const ms = options.ms ?? 2000
  const sides = {}
  for (const [side, link] of [['machine', new SerialLink(findPort(options.port))], ['kimulator', new EmuLink(options)]]) {
    console.log(`\n${side}: ${link.name}`)
    sides[side] = await withKim(link, async (kim) => {
      const summary = await info(kim, options)
      console.log(summary)
      return { info: summary, programs: await programs(kim, null, ms) }
    })
  }
  const differences = []
  for (const key of new Set([...Object.keys(sides.machine.info), ...Object.keys(sides.kimulator.info)])) {
    if (sides.machine.info[key] !== sides.kimulator.info[key]) {
      differences.push(`${key}: machine ${sides.machine.info[key]}, KIMULATOR ${sides.kimulator.info[key]}`)
    }
  }
  sides.machine.programs.forEach((result, index) => {
    const other = sides.kimulator.programs[index]
    for (const key of ['loaded', 'returned', 'imageIntact', 'leftIrqHooked', 'output']) {
      if (result[key] !== other[key]) {
        differences.push(`${result.name} ${key}: machine ${JSON.stringify(result[key])}, KIMULATOR ${JSON.stringify(other[key])}`)
      }
    }
  })
  console.log(`\n${differences.length} difference(s)`)
  for (const difference of differences) console.log(`  ${difference}`)
  return { ...sides, differences }
}

async function main() {
  const options = parse(process.argv.slice(2))
  const [command, ...rest] = options.args
  let result
  switch (command) {
    case 'info':
      result = await withKim(openLink(options), (kim) => info(kim, options))
      console.log(result)
      break
    case 'read': {
      const [start, end] = rest[0].split('.').map((text) => parseInt(text, 16))
      await withKim(openLink(options), async (kim) => {
        process.stdout.write(await kim.command(`${hex(start, 4)}${end === undefined ? '' : `.${hex(end, 4)}`}`, 120000))
        console.log()
      })
      break
    }
    case 'write':
      await withKim(openLink(options), (kim) => kim.deposit(parseInt(rest[0], 16), Uint8Array.from(rest.slice(1).map((byte) => parseInt(byte, 16)))))
      break
    case 'run':
      result = await withKim(openLink(options), (kim) => kim.run(parseInt(rest[0], 16), options.ms ?? 2000))
      console.log(result)
      break
    case 'programs':
      result = await withKim(openLink(options), (kim) => programs(kim, rest[0], options.ms ?? 2000))
      break
    case 'compare':
      result = await compare(options)
      break
    default:
      console.error(`usage: kimctl info | read AAAA[.BBBB] | write AAAA HH ... | run AAAA | programs [NAME] | compare\n       [--port PATH] [--emu] [--ms N] [--json FILE] [--rom FILE] [--card-rom FILE]  (see ${basename(fileURLToPath(import.meta.url))})`)
      process.exit(2)
  }
  if (options.json && result) writeFileSync(options.json, `${JSON.stringify(result, null, 2)}\n`)
}

main().catch((error) => {
  console.error(error instanceof KimError ? `kimctl: ${error.message}` : error)
  process.exit(1)
})
