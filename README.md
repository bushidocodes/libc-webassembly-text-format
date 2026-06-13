# libc.wat

A WebAssembly Text Format (WAT) implementation of portions of the C Standard Library.

## Overview

`libc.wat` provides C standard library functions implemented directly in WebAssembly Text Format. It targets pure WebAssembly environments where you want familiar libc semantics without external dependencies, and takes advantage of WebAssembly-specific features like multi-value returns and native memory/math instructions.

Every function from the headers it covers (`assert.h`, `ctype.h`, `math.h`, `stdlib.h`, `string.h`) is implemented — see the status tables below for per-function notes. The transcendental `math.h` functions are accurate to a few ULP rather than being correctly rounded.

## Implementation Status

### assert.h

| Function | Status |
|----------|--------|
| `assert` | Implemented (ignores `NDEBUG`) |

### ctype.h

All functions assume ASCII locale.

| Function | Status |
|----------|--------|
| `isalnum` | Implemented |
| `isalpha` | Implemented |
| `isascii` | Implemented |
| `isblank` | Implemented |
| `iscntrl` | Implemented |
| `isdigit` | Implemented |
| `isgraph` | Implemented |
| `islower` | Implemented |
| `isprint` | Implemented |
| `ispunct` | Implemented |
| `isspace` | Implemented |
| `isupper` | Implemented |
| `isxdigit` | Implemented |
| `tolower` | Implemented |
| `toupper` | Implemented |
| `toascii` | Implemented |

### math.h

| Function | Status |
|----------|--------|
| `ceil` | Implemented (native `f64.ceil`) |
| `fabs` | Implemented (native `f64.abs`) |
| `floor` | Implemented (native `f64.floor`) |
| `sqrt` | Implemented (native `f64.sqrt`) |
| `fmod` | Implemented (exact, via `f64.trunc`/repeated subtraction) |
| `frexp` | Implemented (bit-level; returns `(exponent, fraction)`) |
| `ldexp` | Implemented (`scalbn`-style staged scaling) |
| `modf` | Implemented (returns `(integral, fractional)`) |
| `exp` | Implemented (Cephes rational approx; ~1 ULP) |
| `log` | Implemented (Cephes rational approx; ~1 ULP) |
| `log10` | Implemented (`log(x) * log10(e)`; a few ULP) |
| `pow` | Implemented (exact-ish for integer exponents; `exp(y·log x)` otherwise) |
| `sin` | Implemented (Cephes reduction; ~1 ULP for moderate \|x\|) |
| `cos` | Implemented (Cephes reduction; ~1 ULP for moderate \|x\|) |
| `tan` | Implemented (Cephes rational; ~1 ULP away from poles) |
| `atan` | Implemented (Cephes rational; ~1 ULP) |
| `atan2` | Implemented (quadrant-correct; via `atan`) |
| `asin` | Implemented (`atan2(x, √(1−x²))`; ~2 ULP) |
| `acos` | Implemented (`atan2(√(1−x²), x)`; ~2 ULP) |
| `sinh` | Implemented (Taylor near 0, else exponentials; ~2 ULP) |
| `cosh` | Implemented (via `exp`; ~2 ULP) |
| `tanh` | Implemented (Cephes rational near 0, else `exp`; ~2 ULP) |

The trigonometric functions reduce the argument with a two-part π/4 split, so they are accurate (~1 ULP) for moderate magnitudes but lose precision for very large arguments (roughly one decimal digit per power of ten beyond ~10⁷), since they do not implement full Payne–Hanek reduction.

### stdlib.h

| Function | Status | Notes |
|----------|--------|-------|
| `abs` | Implemented | |
| `div` | Implemented | Returns `(quotient, remainder)` tuple |
| `labs` | Implemented | |
| `ldiv` | Implemented | Returns `(quotient, remainder)` tuple |
| `itoa_s` | Implemented | Decimal only; returns `(base_address, length)` tuple |
| `atof` | Implemented | Wraps `strtod` |
| `atoi` | Implemented | Skips leading whitespace; optional sign; overflow wraps |
| `bsearch` | Implemented | Comparator via the exported function table (see below) |
| `qsort` | Implemented | Selection sort; comparator via the exported function table (see below) |
| `rand` | Implemented | C reference LCG; `RAND_MAX` is 32767 |
| `srand` | Implemented | Seeds `rand` |
| `strtod` | Implemented | Decimal floats + exponent; accurate to a few ULP (not correctly rounded); `ERANGE` on over/underflow; returns `(value, endptr)` |
| `strtol` | Implemented | Base 0/2–36, `0x` prefix, overflow clamps + sets `ERANGE`; returns `(value, endptr)` |

### string.h

