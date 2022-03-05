(module

  (global $errno (mut i32))
  (global $EDOM (export "EDOM") i32 (i32.const 1))
  (global $ERANGE (export "ERANGE") i32 (i32.const 2))
  (global $NULL (export "NULL") i32 (i32.const 0))

  ;; assert.h
  ;; Ignores NDEBUG
  (func (export "assert") (i32 $condition)
    (if (i32.eqz (local.get $condition)) (then
      (unreachable)
    ))
  )

  ;; ctype.h
  ;; Assumes ASCII locale
  (func (export "isalnum") (param i32) (result i32))
  (func (export "isalpha") (param i32) (result i32))
  (func (export "iscntrl") (param i32) (result i32))
  (func (export "isdigit") (param i32) (result i32))
  (func (export "isgraph") (param i32) (result i32))
  (func (export "islower") (param i32) (result i32))
  (func (export "isprint") (param i32) (result i32))
  (func (export "ispunct") (param i32) (result i32))
  (func (export "isspace") (param i32) (result i32))
  (func (export "isupper") (param i32) (result i32))
  (func (export "isxdigit") (param i32) (result i32))
  (func (export "isxdigit") (param i32) (result i32))
  (func (export "tolower") (param i32) (result i32))
  (func (export "toupper") (param i32) (result i32))

  ;; float.h - Skipped!

  ;; limits.h - Skipped!
  ;; locale.h - Skipped!

  ;; math.h
  (func (export "acos") (param f64) (result f64)
    (unreachable)
  )
  
  (func (export "asin") (param f64) (result f64)
    (unreachable)
  )
  
  (func (export "atan") (param f64) (result f64)
    (unreachable)
  )
  
  (func (export "atan2") (param f64) (param f64) (result f64)
    (unreachable)
  )
  
  (func (export "cos") (param f64) (result f64)
    (unreachable)
  )
  
  (func (export "sin") (param f64) (result f64)
    (unreachable)
  )
  
  (func (export "tan") (param f64) (result f64)
    (unreachable)
  )
  
  (func (export "cosh") (param f64) (result f64)
    (unreachable)
  )
  
  (func (export "sinh") (param f64) (result f64)
    (unreachable)
  )

  (func (export "tanh") (param f64) (result f64)
    (unreachable)
  )
  
  (func (export "exp") (param f64) (result f64)
    (unreachable)
  )
  
  ;; Uses multiple return in place of return pointer
  (func (export "frexp") (param f64) (result i32 f64)
    (unreachable)
  )

  (func (export "ldexp") (param $x f64) (param $exp i32) (result f64)
    (unreachable)
  )

  (func (export "log") (param $x f64) (result f64)
    (unreachable)
  )

  (func (export "log10") (param $x f64) (result f64)
    (unreachable)
  )
  
  (func (export "modf") (param $value f64) (result f64 f64)
    (unreachable)
  )
  
  (func (export "pow") (param $x f64) (param $y f64) (result f64)
    (unreachable)
  )

  (func (export "sqrt") (param $x f64) (result f64)
    (f64.sqrt (local.get $x))
  )

  (func (export "ceil") (param $x f64) (result f64)
    (f64.ceil (local.get $x))
  )

  (func (export "fabs") (param $x f64) (result f64)
    (f64.abs (local.get $x))
  )

  (func (export "floor") (param $x f64) (result f64)
    (f64.floor (local.get $x))
  )

  (func (export "fmod") (param $x f64) (param $y f64) (result f64)
    (unreachable)
  )

  ;; setjmp.h - Skipped!
  ;; signal.h - Skipped!
  ;; stdarg.h - Skipped!
  ;; stddef.h - Skipped!
  ;; stdio.h - Skipped!

  (func (export "abs") (param $i i32) (result i32)
    (if (i32.lt_s (local.get $i) (i32.const 0)) (then
      (i32.mul (local.get $1) (i32.const -1))
    ) (else 
      (local.get $1)
    ))
  )
  
  (func (export "labs") (param $i i64) (result i64)
    (if (i64.lt_s (local.get $i) (i64.const 0)) (then
      (i64.mul (local.get $1) (i64.const -1))
    ) (else 
      (local.get $1)
    ))
  )
    
  ;; Compute quotient and remainder of integer division. 
  ;; Returns 2-tuple in place of dib_t struct
  (func (export "div") (param $numerator i32) (param $denominator i32) (result i32 i32)
    (i32.div_s (local.get $numerator) (local.get $denominator))
    (i32.rem_s (local.get $numerator) (local.get $denominator))
  )

  (func (export "ldiv") (param $numerator i64) (param $denominator i64) (result i64 i64)
    (i64.div_s (local.get $numerator) (local.get $denominator))
    (i64.rem_s (local.get $numerator) (local.get $denominator))
  )

  (func (export "bsearch"))
  (func (export "qsort"))

  (func (export "rand"))
  (func (export "srand"))
  (func (export "atof"))
  (func (export "atoi"))
  (func (export "strtod"))
  (func (export "strtol"))

  ;; Copies a range of bytes from src to dst
  ;; memory.copy is able to handle overlapping regions in linear memory, so there is no distinction
  ;; between memmove and memcpy
  (func $memcpy (export "memcpy") (param $dst i32) (param $src i32) (param $size i32) (result i32)
    (call $memmove (local.get $dst) (local.get $src) (local.get $size))
  )

  (func $memmove (export "memmove") (param $dst i32) (param $src i32) (param $size i32) (result i32)
    (memory.copy (local.get $dst) (local.get $src) (local.get $size))
  )

  (func $memchr (export "memchr") (param $s i32) (param $c i32) (param $n i32)
    (unreachable)
  )

  (func $memset (export "memset") (param $s i32) (param $c i32) (param $n i32)
    (memory.fill (local.get $s) (local.get $c) (local.get $n))
  )

  ;; Compares the two regions starting at offsets s1 and s2 of identical size n match byte-for-byte
  ;; Returns -1 if range s1 is less than s2, 0 if range s1 matchs s2, 1 if range s1 is greater than s2
  (func (export "memcmp") (param $s1 i32) (param $s2 i32) (param $n i32) (result i32) 
    (local $s1Cursor i32)
    (local $s2Cursor i32)
    (local.set $s1Cursor (local.get $s1))
    (local.set $s2Cursor (local.get $s2))
    (if (i32.gt_s (local.get $n) (i32.const 0)) (then
      (loop
        (if (i32.ne (i32.load8_u (local.get $s1Cursor)) (i32.load8_u (local.get $s2Cursor))) (then
          (if (i32.lt_u (i32.load8_u (local.get $s1Cursor)) (i32.load8_u (local.get $s2Cursor)) ) (then
            (return (i32.const -1))
          ) (else 
            (return (i32.const 1))
          ))
        ))
        (local.set $s1Cursor (i32.add (local.get $s1Cursor) (i32.const 1)))
        (local.set $s2Cursor (i32.add (local.get $s2Cursor) (i32.const 1)))
        (br_if 0 (i32.gt_s (local.tee $n (i32.sub (local.get $n (i32.const 1)))) (i32.const 0)))
      )  
    ))
    (i32.const 0)
  )


  (func (export "strcpy"))
  (func (export "strncpy"))
  (func (export "strcat"))
  (func (export "strncat"))
  (func (export "strlen"))
  (func (export "strcmp"))
  (func (export "strcoll"))
  (func (export "strncmp"))
  (func (export "strxfrm"))
  (func (export "strchr"))
  (func (export "strcspn"))
  (func (export "strpbrk"))
  (func (export "strrchr"))
  (func (export "strrchr"))
  (func (export "strspn"))
  (func (export "strstr"))
  (func (export "strtrok"))
  (func (export "strerror"))

)