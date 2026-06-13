// Correctness tests for the implemented libc.wat functions.
//
// The compiled module (libc.wasm) is loaded and instantiated with no imports.
// Multi-value WAT results surface as JS arrays; i64 params/results surface as
// BigInt. Run with `npm test` (builds the wasm first) or `node --test` against
// an already-built libc.wasm.

import { test, before } from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

const wasmPath = fileURLToPath(new URL("../libc.wasm", import.meta.url));

let libc;
let mem;

before(async () => {
  const bytes = await readFile(wasmPath);
  const { instance } = await WebAssembly.instantiate(bytes);
  libc = instance.exports;
  mem = new Uint8Array(libc.memory.buffer);
});

const C = (ch) => ch.charCodeAt(0);

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
