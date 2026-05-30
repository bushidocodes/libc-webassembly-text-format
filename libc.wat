(module

  (memory 1)

  (global $errno (mut i32) (i32.const 0))
  (global $EDOM i32 (i32.const 1))
  (global $ERANGE i32 (i32.const 2))
  (global $NULL i32 (i32.const 0))

  ;; assert.h
  ;; Ignores NDEBUG
  (func $assert (param $condition i32)
    (if (i32.eqz (local.get $condition)) (then
      (unreachable)
    ))
  )

  ;; ctype.h
  ;; Assumes ASCII locale
  
  ;; checks if charCode is a letter or digit [0-9a-zA-Z]
  (func $isalnum (param $charCode i32) (result i32)
    (i32.or 
      (call $isdigit (local.get $charCode))
      (call $isalpha (local.get $charCode))
    )
  )

  ;; checks if charCode is a letter [a-zA-Z]
  (func $isalpha (param $charCode i32) (result i32)
    (i32.or
      (call $islower (local.get $charCode))
      (call $isupper (local.get $charCode))
    )
  )

  ;; checks if charCode is a 7-bit unsigned char value that fits into the ASCII character set.
  (func $isascii (param $charCode i32) (result i32)
    (i32.and
      (i32.ge_s (local.get $charCode) (i32.const  0))
      (i32.le_s (local.get $charCode) (i32.const  127))
    )
  )

  ;; checks if charCode is a space or tab
  (func $isblank (param $charCode i32) (result i32)
    (i32.or
      (i32.eq (local.get $charCode) (i32.const  32))
      (i32.eq (local.get $charCode) (i32.const  9))
    )
  )

  ;; Checks if charCode is a non-printable control code
  ;; This includes the C0 control set (0-31) and DEL (127)
  (func $iscntrl (param $charCode i32) (result i32)
    (i32.or
      (i32.and
        (i32.ge_s (local.get $charCode) (i32.const  0))
        (i32.le_s (local.get $charCode) (i32.const 31))
      )
      (i32.eq (local.get $charCode) (i32.const 127))
    )
  )

  ;; checks if charCode is a digit [0-9]
  (func $isdigit (param $charCode i32) (result i32)
    (i32.and
      (i32.ge_s (local.get $charCode) (i32.const 48))
      (i32.le_s (local.get $charCode) (i32.const 57))
    )
  )

  ;; checks if charCode is a character that would be written to a graphical device
  (func $isgraph (param $charCode i32) (result i32)
    (i32.and 
      (call $isascii (local.get $charCode))
      (i32.and 
        (i32.eqz (call $iscntrl (local.get $charCode)))
        (i32.eqz (call $isspace (local.get $charCode)))
      )
    )
  )

  ;; checks if charCode is a lowercase letter [a-z]
  (func $islower (param $charCode i32) (result i32)
    (i32.and
      (i32.ge_s (local.get $charCode) (i32.const  97))
      (i32.le_s (local.get $charCode) (i32.const  122))
    )
  )

  ;; checks for any printable character including space
  (func $isprint (param $charCode i32) (result i32)
    (i32.or 
      (call $isgraph (local.get $charCode))
      (i32.eq (local.get $charCode) (i32.const  32))
    )
  )

  ;; checks for any printable character which is not a space or an alphanumeric character.
  (func $ispunct (param $charCode i32) (result i32)
    (i32.and
      (call $isgraph (local.get $charCode))
      (i32.eqz (call $isalnum (local.get $charCode)))
    )
  )

  ;; checks if charCode is a space or one of the standard motion control characters.
  (func $isspace (param $charCode i32) (result i32)
    (if (i32.eq (local.get $charCode) (i32.const  9)) (then (return (i32.const 1)))) ;; horizontal tab
    (if (i32.eq (local.get $charCode) (i32.const 10)) (then (return (i32.const 1)))) ;; line feed
    (if (i32.eq (local.get $charCode) (i32.const 11)) (then (return (i32.const 1)))) ;; vertical tab
    (if (i32.eq (local.get $charCode) (i32.const 12)) (then (return (i32.const 1)))) ;; form feed
    (if (i32.eq (local.get $charCode) (i32.const 13)) (then (return (i32.const 1)))) ;; carraige return
    (if (i32.eq (local.get $charCode) (i32.const 32)) (then (return (i32.const 1)))) ;; space

    (i32.const 0)
  )

  ;; checks if charCode is an uppercase letter [A-Z]
  (func $isupper (param $charCode i32) (result i32)
    (i32.and
      (i32.ge_s (local.get $charCode) (i32.const 65))
      (i32.le_s (local.get $charCode) (i32.const 90))
    )
  )

  ;; checks if charCode is a hexadecimal digit [0-9a-fA-F]
  (func $isxdigit (param $charCode i32) (result i32)
    (i32.or 
      (call $isdigit (local.get $charCode))
      (i32.or 
        (i32.and
          (i32.ge_s (local.get $charCode) (i32.const 65))
          (i32.le_s (local.get $charCode) (i32.const 70))
        )
        (i32.and
          (i32.ge_s (local.get $charCode) (i32.const 97))
          (i32.le_s (local.get $charCode) (i32.const 102))
        )
      )
    )
  )

  ;; TODO
  (func $toascii (param $charCode i32) (result i32)
    (unreachable)
  )

  (func $toupper (param $charCode i32) (result i32)
    (if (call $islower (local.get $charCode)) (then
      ;; Distance between A and a is 32
      (return (i32.sub (local.get $charCode) (i32.const 32)))
    ))

    (return (local.get $charCode))
  )

  (func $tolower (param $charCode i32) (result i32)
    (if (call $isupper (local.get $charCode)) (then
      ;; Distance between A and a is 32
      (return (i32.add (local.get $charCode) (i32.const 32)))
    ))

    (return (local.get $charCode))
  )

  ;; Only handles decimal
  ;; Modified to return base address and length as a tuple!
  (func $itoa_s (param $x i32) (param $offset i32) (param $radix i32) (result i32 i32)
    (local $low i32)
    (local $high i32)
    (local $temp i32)
    (local $length i32)
    (local.set $low (local.get $offset))
    (if (i32.lt_s (local.get $x) (i32.const 0)) (then
      ;; Append negative sign
      (i32.store8 (local.get $low) (i32.const 45))
      (local.set $low (i32.add (local.get $low) (i32.const 1)))
      (local.set $x (i32.mul (local.get $x) (i32.const -1)))
    ))
  
    (local.set $high (local.get $low))
    (if (i32.gt_s (local.get $x) (i32.const 0)) (then
      (loop
        (i32.store8 (local.get $high) (i32.add (i32.const 48) (i32.rem_u (local.get $x) (local.get $radix))))
        (local.set $high (i32.add (local.get $high) (i32.const 1)))
        (br_if 0 (i32.gt_s (local.tee $x (i32.div_u (local.get $x) (local.get $radix))) (i32.const 0)))
      )
    ))
  
    (local.set $length (i32.sub (local.get $high) (local.get $offset)))
    
    (local.set $high (i32.sub (local.get $high) (i32.const 1)))
    (if (i32.gt_u (local.get $high) (local.get $low)) (then
      (loop
        (local.set $temp (i32.load8_u (local.get $low)))
        (i32.store8 (local.get $low) (i32.load8_u (local.get $high)))
        (i32.store8 (local.get $high) (local.get $temp))
        (br_if 0 (i32.gt_u 
          (local.tee $high (i32.sub (local.get $high) (i32.const 1))) 
          (local.tee $low (i32.add (local.get $low) (i32.const 1))) 
        ))
      )
    ))

    (local.get $offset) (local.get $length)
  )

  ;; float.h - Skipped!
  ;; limits.h - Skipped!
  ;; locale.h - Skipped!

  ;; math.h
  (func $acos (param $x f64) (result f64)
    (unreachable)
  )
  
  (func $asin (param $x f64) (result f64)
    (unreachable)
  )
  
  (func $atan (param $x f64) (result f64)
    (unreachable)
  )
  
  (func $atan2 (param $y f64) (param $x f64) (result f64)
    (unreachable)
  )
  
  (func $cos (param $x f64) (result f64)
    (unreachable)
  )
  
  (func $sin (param $x f64) (result f64)
    (unreachable)
  )
  
  (func $tan (param $x f64) (result f64)
    (unreachable)
  )
  
  (func $cosh (param $x f64) (result f64)
    (unreachable)
  )
  
  (func $sinh (param $x f64) (result f64)
    (unreachable)
  )

  (func $tanh (param $x f64) (result f64)
    (unreachable)
  )
  
  (func $exp (param $x f64) (result f64)
    (unreachable)
  )
  
  ;; Uses multiple return in place of return pointer
  (func $frexp (param $x f64) (result i32 f64)
    (unreachable)
  )

  (func $ldexp (param $x f64) (param $exp i32) (result f64)
    (unreachable)
  )

  (func $log (param $x f64) (result f64)
    (unreachable)
  )

  (func $log10 (param $x f64) (result f64)
    (unreachable)
  )
  
  (func $modf (param $value f64) (result f64 f64)
    (unreachable)
  )
  
  (func $pow (param $x f64) (param $y f64) (result f64)
    (unreachable)
  )

  (func $sqrt (param $x f64) (result f64)
    (f64.sqrt (local.get $x))
  )

  (func $ceil (param $x f64) (result f64)
    (f64.ceil (local.get $x))
  )

  (func $fabs (param $x f64) (result f64)
    (f64.abs (local.get $x))
  )

  (func $floor (param $x f64) (result f64)
    (f64.floor (local.get $x))
  )

  (func $fmod (param $x f64) (param $y f64) (result f64)
    (unreachable)
  )

  ;; setjmp.h - Skipped!
  ;; signal.h - Skipped!
  ;; stdarg.h - Skipped!
  ;; stddef.h - Skipped!
  ;; stdio.h - Skipped!

  (func $abs (param $i i32) (result i32)
    (if (result i32) (i32.lt_s (local.get $i) (i32.const 0)) (then
      (i32.mul (local.get $i) (i32.const -1))
    ) (else
      (local.get $i)
    ))
  )

  (func $labs (param $i i64) (result i64)
    (if (result i64) (i64.lt_s (local.get $i) (i64.const 0)) (then
      (i64.mul (local.get $i) (i64.const -1))
    ) (else
      (local.get $i)
    ))
  )
    
  ;; Compute quotient and remainder of integer division. 
  ;; Returns 2-tuple in place of dib_t struct
  (func $div (param $numerator i32) (param $denominator i32) (result i32 i32)
    (i32.div_s (local.get $numerator) (local.get $denominator))
    (i32.rem_s (local.get $numerator) (local.get $denominator))
  )

  (func $ldiv (param $numerator i64) (param $denominator i64) (result i64 i64)
    (i64.div_s (local.get $numerator) (local.get $denominator))
    (i64.rem_s (local.get $numerator) (local.get $denominator))
  )

  (func $bsearch)
  (func $qsort)
  (func $rand)
  (func $srand)
  (func $atof)
  (func $atoi)
  (func $strtod)
  (func $strtol)

  ;; Copies a range of bytes from src to dst
  ;; memory.copy is able to handle overlapping regions in linear memory, so there is no distinction
  ;; between memmove and memcpy
  (func $memcpy (param $dst i32) (param $src i32) (param $size i32) (result i32)
    (call $memmove (local.get $dst) (local.get $src) (local.get $size))
  )

  (func $memmove (param $dst i32) (param $src i32) (param $size i32) (result i32)
    (memory.copy (local.get $dst) (local.get $src) (local.get $size))
    (local.get $dst)
  )

  ;; Searches the region of size n starting at s for the byte c
  ;; Returns offset of match or NULL (0) if not found
  (func $memchr (param $s i32) (param $c i32) (param $n i32) (result i32)
    (local $i i32)
    (local.set $i (i32.const 0))

    (if (i32.lt_u (local.get $i) (local.get $n)) (then
      (loop
        (if (i32.eq (i32.load8_u (i32.add (local.get $s) (local.get $i))) (local.get $c)) (then
          (return (i32.add (local.get $s) (local.get $i)))
        ))
        (br_if 0 (i32.lt_u (local.tee $i (i32.add (local.get $i) (i32.const 1))) (local.get $n)))
      )
    ))

    (i32.const 0)
  )

  (func $memset (param $s i32) (param $c i32) (param $n i32)
    (memory.fill (local.get $s) (local.get $c) (local.get $n))
  )

  ;; Compares the two regions starting at offsets s1 and s2 of identical size n match byte-for-byte
  ;; Returns -1 if range s1 is less than s2, 0 if range s1 matchs s2, 1 if range s1 is greater than s2
  (func $memcmp (param $s1 i32) (param $s2 i32) (param $n i32) (result i32) 
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

  (func $strcpy)
  (func $strncpy)
  (func $strcat)
  (func $strncat)
  (func $strlen)
  (func $strcmp)
  (func $strcoll)
  (func $strncmp)
  (func $strxfrm)
  (func $strchr)
  (func $strcspn)
  (func $strpbrk)
  (func $strrchr)
  (func $strspn)
  (func $strstr)
  (func $strtok)
  (func $strerror)
)