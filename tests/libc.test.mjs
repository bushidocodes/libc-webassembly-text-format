// Correctness tests for the implemented libc.wat functions.
//
// The compiled module (libc.wasm) is loaded and instantiated with no imports.
// Multi-value WAT results surface as JS arrays; i64 params/results surface as
// BigInt. Run with `npm test` (builds the wasm first) or `node --test` against
// an already-built libc.wasm.

import { test, before } from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { mkdtempSync, writeFileSync, readFileSync, rmSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const wasmPath = fileURLToPath(new URL("../libc.wasm", import.meta.url));

// Assemble a small WAT source to wasm bytes with wat2wasm (already required to
// build libc.wasm). Used to build a comparator module for the qsort/bsearch
// tests, since a funcref table slot must hold a real wasm function.
const assemble = (watSource) => {
  const dir = mkdtempSync(join(tmpdir(), "libc-test-"));
  try {
    const watFile = join(dir, "m.wat");
    const wasmFile = join(dir, "m.wasm");
    writeFileSync(watFile, watSource);
    execFileSync("wat2wasm", [watFile, "-o", wasmFile]);
    return readFileSync(wasmFile);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
};

let libc;
let mem;

before(async () => {
  const bytes = await readFile(wasmPath);
  const { instance } = await WebAssembly.instantiate(bytes);
  libc = instance.exports;
  mem = new Uint8Array(libc.memory.buffer);
});

const C = (ch) => ch.charCodeAt(0);

// Write a JS string as a NUL-terminated C string at `offset`; returns offset.
const putStr = (offset, str) => {
  let i = 0;
  for (; i < str.length; i++) mem[offset + i] = str.charCodeAt(i);
  mem[offset + i] = 0;
  return offset;
};

// Read a NUL-terminated C string starting at `offset`.
const getStr = (offset) => {
  let end = offset;
  while (mem[end] !== 0) end++;
  return new TextDecoder().decode(mem.subarray(offset, end));
};

// ---------------------------------------------------------------------------
// ctype.h
// ---------------------------------------------------------------------------

test("isdigit", () => {
  assert.equal(libc.isdigit(C("0")), 1);
  assert.equal(libc.isdigit(C("9")), 1);
  assert.equal(libc.isdigit(C("a")), 0);
  assert.equal(libc.isdigit(C("/")), 0); // 47, just below '0'
});

test("isalpha / islower / isupper", () => {
  assert.equal(libc.isalpha(C("a")), 1);
  assert.equal(libc.isalpha(C("Z")), 1);
  assert.equal(libc.isalpha(C("0")), 0);
  assert.equal(libc.islower(C("a")), 1);
  assert.equal(libc.islower(C("A")), 0);
  assert.equal(libc.isupper(C("A")), 1);
  assert.equal(libc.isupper(C("a")), 0);
});

test("isalnum", () => {
  assert.equal(libc.isalnum(C("a")), 1);
  assert.equal(libc.isalnum(C("7")), 1);
  assert.equal(libc.isalnum(C(" ")), 0);
});

test("isspace / isblank", () => {
  assert.equal(libc.isspace(C(" ")), 1);
  assert.equal(libc.isspace(C("\t")), 1);
  assert.equal(libc.isspace(C("\n")), 1);
  assert.equal(libc.isspace(C("a")), 0);
  assert.equal(libc.isblank(C(" ")), 1);
  assert.equal(libc.isblank(C("\t")), 1);
  assert.equal(libc.isblank(C("\n")), 0);
});

test("iscntrl / isprint / isgraph", () => {
  assert.equal(libc.iscntrl(0), 1);
  assert.equal(libc.iscntrl(127), 1);
  assert.equal(libc.iscntrl(C("a")), 0);
  assert.equal(libc.isprint(C(" ")), 1);
  assert.equal(libc.isprint(C("a")), 1);
  assert.equal(libc.isprint(0), 0);
  assert.equal(libc.isgraph(C(" ")), 0); // space is printable but not graphical
  assert.equal(libc.isgraph(C("a")), 1);
});

test("ispunct", () => {
  assert.equal(libc.ispunct(C("!")), 1);
  assert.equal(libc.ispunct(C("a")), 0);
  assert.equal(libc.ispunct(C(" ")), 0);
});

test("isxdigit / isascii", () => {
  assert.equal(libc.isxdigit(C("0")), 1);
  assert.equal(libc.isxdigit(C("f")), 1);
  assert.equal(libc.isxdigit(C("F")), 1);
  assert.equal(libc.isxdigit(C("g")), 0);
  assert.equal(libc.isascii(65), 1);
  assert.equal(libc.isascii(127), 1);
  assert.equal(libc.isascii(128), 0);
});

test("toupper / tolower", () => {
  assert.equal(libc.toupper(C("a")), C("A"));
  assert.equal(libc.toupper(C("A")), C("A")); // unchanged
  assert.equal(libc.toupper(C("1")), C("1")); // non-alpha unchanged
  assert.equal(libc.tolower(C("A")), C("a"));
  assert.equal(libc.tolower(C("a")), C("a"));
});

// ---------------------------------------------------------------------------
// stdlib.h
// ---------------------------------------------------------------------------

test("abs", () => {
  assert.equal(libc.abs(-5), 5);
  assert.equal(libc.abs(5), 5);
  assert.equal(libc.abs(0), 0);
});

test("labs", () => {
  assert.equal(libc.labs(-5n), 5n);
  assert.equal(libc.labs(5n), 5n);
  assert.equal(libc.labs(0n), 0n);
});

test("div returns (quotient, remainder)", () => {
  assert.deepEqual(libc.div(7, 2), [3, 1]);
  assert.deepEqual(libc.div(-7, 2), [-3, -1]); // C truncates toward zero
  assert.deepEqual(libc.div(6, 3), [2, 0]);
});

test("ldiv returns (quotient, remainder)", () => {
  assert.deepEqual(libc.ldiv(7n, 2n), [3n, 1n]);
  assert.deepEqual(libc.ldiv(-7n, 2n), [-3n, -1n]);
});

test("itoa_s decimal", () => {
  const offset = 256;
  const decode = (base, len) =>
    new TextDecoder().decode(mem.subarray(base, base + len));

  let [base, len] = libc.itoa_s(123, offset, 10);
  assert.equal(decode(base, len), "123");

  [base, len] = libc.itoa_s(-123, offset, 10);
  assert.equal(decode(base, len), "-123");

  [base, len] = libc.itoa_s(0, offset, 10);
  assert.equal(decode(base, len), "0");

  [base, len] = libc.itoa_s(7, offset, 10);
  assert.equal(decode(base, len), "7");
});

test("atoi parses signed decimal with leading whitespace", () => {
  assert.equal(libc.atoi(putStr(2000, "123")), 123);
  assert.equal(libc.atoi(putStr(2000, "-123")), -123);
  assert.equal(libc.atoi(putStr(2000, "+45")), 45);
  assert.equal(libc.atoi(putStr(2000, "   7")), 7);
  assert.equal(libc.atoi(putStr(2000, "42abc")), 42); // stops at first non-digit
  assert.equal(libc.atoi(putStr(2000, "abc")), 0); // no digits
  assert.equal(libc.atoi(putStr(2000, "")), 0);
  assert.equal(libc.atoi(putStr(2000, "0")), 0);
});

test("rand matches the reference LCG and is seedable", () => {
  // Reference implementation of the same generator, in 64-bit (unsigned long)
  // arithmetic, to validate the WAT against the algorithm it implements.
  let next = 1n;
  const mask = (1n << 64n) - 1n;
  const ref = () => {
    next = (next * 1103515245n + 12345n) & mask;
    return Number((next >> 16n) & 0x7fffn);
  };

  libc.srand(1);
  for (let i = 0; i < 20; i++) assert.equal(libc.rand(), ref());

  // every value lies within [0, RAND_MAX]
  for (let i = 0; i < 100; i++) {
    const r = libc.rand();
    assert.ok(r >= 0 && r <= 32767, `rand() out of range: ${r}`);
  }

  // seeding resets the sequence deterministically
  libc.srand(42);
  const a = [libc.rand(), libc.rand(), libc.rand()];
  libc.srand(42);
  const b = [libc.rand(), libc.rand(), libc.rand()];
  assert.deepEqual(a, b);
});

test("strtol parses bases, sign, prefixes and reports endptr", () => {
  // helper returns [value, consumed-length, errno]
  const run = (str, base) => {
    libc.errno.value = 0;
    const p = putStr(3000, str);
    const [v, end] = libc.strtol(p, base);
    return [v, end - p, libc.errno.value];
  };

  assert.deepEqual(run("123", 10), [123n, 3, 0]);
  assert.deepEqual(run("  -42", 10), [-42n, 5, 0]);
  assert.deepEqual(run("+5", 10), [5n, 2, 0]);
  assert.deepEqual(run("0x1A", 16), [26n, 4, 0]);
  assert.deepEqual(run("0x1A", 0), [26n, 4, 0]); // base 0 detects hex
  assert.deepEqual(run("010", 0), [8n, 3, 0]); // base 0 detects octal
  assert.deepEqual(run("010", 10), [10n, 3, 0]); // decimal ignores leading 0
  assert.deepEqual(run("777", 8), [511n, 3, 0]);
  assert.deepEqual(run("zz", 36), [1295n, 2, 0]); // 35*36 + 35
  assert.deepEqual(run("12abc", 10), [12n, 2, 0]); // stops at first non-digit
  assert.deepEqual(run("abc", 10), [0n, 0, 0]); // no conversion -> endptr == nptr
});

test("strtol clamps overflow to LONG_MAX/LONG_MIN and sets ERANGE", () => {
  const LONG_MAX = 9223372036854775807n;
  const LONG_MIN = -9223372036854775808n;
  const ERANGE = libc.ERANGE.value;

  // exact boundaries parse without error
  libc.errno.value = 0;
  assert.equal(libc.strtol(putStr(3000, "9223372036854775807"), 10)[0], LONG_MAX);
  assert.equal(libc.errno.value, 0);
  assert.equal(libc.strtol(putStr(3000, "-9223372036854775808"), 10)[0], LONG_MIN);

  // beyond the boundaries clamps and sets ERANGE
  libc.errno.value = 0;
  assert.equal(libc.strtol(putStr(3000, "99999999999999999999999"), 10)[0], LONG_MAX);
  assert.equal(libc.errno.value, ERANGE);

  libc.errno.value = 0;
  assert.equal(libc.strtol(putStr(3000, "-99999999999999999999999"), 10)[0], LONG_MIN);
  assert.equal(libc.errno.value, ERANGE);
});

test("strtod parses decimal floats and reports endptr", () => {
  const run = (str) => {
    libc.errno.value = 0;
    const p = putStr(3000, str);
    const [v, end] = libc.strtod(p);
    return [v, end - p, libc.errno.value];
  };

  // these all round-trip exactly to the same double as JS Number()
  for (const s of ["3.14", "-2.5", ".5", "5.", "42", "1e3", "1.5e-3",
                   "6.022e23", "0.0", "1E10", "+7.25"]) {
    assert.equal(run(s)[0], Number(s), `strtod(${JSON.stringify(s)})`);
  }

  assert.deepEqual(run("3.14"), [3.14, 4, 0]);
  assert.deepEqual(run("  -0.001"), [-0.001, 8, 0]); // skips leading whitespace
  assert.deepEqual(run("12.5abc"), [12.5, 4, 0]); // stops at first non-numeric
  assert.deepEqual(run("abc"), [0, 0, 0]); // no conversion -> endptr == nptr
  // a trailing 'e' with no exponent digits is not consumed
  assert.deepEqual(run("5e"), [5, 1, 0]);
});

test("strtod sets ERANGE on overflow and underflow", () => {
  const ERANGE = libc.ERANGE.value;
  const run = (str) => {
    libc.errno.value = 0;
    const [v] = libc.strtod(putStr(3000, str));
    return [v, libc.errno.value];
  };

  assert.deepEqual(run("1e400"), [Infinity, ERANGE]);
  assert.deepEqual(run("-1e400"), [-Infinity, ERANGE]);
  assert.deepEqual(run("1e-400"), [0, ERANGE]);
});

test("atof equals strtod's value", () => {
  for (const s of ["3.14", "-42.5", "1e-3", "0", "10abc"]) {
    const p = putStr(3000, s);
    assert.equal(libc.atof(p), libc.strtod(p)[0]);
  }
});

// qsort/bsearch take a caller-supplied comparator. The comparator must be a
// real wasm function installed into the exported function table; it reads the
// elements out of libc's shared linear memory. We build an ascending-i32
// comparator in its own module, share libc's memory with it, and install it at
// table slot 0.
const COMPARATOR_WAT = `
  (module
    (import "env" "memory" (memory 0))
    (func (export "cmp_i32") (param $a i32) (param $b i32) (result i32)
      (i32.sub (i32.load (local.get $a)) (i32.load (local.get $b)))
    )
  )`;

const installComparator = async () => {
  const { instance } = await WebAssembly.instantiate(assemble(COMPARATOR_WAT), {
    env: { memory: libc.memory },
  });
  libc.__indirect_function_table.set(0, instance.exports.cmp_i32);
  return 0; // table index passed as the `compar` argument
};

test("qsort sorts an i32 array via the table comparator", async () => {
  const compar = await installComparator();
  const i32 = new Int32Array(libc.memory.buffer);
  const base = 4000;
  const input = [5, 3, 9, 1, 4, 2, 9, 0];
  input.forEach((v, k) => (i32[(base >> 2) + k] = v));

  libc.qsort(base, input.length, 4, compar);

  const out = [];
  for (let k = 0; k < input.length; k++) out.push(i32[(base >> 2) + k]);
  assert.deepEqual(out, [...input].sort((a, b) => a - b));

  // a single-element (and empty) array is a no-op, not a crash
  libc.qsort(base, 1, 4, compar);
  libc.qsort(base, 0, 4, compar);
  assert.equal(i32[base >> 2], 0);
});

test("bsearch finds elements in a sorted array, or returns NULL", async () => {
  const compar = await installComparator();
  const i32 = new Int32Array(libc.memory.buffer);
  const base = 4000;
  const sorted = [1, 3, 5, 7, 9, 11];
  sorted.forEach((v, k) => (i32[(base >> 2) + k] = v));
  const key = 5000;

  for (let k = 0; k < sorted.length; k++) {
    i32[key >> 2] = sorted[k];
    const p = libc.bsearch(key, base, sorted.length, 4, compar);
    assert.equal((p - base) / 4, k, `bsearch(${sorted[k]})`);
  }

  for (const absent of [0, 4, 12]) {
    i32[key >> 2] = absent;
    assert.equal(libc.bsearch(key, base, sorted.length, 4, compar), 0);
  }
});

// ---------------------------------------------------------------------------
// math.h
// ---------------------------------------------------------------------------

test("sqrt / ceil / fabs / floor", () => {
  assert.equal(libc.sqrt(16), 4);
  assert.equal(libc.ceil(1.2), 2);
  assert.equal(libc.floor(1.8), 1);
  assert.equal(libc.fabs(-3.5), 3.5);
  assert.equal(libc.fabs(3.5), 3.5);
});

// helper: assert two doubles are bit-identical (so NaN === NaN, +0 !== -0)
const eqf = (got, exp, msg) => assert.ok(Object.is(got, exp), `${msg}: got ${got}, want ${exp}`);

test("fmod matches IEEE remainder (the JS % operator)", () => {
  for (const [x, y] of [[5.3, 2], [-5.3, 2], [5.3, -2], [1e9 + 0.5, 3],
                        [7, 7], [2, 5], [0, 5]]) {
    eqf(libc.fmod(x, y), x % y, `fmod(${x}, ${y})`);
  }
  // exact for a large quotient (the naive x - trunc(x/y)*y would not be)
  eqf(libc.fmod(1e16 + 1, 3), (1e16 + 1) % 3, "fmod large");
  // edge cases -> NaN, or x passed through
  assert.ok(Number.isNaN(libc.fmod(5, 0)));
  assert.ok(Number.isNaN(libc.fmod(Infinity, 2)));
  assert.ok(Number.isNaN(libc.fmod(NaN, 1)));
  eqf(libc.fmod(3, Infinity), 3, "fmod(x, inf)");
});

test("modf splits into integral and fractional parts", () => {
  for (const v of [3.75, -3.75, 5, 0]) {
    const [ip, fp] = libc.modf(v);
    eqf(ip, Math.trunc(v), `modf int ${v}`);
    eqf(fp, v - Math.trunc(v), `modf frac ${v}`);
  }
  // infinities: integral is +/-inf, fractional is signed zero
  assert.deepEqual(libc.modf(Infinity), [Infinity, 0]);
  eqf(libc.modf(-Infinity)[1], -0, "modf(-inf) frac");
});

test("frexp returns a normalized fraction and exponent", () => {
  for (const v of [1, 0.5, 8, -8, 123.456, 1e300,
                   5e-324 /* min subnormal */, 2.2250738585072014e-308]) {
    const [e, m] = libc.frexp(v);
    eqf(m * 2 ** e, v, `frexp reconstruct ${v}`); // x == m * 2^e exactly
    assert.ok(Math.abs(m) >= 0.5 && Math.abs(m) < 1, `frexp range ${v}: ${m}`);
  }
  assert.deepEqual(libc.frexp(0), [0, 0]); // zero -> (0, 0)
});

test("ldexp computes x * 2^exp with over/underflow", () => {
  for (const [x, n] of [[1, 3], [1, -3], [3, 10], [1.5, 100], [0, 5]]) {
    eqf(libc.ldexp(x, n), x * 2 ** n, `ldexp(${x}, ${n})`);
  }
  eqf(libc.ldexp(1, 2000), Infinity, "ldexp overflow"); // overflow -> inf
  eqf(libc.ldexp(1, -2000), 0, "ldexp underflow"); // underflow -> 0
  // frexp and ldexp are inverses
  const [e, m] = libc.frexp(123.456);
  eqf(libc.ldexp(m, e), 123.456, "ldexp(frexp(x))");
});

test("toascii masks to 7 bits", () => {
  assert.equal(libc.toascii(0x41), 0x41);
  assert.equal(libc.toascii(200), 200 & 0x7f);
  assert.equal(libc.toascii(0xff), 0x7f);
});

// distance in representable doubles (ULPs) between two finite values
const ulps = (a, b) => {
  if (Object.is(a, b)) return 0;
  if (!Number.isFinite(a) || !Number.isFinite(b)) return Infinity;
  const buf = new DataView(new ArrayBuffer(8));
  buf.setFloat64(0, a);
  const ai = buf.getBigInt64(0);
  buf.setFloat64(0, b);
  const bi = buf.getBigInt64(0);
  const d = ai > bi ? ai - bi : bi - ai;
  return Number(d);
};
const closeUlp = (got, exp, max, msg) =>
  assert.ok(ulps(got, exp) <= max, `${msg}: ${got} vs ${exp} (${ulps(got, exp)} ulp)`);

test("exp approximates e^x to within a few ULP", () => {
  for (const x of [0, 1, -1, 0.5, -0.5, 2.5, -10, 10, 100, -100, 0.0001]) {
    closeUlp(libc.exp(x), Math.exp(x), 2, `exp(${x})`);
  }
  // specials
  assert.equal(libc.exp(0), 1);
  assert.equal(libc.exp(Infinity), Infinity);
  assert.equal(libc.exp(-Infinity), 0);
  assert.ok(Number.isNaN(libc.exp(NaN)));
  // overflow -> inf + ERANGE
  libc.errno.value = 0;
  assert.equal(libc.exp(710), Infinity);
  assert.equal(libc.errno.value, libc.ERANGE.value);
});

test("log approximates ln(x) to within a few ULP", () => {
  for (const x of [1, Math.E, 0.5, 2, 10, 1e9, 1e-9, 123.456, 0.0001]) {
    closeUlp(libc.log(x), Math.log(x), 2, `log(${x})`);
  }
  assert.equal(libc.log(1), 0);
  assert.equal(libc.log(Infinity), Infinity);
  assert.ok(Number.isNaN(libc.log(NaN)));
  // log(0) -> -inf + ERANGE; log(negative) -> NaN + EDOM
  libc.errno.value = 0;
  assert.equal(libc.log(0), -Infinity);
  assert.equal(libc.errno.value, libc.ERANGE.value);
  libc.errno.value = 0;
  assert.ok(Number.isNaN(libc.log(-1)));
  assert.equal(libc.errno.value, libc.EDOM.value);
});

test("log10 approximates log base 10 to within a few ULP", () => {
  for (const x of [1, 10, 100, 1000, 0.1, 2, 1e9, 1e-9]) {
    closeUlp(libc.log10(x), Math.log10(x), 2, `log10(${x})`);
  }
});

test("pow is near-exact for integer exponents", () => {
  // small integer powers (including negative bases and reciprocals) are exact
  for (const [x, y, want] of [[2, 10, 1024], [-2, 3, -8], [-3, 3, -27],
                              [10, -2, 0.01], [2, -3, 0.125], [5, 3, 125],
                              [3, 4, 81], [7, 2, 49], [2, 0, 1], [9, 1, 9]]) {
    assert.equal(libc.pow(x, y), want, `pow(${x}, ${y})`);
  }
  // larger integer powers stay within a few ULP of Math.pow
  for (let i = 0; i < 2000; i++) {
    const x = (Math.random() - 0.5) * 30;
    const y = Math.floor((Math.random() - 0.5) * 30);
    closeUlp(libc.pow(x, y), Math.pow(x, y), 32, `pow(${x}, ${y})`);
  }
});

test("pow approximates x^y for non-integer exponents", () => {
  assert.equal(libc.pow(2, 0.5), Math.SQRT2);
  // exp(y*log x) compounds a few tens of ULP of error; not correctly rounded
  for (let i = 0; i < 5000; i++) {
    const x = Math.exp((Math.random() - 0.5) * 20); // positive base
    const y = (Math.random() - 0.5) * 20;
    closeUlp(libc.pow(x, y), Math.pow(x, y), 100, `pow(${x}, ${y})`);
  }
});

test("sin and cos are accurate for moderate arguments", () => {
  assert.equal(libc.sin(0), 0);
  assert.equal(libc.cos(0), 1);
  closeUlp(libc.sin(Math.PI / 6), 0.5, 2, "sin(pi/6)");
  closeUlp(libc.cos(Math.PI / 3), 0.5, 2, "cos(pi/3)");

  // deterministic grid over [-20, 20]; near a zero crossing the value is tiny
  // so we check absolute error, and check ULPs only where the value is large.
  for (let x = -20; x <= 20; x += 0.0137) {
    for (const [f, ref] of [[libc.sin, Math.sin], [libc.cos, Math.cos]]) {
      const got = f(x);
      assert.ok(Math.abs(got - ref(x)) < 1e-13, `${f === libc.sin ? "sin" : "cos"}(${x}) abs`);
      if (Math.abs(ref(x)) > 0.5) closeUlp(got, ref(x), 8, `f(${x})`);
    }
  }

  // specials: sin/cos of +/-inf are NaN
  assert.ok(Number.isNaN(libc.sin(Infinity)));
  assert.ok(Number.isNaN(libc.cos(-Infinity)));
  assert.ok(Number.isNaN(libc.sin(NaN)));
});

test("tan is accurate away from its poles", () => {
  closeUlp(libc.tan(Math.PI / 4), Math.tan(Math.PI / 4), 2, "tan(pi/4)");
  // grid within (-pi/2, pi/2), staying clear of the poles at +/-pi/2
  for (let x = -1.5; x <= 1.5; x += 0.0017) {
    closeUlp(libc.tan(x), Math.tan(x), 16, `tan(${x})`);
  }
  assert.equal(libc.tan(0), 0);
  assert.ok(Object.is(libc.tan(-0), -0));
  assert.ok(Number.isNaN(libc.tan(Infinity)));
});

test("pow handles the C99 special cases", () => {
  const { value: EDOM } = libc.EDOM;
  const { value: ERANGE } = libc.ERANGE;

  // anything**0 == 1 (even NaN); 1**anything == 1 (even NaN)
  assert.equal(libc.pow(5, 0), 1);
  assert.equal(libc.pow(0, 0), 1);
  assert.equal(libc.pow(NaN, 0), 1);
  assert.equal(libc.pow(1, NaN), 1);
  assert.ok(Number.isNaN(libc.pow(NaN, 2)));

  // NOTE: C99 differs from JS Math.pow here -- pow(+/-1, +/-inf) == 1
  assert.equal(libc.pow(1, Infinity), 1);
  assert.equal(libc.pow(-1, Infinity), 1);
  assert.equal(libc.pow(-1, -Infinity), 1);

  // x ** +/-inf
  assert.equal(libc.pow(2, Infinity), Infinity);
  assert.equal(libc.pow(0.5, Infinity), 0);
  assert.equal(libc.pow(2, -Infinity), 0);
  assert.equal(libc.pow(0.5, -Infinity), Infinity);

  // +/-inf ** y
  assert.equal(libc.pow(Infinity, 2), Infinity);
  assert.equal(libc.pow(Infinity, -2), 0);
  assert.equal(libc.pow(-Infinity, 3), -Infinity);
  assert.equal(libc.pow(-Infinity, 2), Infinity);
  assert.ok(Object.is(libc.pow(-Infinity, -3), -0)); // 1/(-inf) == -0
  assert.equal(libc.pow(-Infinity, -2), 0);

  // signed-zero base
  assert.ok(Object.is(libc.pow(0, 3), 0));
  assert.ok(Object.is(libc.pow(-0, 3), -0)); // odd exponent keeps the sign
  assert.ok(Object.is(libc.pow(-0, 2), 0)); // even exponent does not

  // zero base, negative exponent -> pole error (+/-inf, ERANGE)
  libc.errno.value = 0;
  assert.equal(libc.pow(0, -2), Infinity);
  assert.equal(libc.errno.value, ERANGE);
  assert.ok(Object.is(libc.pow(-0, -3), -Infinity));

  // negative base, non-integer exponent -> domain error (NaN, EDOM)
  libc.errno.value = 0;
  assert.ok(Number.isNaN(libc.pow(-2, 0.5)));
  assert.equal(libc.errno.value, EDOM);
});

// ---------------------------------------------------------------------------
// string.h
// ---------------------------------------------------------------------------

test("memset fills and returns the destination", () => {
  const s = 512;
  const ret = libc.memset(s, 0x41, 4);
  assert.equal(ret, s);
  assert.deepEqual([...mem.subarray(s, s + 4)], [0x41, 0x41, 0x41, 0x41]);
  // byte past the fill is untouched
  assert.notEqual(mem[s + 4], 0x41);
});

test("memcpy copies bytes and returns the destination", () => {
  const src = 600;
  const dst = 700;
  const data = [1, 2, 3, 4, 5];
  mem.set(data, src);
  const ret = libc.memcpy(dst, src, data.length);
  assert.equal(ret, dst);
  assert.deepEqual([...mem.subarray(dst, dst + data.length)], data);
});

test("memmove handles overlapping regions", () => {
  const base = 800;
  mem.set([1, 2, 3, 4, 5], base);
  // shift forward by one byte (overlap)
  libc.memmove(base + 1, base, 4);
  assert.deepEqual([...mem.subarray(base, base + 5)], [1, 1, 2, 3, 4]);
});

test("memcmp orders byte ranges", () => {
  const a = 900;
  const b = 920;
  mem.set([1, 2, 3], a);
  mem.set([1, 2, 3], b);
  assert.equal(libc.memcmp(a, b, 3), 0);

  mem.set([1, 2, 4], b);
  assert.equal(libc.memcmp(a, b, 3), -1); // a < b

  mem.set([1, 2, 2], b);
  assert.equal(libc.memcmp(a, b, 3), 1); // a > b
});

test("memchr finds a byte or returns NULL", () => {
  const s = 1000;
  mem.set([10, 20, 30, 40], s);
  assert.equal(libc.memchr(s, 30, 4), s + 2);
  assert.equal(libc.memchr(s, 99, 4), 0); // not found -> NULL
});

test("strlen", () => {
  assert.equal(libc.strlen(putStr(2000, "hello")), 5);
  assert.equal(libc.strlen(putStr(2000, "")), 0);
  assert.equal(libc.strlen(putStr(2000, "a longer string")), 15);
});

test("strcmp orders strings (-1/0/1)", () => {
  const a = putStr(2000, "abc");
  assert.equal(libc.strcmp(a, putStr(2100, "abc")), 0);
  assert.equal(libc.strcmp(putStr(2000, "abc"), putStr(2100, "abd")), -1);
  assert.equal(libc.strcmp(putStr(2000, "abd"), putStr(2100, "abc")), 1);
  // prefix sorts before the longer string
  assert.equal(libc.strcmp(putStr(2000, "ab"), putStr(2100, "abc")), -1);
  assert.equal(libc.strcmp(putStr(2000, "abc"), putStr(2100, "ab")), 1);
  // bytes are compared unsigned (so e.g. 0x80 > 'a')
  mem.set([0x80, 0], 2000);
  assert.equal(libc.strcmp(2000, putStr(2100, "a")), 1);
});

test("strcoll matches strcmp in the C locale", () => {
  assert.equal(libc.strcoll(putStr(2000, "abc"), putStr(2100, "abc")), 0);
  assert.equal(libc.strcoll(putStr(2000, "abc"), putStr(2100, "abd")), -1);
});

test("strncmp compares at most n bytes", () => {
  assert.equal(libc.strncmp(putStr(2000, "abc"), putStr(2100, "abd"), 2), 0);
  assert.equal(libc.strncmp(putStr(2000, "abc"), putStr(2100, "abd"), 3), -1);
  assert.equal(libc.strncmp(putStr(2000, "abc"), putStr(2100, "abc"), 0), 0);
  // stops at a shared NUL even when n is larger
  assert.equal(libc.strncmp(putStr(2000, "ab"), putStr(2100, "ab"), 10), 0);
});

test("strcpy copies including NUL and returns dst", () => {
  const dst = 2000;
  const ret = libc.strcpy(dst, putStr(2100, "hello"));
  assert.equal(ret, dst);
  assert.equal(getStr(dst), "hello");
});

test("strncpy copies, pads with NUL, and does not over-terminate", () => {
  // src shorter than n -> remainder padded with NUL
  mem.fill(0xff, 2000, 2010);
  libc.strncpy(2000, putStr(2100, "hi"), 5);
  assert.deepEqual([...mem.subarray(2000, 2005)], [C("h"), C("i"), 0, 0, 0]);

  // src at least n bytes -> exactly n copied, no terminating NUL written
  mem.fill(0xff, 2000, 2010);
  libc.strncpy(2000, putStr(2100, "world"), 3);
  assert.deepEqual([...mem.subarray(2000, 2004)], [C("w"), C("o"), C("r"), 0xff]);
});

test("strcat appends and returns dst", () => {
  const dst = putStr(2000, "foo");
  const ret = libc.strcat(dst, putStr(2100, "bar"));
  assert.equal(ret, dst);
  assert.equal(getStr(dst), "foobar");
});

test("strncat appends at most n bytes and always terminates", () => {
  let dst = putStr(2000, "foo");
  libc.strncat(dst, putStr(2100, "barbaz"), 3);
  assert.equal(getStr(dst), "foobar");

  // n larger than src length stops at src NUL
  dst = putStr(2000, "foo");
  libc.strncat(dst, putStr(2100, "x"), 10);
  assert.equal(getStr(dst), "foox");
});

test("strchr finds first occurrence, NUL, or returns NULL", () => {
  const s = putStr(2000, "hello");
  assert.equal(libc.strchr(s, C("l")), s + 2); // first 'l'
  assert.equal(libc.strchr(s, C("h")), s);
  assert.equal(libc.strchr(s, C("z")), 0); // absent
  assert.equal(libc.strchr(s, 0), s + 5); // matches terminating NUL
});

test("strrchr finds last occurrence, NUL, or returns NULL", () => {
  const s = putStr(2000, "hello");
  assert.equal(libc.strrchr(s, C("l")), s + 3); // last 'l'
  assert.equal(libc.strrchr(s, C("o")), s + 4);
  assert.equal(libc.strrchr(s, C("z")), 0); // absent
  assert.equal(libc.strrchr(s, 0), s + 5); // matches terminating NUL
});

test("strspn measures the accepted prefix", () => {
  assert.equal(libc.strspn(putStr(2000, "aabbcc"), putStr(2100, "ab")), 4);
  assert.equal(libc.strspn(putStr(2000, "xyz"), putStr(2100, "ab")), 0);
  assert.equal(libc.strspn(putStr(2000, "abc"), putStr(2100, "abc")), 3);
});

test("strcspn measures the rejected-free prefix", () => {
  assert.equal(libc.strcspn(putStr(2000, "hello,world"), putStr(2100, ",")), 5);
  assert.equal(libc.strcspn(putStr(2000, "hello"), putStr(2100, "xyz")), 5); // no reject hit
  assert.equal(libc.strcspn(putStr(2000, ",abc"), putStr(2100, ",")), 0);
});

test("strpbrk finds the first byte from the set, or NULL", () => {
  const s = putStr(2000, "hello,world");
  assert.equal(libc.strpbrk(s, putStr(2100, ",;")), s + 5);
  assert.equal(libc.strpbrk(putStr(2000, "hello"), putStr(2100, "xyz")), 0);
});

test("strstr finds substring, handles empty needle, or NULL", () => {
  const s = putStr(2000, "hello world");
  assert.equal(libc.strstr(s, putStr(2100, "world")), s + 6);
  assert.equal(libc.strstr(s, putStr(2100, "hello")), s);
  assert.equal(libc.strstr(s, putStr(2100, "")), s); // empty needle -> haystack
  assert.equal(libc.strstr(s, putStr(2100, "xyz")), 0); // absent
  // partial-then-fail must not produce a false match
  assert.equal(libc.strstr(putStr(2000, "abcabd"), putStr(2100, "abd")), 2003);
});

test("strxfrm copies and returns the source length (C locale)", () => {
  const dst = 2000;
  // ample room: dst becomes an exact copy, return is strlen(src)
  mem.fill(0xff, dst, dst + 10);
  assert.equal(libc.strxfrm(dst, putStr(2100, "abcd"), 10), 4);
  assert.equal(getStr(dst), "abcd");

  // n == 0: nothing written, still returns strlen(src)
  mem.fill(0xff, dst, dst + 10);
  assert.equal(libc.strxfrm(dst, putStr(2100, "abcd"), 0), 4);
  assert.equal(mem[dst], 0xff); // untouched

  // exactly enough room for the string plus its NUL
  mem.fill(0xff, dst, dst + 10);
  assert.equal(libc.strxfrm(dst, putStr(2100, "abc"), 4), 3);
  assert.equal(getStr(dst), "abc");
});

test("strtok splits on delimiters across calls", () => {
  const s = putStr(2000, "a,bb,,ccc");
  const delim = putStr(2100, ",");
  const read = (p) => getStr(p);

  let t = libc.strtok(s, delim);
  assert.equal(read(t), "a");
  t = libc.strtok(0, delim);
  assert.equal(read(t), "bb");
  t = libc.strtok(0, delim); // empty field between the two commas is skipped
  assert.equal(read(t), "ccc");
  assert.equal(libc.strtok(0, delim), 0); // no more tokens
  assert.equal(libc.strtok(0, delim), 0); // stays NULL
});

test("strtok skips leading delimiters and handles multiple delimiters", () => {
  const s = putStr(2000, "  hello world  ");
  const delim = putStr(2100, " ");
  assert.equal(getStr(libc.strtok(s, delim)), "hello");
  assert.equal(getStr(libc.strtok(0, delim)), "world");
  assert.equal(libc.strtok(0, delim), 0);

  // a string of only delimiters yields no tokens
  assert.equal(libc.strtok(putStr(2000, ",,,"), putStr(2100, ",")), 0);
});

test("strerror returns a message for each known errno", () => {
  assert.equal(getStr(libc.strerror(0)), "Success");
  assert.equal(getStr(libc.strerror(1)), "Numerical argument out of domain"); // EDOM
  assert.equal(getStr(libc.strerror(2)), "Numerical result out of range"); // ERANGE
  assert.equal(getStr(libc.strerror(3)), "Unknown error"); // unmapped
  assert.equal(getStr(libc.strerror(999)), "Unknown error");
});

