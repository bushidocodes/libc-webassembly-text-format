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
    (loop
      (i32.store8 (local.get $high) (i32.add (i32.const 48) (i32.rem_u (local.get $x) (local.get $radix))))
      (local.set $high (i32.add (local.get $high) (i32.const 1)))
      (br_if 0 (i32.gt_u (local.tee $x (i32.div_u (local.get $x) (local.get $radix))) (i32.const 0)))
    )
  
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

  ;; Note: result is undefined for i32.const 0x80000000 (INT_MIN), matching C UB
  (func $abs (param $i i32) (result i32)
    (if (result i32) (i32.lt_s (local.get $i) (i32.const 0)) (then
      (i32.sub (i32.const 0) (local.get $i))
    ) (else
      (local.get $i)
    ))
  )

  ;; Note: result is undefined for i64.const 0x8000000000000000 (LLONG_MIN), matching C UB
  (func $labs (param $i i64) (result i64)
    (if (result i64) (i64.lt_s (local.get $i) (i64.const 0)) (then
      (i64.sub (i64.const 0) (local.get $i))
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

  ;; Stubs retain their correct C-compatible signatures so they can be imported
  ;; with the right type today; the (unreachable) body traps until implemented.
  ;; Following this library's conventions: C `long` maps to i64 (as in $labs /
  ;; $ldiv) and pointer out-params map to multi-value returns (as in $div /
  ;; $frexp), so e.g. strtol's `char **endptr` is returned as a second result.

  ;; void *bsearch(const void *key, const void *base, size_t nmemb, size_t size,
  ;;               int (*compar)(const void *, const void *))
  (func $bsearch (param $key i32) (param $base i32) (param $nmemb i32) (param $size i32) (param $compar i32) (result i32)
    (unreachable)
  )

  ;; void qsort(void *base, size_t nmemb, size_t size,
  ;;            int (*compar)(const void *, const void *))
  (func $qsort (param $base i32) (param $nmemb i32) (param $size i32) (param $compar i32)
    (unreachable)
  )

  ;; int rand(void)
  (func $rand (result i32)
    (unreachable)
  )

  ;; void srand(unsigned int seed)
  (func $srand (param $seed i32)
    (unreachable)
  )

  ;; double atof(const char *nptr)
  (func $atof (param $nptr i32) (result f64)
    (unreachable)
  )

  ;; int atoi(const char *nptr)
  (func $atoi (param $nptr i32) (result i32)
    (unreachable)
  )

  ;; double strtod(const char *nptr, char **endptr)
  ;; Returns (value, endptr) in place of the char** out-param.
  (func $strtod (param $nptr i32) (result f64 i32)
    (unreachable)
  )

  ;; long strtol(const char *nptr, char **endptr, int base)
  ;; Returns (value, endptr) in place of the char** out-param.
  (func $strtol (param $nptr i32) (param $base i32) (result i64 i32)
    (unreachable)
  )

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

  (func $memset (param $s i32) (param $c i32) (param $n i32) (result i32)
    (memory.fill (local.get $s) (local.get $c) (local.get $n))
    (local.get $s)
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
        (br_if 0 (i32.gt_s (local.tee $n (i32.sub (local.get $n) (i32.const 1))) (i32.const 0)))
      )  
    ))
    (i32.const 0)
  )

  ;; char *strcpy(char *dst, const char *src)
  ;; Copies src (including its terminating NUL) into dst and returns dst.
  (func $strcpy (param $dst i32) (param $src i32) (result i32)
    (local $d i32)
    (local $c i32)
    (local.set $d (local.get $dst))
    (loop $loop
      (local.set $c (i32.load8_u (local.get $src)))
      (i32.store8 (local.get $d) (local.get $c))
      (local.set $src (i32.add (local.get $src) (i32.const 1)))
      (local.set $d (i32.add (local.get $d) (i32.const 1)))
      (br_if $loop (local.get $c)) ;; continue until the NUL has been copied
    )
    (local.get $dst)
  )

  ;; char *strncpy(char *dst, const char *src, size_t n)
  ;; Copies at most n bytes from src into dst. If src is shorter than n, the
  ;; remainder of dst is padded with NULs; if src is n bytes or longer, no
  ;; terminating NUL is written. Returns dst.
  (func $strncpy (param $dst i32) (param $src i32) (param $n i32) (result i32)
    (local $d i32)
    (local $c i32)
    (local.set $d (local.get $dst))
    (block $done
      (loop $loop
        (br_if $done (i32.eqz (local.get $n)))
        (local.set $c (i32.load8_u (local.get $src)))
        (i32.store8 (local.get $d) (local.get $c))
        (local.set $d (i32.add (local.get $d) (i32.const 1)))
        (local.set $n (i32.sub (local.get $n) (i32.const 1)))
        (if (i32.eqz (local.get $c)) (then
          ;; reached the end of src: pad the rest of dst with NULs
          (drop (call $memset (local.get $d) (i32.const 0) (local.get $n)))
          (br $done)
        ))
        (local.set $src (i32.add (local.get $src) (i32.const 1)))
        (br $loop)
      )
    )
    (local.get $dst)
  )

  ;; char *strcat(char *dst, const char *src)
  ;; Appends src to the end of the string in dst and returns dst.
  (func $strcat (param $dst i32) (param $src i32) (result i32)
    (drop (call $strcpy
      (i32.add (local.get $dst) (call $strlen (local.get $dst)))
      (local.get $src)
    ))
    (local.get $dst)
  )

  ;; char *strncat(char *dst, const char *src, size_t n)
  ;; Appends at most n bytes from src to the end of the string in dst, then
  ;; always writes a terminating NUL. Returns dst.
  (func $strncat (param $dst i32) (param $src i32) (param $n i32) (result i32)
    (local $d i32)
    (local $c i32)
    (local.set $d (i32.add (local.get $dst) (call $strlen (local.get $dst))))
    (block $done
      (loop $loop
        (br_if $done (i32.eqz (local.get $n)))
        (local.set $c (i32.load8_u (local.get $src)))
        (br_if $done (i32.eqz (local.get $c))) ;; stop at end of src
        (i32.store8 (local.get $d) (local.get $c))
        (local.set $d (i32.add (local.get $d) (i32.const 1)))
        (local.set $src (i32.add (local.get $src) (i32.const 1)))
        (local.set $n (i32.sub (local.get $n) (i32.const 1)))
        (br $loop)
      )
    )
    (i32.store8 (local.get $d) (i32.const 0))
    (local.get $dst)
  )

  ;; size_t strlen(const char *s)
  (func $strlen (param $s i32) (result i32)
    (local $cursor i32)
    (local.set $cursor (local.get $s))
    (block $done
      (loop $loop
        (br_if $done (i32.eqz (i32.load8_u (local.get $cursor))))
        (local.set $cursor (i32.add (local.get $cursor) (i32.const 1)))
        (br $loop)
      )
    )
    (i32.sub (local.get $cursor) (local.get $s))
  )

  ;; int strcmp(const char *s1, const char *s2)
  ;; Returns -1, 0, or 1 (matching $memcmp's convention) according to whether
  ;; s1 sorts before, equal to, or after s2 by unsigned byte comparison.
  (func $strcmp (param $s1 i32) (param $s2 i32) (result i32)
    (local $c1 i32)
    (local $c2 i32)
    (loop $loop
      (local.set $c1 (i32.load8_u (local.get $s1)))
      (local.set $c2 (i32.load8_u (local.get $s2)))
      (if (i32.ne (local.get $c1) (local.get $c2)) (then
        (return (if (result i32) (i32.lt_u (local.get $c1) (local.get $c2))
          (then (i32.const -1))
          (else (i32.const 1))
        ))
      ))
      ;; bytes are equal here; if they are both NUL the strings fully match
      (if (i32.eqz (local.get $c1)) (then (return (i32.const 0))))
      (local.set $s1 (i32.add (local.get $s1) (i32.const 1)))
      (local.set $s2 (i32.add (local.get $s2) (i32.const 1)))
      (br $loop)
    )
    (unreachable)
  )

  ;; int strcoll(const char *s1, const char *s2)
  ;; In the ASCII "C" locale this library targets, collation order is plain
  ;; byte order, so strcoll is equivalent to strcmp.
  (func $strcoll (param $s1 i32) (param $s2 i32) (result i32)
    (call $strcmp (local.get $s1) (local.get $s2))
  )

  ;; int strncmp(const char *s1, const char *s2, size_t n)
  ;; Like strcmp but compares at most n bytes. Returns -1, 0, or 1.
  (func $strncmp (param $s1 i32) (param $s2 i32) (param $n i32) (result i32)
    (local $c1 i32)
    (local $c2 i32)
    (block $done
      (br_if $done (i32.eqz (local.get $n)))
      (loop $loop
        (local.set $c1 (i32.load8_u (local.get $s1)))
        (local.set $c2 (i32.load8_u (local.get $s2)))
        (if (i32.ne (local.get $c1) (local.get $c2)) (then
          (return (if (result i32) (i32.lt_u (local.get $c1) (local.get $c2))
            (then (i32.const -1))
            (else (i32.const 1))
          ))
        ))
        (if (i32.eqz (local.get $c1)) (then (return (i32.const 0))))
        (local.set $s1 (i32.add (local.get $s1) (i32.const 1)))
        (local.set $s2 (i32.add (local.get $s2) (i32.const 1)))
        (br_if $loop (i32.gt_u (local.tee $n (i32.sub (local.get $n) (i32.const 1))) (i32.const 0)))
      )
    )
    (i32.const 0)
  )

  ;; size_t strxfrm(char *dst, const char *src, size_t n)
  (func $strxfrm (param $dst i32) (param $src i32) (param $n i32) (result i32)
    (unreachable)
  )

  ;; char *strchr(const char *s, int c)
  (func $strchr (param $s i32) (param $c i32) (result i32)
    (unreachable)
  )

  ;; size_t strcspn(const char *s, const char *reject)
  (func $strcspn (param $s i32) (param $reject i32) (result i32)
    (unreachable)
  )

  ;; char *strpbrk(const char *s, const char *accept)
  (func $strpbrk (param $s i32) (param $accept i32) (result i32)
    (unreachable)
  )

  ;; char *strrchr(const char *s, int c)
  (func $strrchr (param $s i32) (param $c i32) (result i32)
    (unreachable)
  )

  ;; size_t strspn(const char *s, const char *accept)
  (func $strspn (param $s i32) (param $accept i32) (result i32)
    (unreachable)
  )

  ;; char *strstr(const char *haystack, const char *needle)
  (func $strstr (param $haystack i32) (param $needle i32) (result i32)
    (unreachable)
  )

  ;; char *strtok(char *str, const char *delim)
  (func $strtok (param $str i32) (param $delim i32) (result i32)
    (unreachable)
  )

  ;; char *strerror(int errnum)
  (func $strerror (param $errnum i32) (result i32)
    (unreachable)
  )

  ;; Exports
  ;; The linear memory and every implemented function are exported so the
  ;; library can be consumed from a host runtime (and exercised by tests).
  (export "memory" (memory 0))

  ;; assert.h
  (export "assert" (func $assert))

  ;; ctype.h
  (export "isalnum" (func $isalnum))
  (export "isalpha" (func $isalpha))
  (export "isascii" (func $isascii))
  (export "isblank" (func $isblank))
  (export "iscntrl" (func $iscntrl))
  (export "isdigit" (func $isdigit))
  (export "isgraph" (func $isgraph))
  (export "islower" (func $islower))
  (export "isprint" (func $isprint))
  (export "ispunct" (func $ispunct))
  (export "isspace" (func $isspace))
  (export "isupper" (func $isupper))
  (export "isxdigit" (func $isxdigit))
  (export "toupper" (func $toupper))
  (export "tolower" (func $tolower))

  ;; math.h
  (export "sqrt" (func $sqrt))
  (export "ceil" (func $ceil))
  (export "fabs" (func $fabs))
  (export "floor" (func $floor))

  ;; stdlib.h
  (export "itoa_s" (func $itoa_s))
  (export "abs" (func $abs))
  (export "labs" (func $labs))
  (export "div" (func $div))
  (export "ldiv" (func $ldiv))
  ;; Stubs (correct signature, traps until implemented)
  (export "bsearch" (func $bsearch))
  (export "qsort" (func $qsort))
  (export "rand" (func $rand))
  (export "srand" (func $srand))
  (export "atof" (func $atof))
  (export "atoi" (func $atoi))
  (export "strtod" (func $strtod))
  (export "strtol" (func $strtol))

  ;; string.h
  (export "memcpy" (func $memcpy))
  (export "memmove" (func $memmove))
  (export "memchr" (func $memchr))
  (export "memset" (func $memset))
  (export "memcmp" (func $memcmp))
  (export "strcpy" (func $strcpy))
  (export "strncpy" (func $strncpy))
  (export "strcat" (func $strcat))
  (export "strncat" (func $strncat))
  (export "strlen" (func $strlen))
  (export "strcmp" (func $strcmp))
  (export "strcoll" (func $strcoll))
  (export "strncmp" (func $strncmp))
  ;; Stubs (correct signature, traps until implemented)
  (export "strxfrm" (func $strxfrm))
  (export "strchr" (func $strchr))
  (export "strcspn" (func $strcspn))
  (export "strpbrk" (func $strpbrk))
  (export "strrchr" (func $strrchr))
  (export "strspn" (func $strspn))
  (export "strstr" (func $strstr))
  (export "strtok" (func $strtok))
  (export "strerror" (func $strerror))
)