| Function | Status |
|----------|--------|
| `memchr` | Implemented |
| `memcmp` | Implemented |
| `memcpy` | Implemented (delegates to `memmove`) |
| `memmove` | Implemented (native `memory.copy`) |
| `memset` | Implemented (native `memory.fill`) |
| `strcat` | Implemented |
| `strchr` | Implemented |
| `strcmp` | Implemented (returns `-1`/`0`/`1`) |
| `strcoll` | Implemented (ASCII locale; aliases `strcmp`) |
| `strcpy` | Implemented |
| `strcspn` | Implemented |
| `strerror` | Implemented (`EDOM`/`ERANGE` messages) |
| `strlen` | Implemented |
| `strncat` | Implemented |
| `strncmp` | Implemented (returns `-1`/`0`/`1`) |
| `strncpy` | Implemented |
| `strpbrk` | Implemented |
| `strrchr` | Implemented |
| `strspn` | Implemented |
| `strstr` | Implemented (naive search) |
| `strtok` | Implemented (non-reentrant, like C) |
| `strxfrm` | Implemented (ASCII locale; identity transform) |

### Skipped Headers

The following headers are intentionally not implemented:

- `float.h` — compiler-specific constants
- `limits.h` — compiler-specific constants
- `locale.h` — not meaningful in WASM
- `setjmp.h` — not expressible in WASM
- `signal.h` — not expressible in WASM
- `stdarg.h` — not expressible in WASM
- `stddef.h` — compiler-specific types
- `stdio.h` — I/O handled by the host

## Design Notes

### Multi-value returns

Where C uses output pointer parameters or structs, this library uses WebAssembly multi-value returns instead. This is a cleaner fit for the WASM execution model and avoids pointer aliasing concerns.

| C signature | WAT signature |
|-------------|---------------|
| `div_t div(int, int)` | `(func $div ...) (result i32 i32)` |
| `ldiv_t ldiv(long, long)` | `(func $ldiv ...) (result i64 i64)` |
| `double *frexp(double, int*)` | `(func $frexp ...) (result i32 f64)` |
| `double modf(double, double*)` | `(func $modf ...) (result f64 f64)` |

`itoa_s` is an extension that returns `(base_address, length)` rather than following the original `itoa` signature, avoiding a null-terminated-string convention.

### Global state

`$errno` is a mutable global rather than a thread-local, which is sufficient for single-threaded WASM modules. `$EDOM` and `$ERANGE` are constant globals matching their POSIX values (1 and 2). All three are exported (`errno`, `EDOM`, `ERANGE`) so a host can clear `errno` before a call and inspect it afterward — for example, `strtol` sets it to `ERANGE` on overflow. `strtok` likewise keeps its scan position in a mutable global (`$strtok_save`), so — exactly like the C standard's `strtok` — it is stateful and not reentrant.

### Comparators for `bsearch` / `qsort`

C passes `bsearch`/`qsort` a comparator *function pointer*. WebAssembly can only
call an arbitrary caller-supplied function through a function table via
`call_indirect`, so the library exports its table as `__indirect_function_table`
and the `compar` argument is the **table slot index** of the comparator (not a
code pointer).

A host installs its comparator into that table and passes the slot index. The
comparator must be a real WebAssembly function of type
`(param i32 i32) (result i32)` that reads its two element pointers out of the
shared linear memory. From JavaScript:

```js
const { instance } = await WebAssembly.instantiate(libcBytes);
const libc = instance.exports;

// A comparator is itself a wasm function that shares libc's memory.
const cmp = await WebAssembly.instantiate(comparatorBytes, {
  env: { memory: libc.memory },
});

libc.__indirect_function_table.set(0, cmp.exports.compare); // install at slot 0
libc.qsort(base, nmemb, size, 0);                           // pass the slot index
```

The table has one slot by default; grow it (`table.grow`) to register more
comparators. `qsort` is a simple selection sort (O(n²), not stable) — the C
standard does not mandate an algorithm.

### Memory operations

`memcpy` delegates to `memmove` because the WebAssembly `memory.copy` instruction handles overlapping regions correctly, so there is no behavioral difference between the two. `memset` uses `memory.fill` directly.

`strerror` returns pointers into a small **reserved region of linear memory (bytes 16–255)** that is initialized from `(data ...)` segments with the error-message strings. A host that uses `strerror` must avoid overwriting that region; all other memory (including byte 0, treated as `NULL`) is free for the host to use.

## Usage

Compile the WAT source to a WASM binary with any standard WAT toolchain:

```sh
# Using wasm-tools
wasm-tools parse libc.wat -o libc.wasm

# Using wat2wasm (part of the WebAssembly Binary Toolkit)
wat2wasm libc.wat -o libc.wasm
```

The module exports its linear memory (as `memory`) and every function under its
C name, so you can import the functions you need into your own module or call
them directly from a host runtime.

## Testing

Correctness tests live in [`tests/libc.test.mjs`](tests/libc.test.mjs) and run
against the assembled `libc.wasm` using Node's built-in test runner (no
dependencies). They cover the implemented `ctype.h`, `stdlib.h`, `math.h`, and
`string.h` functions, including the multi-value (`div`, `ldiv`, `itoa_s`) and
memory-based (`memset`, `memcpy`, `memmove`, `memcmp`, `memchr`) ones.

```sh
# Assemble libc.wasm and run the tests
npm test
```

This requires `wat2wasm` (from [wabt](https://github.com/WebAssembly/wabt)) on
your `PATH` and Node.js 18+.

## Continuous integration

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) assembles `libc.wat` with
`wat2wasm` and runs the test suite on every push and pull request, catching both
assembly errors and correctness regressions.

