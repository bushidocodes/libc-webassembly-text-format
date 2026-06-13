(module

  (memory 1)

  ;; Signature of the comparator passed to $bsearch / $qsort:
  ;; int compar(const void *a, const void *b)
  (type $compar_t (func (param i32 i32) (result i32)))

  ;; Function table used to invoke a caller-supplied comparator via
  ;; call_indirect. A host installs its comparator into the exported
  ;; "__indirect_function_table" and passes the slot index as the compar
  ;; argument. One slot exists by default; grow the table for more.
  (table $indirect 1 funcref)

  (global $errno (mut i32) (i32.const 0))
  (global $EDOM i32 (i32.const 1))
  (global $ERANGE i32 (i32.const 2))
  (global $NULL i32 (i32.const 0))

  ;; Saved scan position for $strtok across successive calls. Like the C
  ;; standard's strtok, this is process-global state and is not reentrant.
  (global $strtok_save (mut i32) (i32.const 0))

  ;; PRNG state for $rand / $srand. Held as a 64-bit value (C `unsigned long`)
  ;; and seeded to 1, matching the C standard's reference generator.
  (global $rand_seed (mut i64) (i64.const 1))

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

  ;; Masks charCode down to 7 bits, mapping it into the ASCII range.
  (func $toascii (param $charCode i32) (result i32)
    (i32.and (local.get $charCode) (i32.const 0x7f))
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

  ;; arctangent, Cephes algorithm: fold |x| into [0, tan(pi/8)] using
  ;; atan(x) = pi/2 - atan(1/x) or pi/4 + atan((x-1)/(x+1)), then a rational
  ;; minimax approximation. Accurate to ~1 ULP. atan(+/-inf) = +/-pi/2.
  (func $atan (param $x f64) (result f64)
    (local $y f64)     ;; the constant offset (0, pi/4, or pi/2)
    (local $corr f64)  ;; extra-precision correction for that offset
    (local $z f64)
    (local $zz f64)
    (local $p f64)
    (local $q f64)
    (local $sign i32)
    (if (f64.ne (local.get $x) (local.get $x)) (then (return (local.get $x)))) ;; NaN
    (if (f64.eq (local.get $x) (f64.const 0)) (then (return (local.get $x)))) ;; preserve +/-0
    (if (f64.eq (f64.abs (local.get $x)) (f64.const inf)) (then
      (return (f64.copysign (f64.const 1.5707963267948966) (local.get $x))) ;; +/-pi/2
    ))
    (local.set $sign (i32.const 1))
    (if (f64.lt (local.get $x) (f64.const 0)) (then
      (local.set $x (f64.neg (local.get $x)))
      (local.set $sign (i32.const -1))
    ))
    ;; range reduction
    (if (f64.gt (local.get $x) (f64.const 2.41421356237309504880)) (then ;; x > tan(3pi/8)
      (local.set $y (f64.const 1.5707963267948966))               ;; pi/2
      (local.set $corr (f64.const 6.123233995736765886130e-17))
      (local.set $x (f64.neg (f64.div (f64.const 1) (local.get $x))))
    ) (else (if (f64.le (local.get $x) (f64.const 0.66)) (then ;; small: no reduction
      (local.set $y (f64.const 0))
      (local.set $corr (f64.const 0))
    ) (else
      (local.set $y (f64.const 0.7853981633974483))                ;; pi/4
      (local.set $corr (f64.const 3.061616997868382943065e-17))    ;; 0.5 * MOREBITS
      (local.set $x (f64.div (f64.sub (local.get $x) (f64.const 1)) (f64.add (local.get $x) (f64.const 1))))
    ))))
    (local.set $zz (f64.mul (local.get $x) (local.get $x)))
    ;; P(zz): degree 4 (5 coefficients)
    (local.set $p (f64.const -8.750608600031904122785e-1))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const -1.615753718733365076637e1)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const -7.500855792314704667340e1)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const -1.228866684490136173410e2)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const -6.485021904942025371773e1)))
    ;; Q(zz): monic degree 5 (5 trailing coefficients)
    (local.set $q (f64.add (local.get $zz) (f64.const 2.485846490142306297962e1)))
    (local.set $q (f64.add (f64.mul (local.get $q) (local.get $zz)) (f64.const 1.650270098316988542046e2)))
    (local.set $q (f64.add (f64.mul (local.get $q) (local.get $zz)) (f64.const 4.328810604912902668951e2)))
    (local.set $q (f64.add (f64.mul (local.get $q) (local.get $zz)) (f64.const 4.853903996359136964868e2)))
    (local.set $q (f64.add (f64.mul (local.get $q) (local.get $zz)) (f64.const 1.945506571482613964425e2)))
    ;; z = x + x * zz * P/Q  (then add the offset and its correction)
    (local.set $z (f64.add (local.get $x)
      (f64.mul (local.get $x) (f64.mul (local.get $zz) (f64.div (local.get $p) (local.get $q))))))
    (local.set $z (f64.add (local.get $y) (f64.add (local.get $z) (local.get $corr))))
    (if (i32.lt_s (local.get $sign) (i32.const 0)) (then (local.set $z (f64.neg (local.get $z)))))
    (local.get $z)
  )

  ;; Two-argument arctangent: the angle of the point (x, y), in (-pi, pi].
  (func $atan2 (param $y f64) (param $x f64) (result f64)
    (if (i32.or (f64.ne (local.get $x) (local.get $x)) (f64.ne (local.get $y) (local.get $y)))
      (then (return (f64.const nan))))
    ;; x is +/- infinity
    (if (f64.eq (local.get $x) (f64.const inf)) (then
      (if (f64.eq (local.get $y) (f64.const inf)) (then (return (f64.const 0.7853981633974483))))      ;; pi/4
      (if (f64.eq (local.get $y) (f64.const -inf)) (then (return (f64.const -0.7853981633974483))))
      (return (f64.copysign (f64.const 0) (local.get $y)))
    ))
    (if (f64.eq (local.get $x) (f64.const -inf)) (then
      (if (f64.eq (local.get $y) (f64.const inf)) (then (return (f64.const 2.356194490192345))))       ;; 3pi/4
      (if (f64.eq (local.get $y) (f64.const -inf)) (then (return (f64.const -2.356194490192345))))
      (return (f64.copysign (f64.const 3.141592653589793) (local.get $y)))
    ))
    ;; y is +/- infinity (x finite)
    (if (f64.eq (local.get $y) (f64.const inf)) (then (return (f64.const 1.5707963267948966))))
    (if (f64.eq (local.get $y) (f64.const -inf)) (then (return (f64.const -1.5707963267948966))))
    ;; x == 0 (either sign)
    (if (f64.eq (local.get $x) (f64.const 0)) (then
      (if (f64.eq (local.get $y) (f64.const 0)) (then
        ;; both zero: +0 base gives +/-0; -0 base gives +/-pi
        (if (i64.lt_s (i64.reinterpret_f64 (local.get $x)) (i64.const 0))
          (then (return (f64.copysign (f64.const 3.141592653589793) (local.get $y))))
          (else (return (local.get $y))))
      ))
      (return (f64.copysign (f64.const 1.5707963267948966) (local.get $y)))
    ))
    ;; general finite case
    (if (f64.gt (local.get $x) (f64.const 0))
      (then (return (call $atan (f64.div (local.get $y) (local.get $x))))) ;; quadrants I, IV
      (else ;; x < 0: quadrants II, III, offset by +/- pi per sign of y
        (return (f64.add
          (call $atan (f64.div (local.get $y) (local.get $x)))
          (f64.copysign (f64.const 3.141592653589793) (local.get $y))))))
    (unreachable)
  )

  ;; arcsine, via asin(x) = atan2(x, sqrt((1-x)(1+x))). Factoring 1 - x^2 as
  ;; (1-x)(1+x) avoids cancellation near |x| = 1. Domain |x| <= 1 (else NaN,
  ;; errno EDOM).
  (func $asin (param $x f64) (result f64)
    (if (f64.gt (f64.abs (local.get $x)) (f64.const 1)) (then
      (global.set $errno (global.get $EDOM))
      (return (f64.const nan))
    ))
    (call $atan2 (local.get $x)
      (f64.sqrt (f64.mul (f64.sub (f64.const 1) (local.get $x)) (f64.add (f64.const 1) (local.get $x)))))
  )

  ;; arccosine, via acos(x) = atan2(sqrt((1-x)(1+x)), x). Domain |x| <= 1 (else
  ;; NaN, errno EDOM).
  (func $acos (param $x f64) (result f64)
    (if (f64.gt (f64.abs (local.get $x)) (f64.const 1)) (then
      (global.set $errno (global.get $EDOM))
      (return (f64.const nan))
    ))
    (call $atan2
      (f64.sqrt (f64.mul (f64.sub (f64.const 1) (local.get $x)) (f64.add (f64.const 1) (local.get $x))))
      (local.get $x))
  )
  
  ;; sin(z) for the reduced argument z in [-pi/4, pi/4] (Cephes sincof series).
  (func $__sin_series (param $z f64) (result f64)
    (local $zz f64)
    (local $p f64)
    (local.set $zz (f64.mul (local.get $z) (local.get $z)))
    (local.set $p (f64.const 1.58962301576546568060e-10))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const -2.50507477628578072866e-8)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const 2.75573136213857245213e-6)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const -1.98412698295895385996e-4)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const 8.33333333332211858878e-3)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const -1.66666666666666307295e-1)))
    ;; z + z * zz * P(zz)
    (f64.add (local.get $z) (f64.mul (f64.mul (local.get $z) (local.get $zz)) (local.get $p)))
  )

  ;; cos(z) for the reduced argument z in [-pi/4, pi/4] (Cephes coscof series).
  (func $__cos_series (param $z f64) (result f64)
    (local $zz f64)
    (local $p f64)
    (local.set $zz (f64.mul (local.get $z) (local.get $z)))
    (local.set $p (f64.const -1.13585365213876817300e-11))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const 2.08757008419747316778e-9)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const -2.75573141792967388112e-7)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const 2.48015872888517045348e-5)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const -1.38888888888730564116e-3)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const 4.16666666666665929218e-2)))
    ;; 1 - zz/2 + zz*zz * P(zz)
    (f64.add
      (f64.sub (f64.const 1) (f64.mul (f64.const 0.5) (local.get $zz)))
      (f64.mul (f64.mul (local.get $zz) (local.get $zz)) (local.get $p)))
  )

  ;; cos(x). Reduces x modulo pi/4 (octant-based) using an extended-precision
  ;; pi/4 split, then evaluates the sin or cos series. ~1-2 ULP for |x| up to a
  ;; few million; precision degrades for very large arguments. cos(+/-inf) = NaN.
  (func $cos (param $x f64) (result f64)
    (local $y f64)
    (local $z f64)
    (local $sign i32)
    (local $j i32)
    (if (f64.ne (local.get $x) (local.get $x)) (then (return (local.get $x)))) ;; NaN
    (if (f64.eq (f64.abs (local.get $x)) (f64.const inf)) (then (return (f64.const nan))))
    (local.set $sign (i32.const 1))
    (local.set $x (f64.abs (local.get $x))) ;; cos is even
    (local.set $y (f64.floor (f64.mul (local.get $x) (f64.const 1.27323954473516276487)))) ;; x * 4/pi
    (local.set $z (f64.floor (call $ldexp (local.get $y) (i32.const -4))))
    (local.set $j (i32.trunc_f64_s (f64.sub (local.get $y) (call $ldexp (local.get $z) (i32.const 4)))))
    (if (i32.and (local.get $j) (i32.const 1)) (then
      (local.set $j (i32.add (local.get $j) (i32.const 1)))
      (local.set $y (f64.add (local.get $y) (f64.const 1)))
    ))
    (local.set $j (i32.and (local.get $j) (i32.const 7)))
    (if (i32.gt_s (local.get $j) (i32.const 3)) (then
      (local.set $j (i32.sub (local.get $j) (i32.const 4)))
      (local.set $sign (i32.sub (i32.const 0) (local.get $sign)))
    ))
    (if (i32.gt_s (local.get $j) (i32.const 1)) (then
      (local.set $sign (i32.sub (i32.const 0) (local.get $sign)))
    ))
    ;; z = ((x - y*DP1) - y*DP2) - y*DP3, DP1+DP2+DP3 = pi/4
    ;; z = (x - y*DP1) - y*DP2, with DP1 + DP2 = pi/4 (two-part for precision)
    (local.set $z (f64.sub (f64.sub (local.get $x)
      (f64.mul (local.get $y) (f64.const 0.785398170351982116699)))
      (f64.mul (local.get $y) (f64.const -6.95453383769972788286e-9))))
    (if (i32.or (i32.eq (local.get $j) (i32.const 1)) (i32.eq (local.get $j) (i32.const 2)))
      (then (local.set $y (call $__sin_series (local.get $z))))
      (else (local.set $y (call $__cos_series (local.get $z)))))
    (if (i32.lt_s (local.get $sign) (i32.const 0)) (then (local.set $y (f64.neg (local.get $y)))))
    (local.get $y)
  )

  ;; sin(x). Same reduction as cos with sin's octant/sign handling.
  (func $sin (param $x f64) (result f64)
    (local $y f64)
    (local $z f64)
    (local $sign i32)
    (local $j i32)
    (if (f64.ne (local.get $x) (local.get $x)) (then (return (local.get $x)))) ;; NaN
    (if (f64.eq (f64.abs (local.get $x)) (f64.const inf)) (then (return (f64.const nan))))
    (local.set $sign (i32.const 1))
    (if (f64.lt (local.get $x) (f64.const 0)) (then
      (local.set $x (f64.neg (local.get $x)))
      (local.set $sign (i32.const -1))
    ))
    (local.set $y (f64.floor (f64.mul (local.get $x) (f64.const 1.27323954473516276487))))
    (local.set $z (f64.floor (call $ldexp (local.get $y) (i32.const -4))))
    (local.set $j (i32.trunc_f64_s (f64.sub (local.get $y) (call $ldexp (local.get $z) (i32.const 4)))))
    (if (i32.and (local.get $j) (i32.const 1)) (then
      (local.set $j (i32.add (local.get $j) (i32.const 1)))
      (local.set $y (f64.add (local.get $y) (f64.const 1)))
    ))
    (local.set $j (i32.and (local.get $j) (i32.const 7)))
    (if (i32.gt_s (local.get $j) (i32.const 3)) (then
      (local.set $j (i32.sub (local.get $j) (i32.const 4)))
      (local.set $sign (i32.sub (i32.const 0) (local.get $sign)))
    ))
    ;; z = (x - y*DP1) - y*DP2, with DP1 + DP2 = pi/4 (two-part for precision)
    (local.set $z (f64.sub (f64.sub (local.get $x)
      (f64.mul (local.get $y) (f64.const 0.785398170351982116699)))
      (f64.mul (local.get $y) (f64.const -6.95453383769972788286e-9))))
    (if (i32.or (i32.eq (local.get $j) (i32.const 1)) (i32.eq (local.get $j) (i32.const 2)))
      (then (local.set $y (call $__cos_series (local.get $z))))
      (else (local.set $y (call $__sin_series (local.get $z)))))
    (if (i32.lt_s (local.get $sign) (i32.const 0)) (then (local.set $y (f64.neg (local.get $y)))))
    (local.get $y)
  )

  ;; tan(x), via Cephes' rational approximation on the reduced argument with a
  ;; cotangent reflection for the odd octants. tan(+/-inf) = NaN.
  (func $tan (param $x f64) (result f64)
    (local $y f64)
    (local $z f64)
    (local $zz f64)
    (local $p f64)
    (local $q f64)
    (local $sign i32)
    (local $j i32)
    (if (f64.ne (local.get $x) (local.get $x)) (then (return (local.get $x)))) ;; NaN
    (if (f64.eq (f64.abs (local.get $x)) (f64.const inf)) (then (return (f64.const nan))))
    (if (f64.eq (local.get $x) (f64.const 0)) (then (return (local.get $x)))) ;; preserve -0
    (local.set $sign (i32.const 1))
    (if (f64.lt (local.get $x) (f64.const 0)) (then
      (local.set $x (f64.neg (local.get $x)))
      (local.set $sign (i32.const -1))
    ))
    (local.set $y (f64.floor (f64.mul (local.get $x) (f64.const 1.27323954473516276487))))
    (local.set $z (f64.floor (call $ldexp (local.get $y) (i32.const -4))))
    (local.set $j (i32.trunc_f64_s (f64.sub (local.get $y) (call $ldexp (local.get $z) (i32.const 4)))))
    (if (i32.and (local.get $j) (i32.const 1)) (then
      (local.set $j (i32.add (local.get $j) (i32.const 1)))
      (local.set $y (f64.add (local.get $y) (f64.const 1)))
    ))
    ;; z = (x - y*DP1) - y*DP2, with DP1 + DP2 = pi/4 (two-part for precision)
    (local.set $z (f64.sub (f64.sub (local.get $x)
      (f64.mul (local.get $y) (f64.const 0.785398170351982116699)))
      (f64.mul (local.get $y) (f64.const -6.95453383769972788286e-9))))
    (local.set $zz (f64.mul (local.get $z) (local.get $z)))
    (if (f64.gt (local.get $zz) (f64.const 1.0e-14)) (then
      ;; P(zz): degree 2 (3 coefficients)
      (local.set $p (f64.const -1.30936939181383777646e4))
      (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const 1.15351664838587416140e6)))
      (local.set $p (f64.add (f64.mul (local.get $p) (local.get $zz)) (f64.const -1.79565251976484877988e7)))
      ;; Q(zz): monic degree 4 (4 trailing coefficients)
      (local.set $q (f64.add (local.get $zz) (f64.const 1.36812963470692954678e4)))
      (local.set $q (f64.add (f64.mul (local.get $q) (local.get $zz)) (f64.const -1.32089234440210967447e6)))
      (local.set $q (f64.add (f64.mul (local.get $q) (local.get $zz)) (f64.const 2.50083801823357915839e7)))
      (local.set $q (f64.add (f64.mul (local.get $q) (local.get $zz)) (f64.const -5.38695755929454629881e7)))
      ;; y = z + z * (zz * P/Q)
      (local.set $y (f64.add (local.get $z)
        (f64.mul (local.get $z) (f64.mul (local.get $zz) (f64.div (local.get $p) (local.get $q))))))
    ) (else
      (local.set $y (local.get $z))
    ))
    ;; odd octant -> cotangent reflection
    (if (i32.and (local.get $j) (i32.const 2)) (then
      (local.set $y (f64.div (f64.const -1) (local.get $y)))
    ))
    (if (i32.lt_s (local.get $sign) (i32.const 0)) (then (local.set $y (f64.neg (local.get $y)))))
    (local.get $y)
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
  
  ;; e^x via Cephes range reduction: x = n*ln2 + r, exp(x) = 2^n * exp(r), with
  ;; exp(r) from a rational minimax approximation on the reduced r. Accurate to
  ;; ~1 ULP. Overflows to +inf (errno ERANGE) above ~709.78 and underflows to 0
  ;; (errno ERANGE) below ~-708.40.
  (func $exp (param $x f64) (result f64)
    (local $n f64)
    (local $ni i32)
    (local $xx f64)
    (local $px f64)
    ;; NaN passes through (and must not reach the float->int conversion below)
    (if (f64.ne (local.get $x) (local.get $x)) (then (return (local.get $x))))
    (if (f64.gt (local.get $x) (f64.const 709.782712893383996732)) (then
      (global.set $errno (global.get $ERANGE))
      (return (f64.const inf))
    ))
    (if (f64.lt (local.get $x) (f64.const -708.396418532264106224)) (then
      (global.set $errno (global.get $ERANGE))
      (return (f64.const 0))
    ))
    ;; n = round(x / ln2); reduce x to r = x - n*ln2 (ln2 split into C1+C2)
    (local.set $n (f64.floor (f64.add (f64.mul (f64.const 1.4426950408889634073599) (local.get $x)) (f64.const 0.5))))
    (local.set $ni (i32.trunc_f64_s (local.get $n)))
    (local.set $x (f64.sub (local.get $x) (f64.mul (local.get $n) (f64.const 6.93145751953125e-1))))
    (local.set $x (f64.sub (local.get $x) (f64.mul (local.get $n) (f64.const 1.42860682030941723212e-6))))
    (local.set $xx (f64.mul (local.get $x) (local.get $x)))
    ;; px = x * P(xx), P degree 2
    (local.set $px (f64.mul (local.get $x)
      (f64.add (f64.mul (f64.add (f64.mul
        (f64.const 1.26177193074810590878e-4) (local.get $xx))
        (f64.const 3.02994407707441961300e-2)) (local.get $xx))
        (f64.const 9.99999999999999999910e-1))))
    ;; x = px / (Q(xx) - px), Q degree 3
    (local.set $x (f64.div (local.get $px)
      (f64.sub
        (f64.add (f64.mul (f64.add (f64.mul (f64.add (f64.mul
          (f64.const 3.00198505138664455042e-6) (local.get $xx))
          (f64.const 2.52448340349684104192e-3)) (local.get $xx))
          (f64.const 2.27265548208155028766e-1)) (local.get $xx))
          (f64.const 2.00000000000000000005e0))
        (local.get $px))))
    ;; exp(r) = 1 + 2x, then scale by 2^n
    (call $ldexp (f64.add (f64.const 1) (f64.mul (f64.const 2) (local.get $x))) (local.get $ni))
  )
  
  ;; Uses multiple return in place of return pointer.
  ;; Splits x into a normalized fraction m (0.5 <= |m| < 1) and an exponent e
  ;; such that x == m * 2^e. Returns (e, m). For 0, inf, and nan, m is x and e is
  ;; 0. (Done by reading and rewriting the IEEE-754 fields directly.)
  (func $frexp (param $x f64) (result i32 f64)
    (local $bits i64)
    (local $ef i32)     ;; raw biased exponent field
    (local $e i32)      ;; accumulated exponent adjustment
    ;; 0, inf, and nan are returned unchanged with e = 0
    (if (f64.eq (local.get $x) (f64.const 0)) (then (return (i32.const 0) (local.get $x))))
    (local.set $bits (i64.reinterpret_f64 (local.get $x)))
    (local.set $ef (i32.wrap_i64 (i64.and (i64.shr_u (local.get $bits) (i64.const 52)) (i64.const 0x7ff))))
    (if (i32.eq (local.get $ef) (i32.const 0x7ff)) (then (return (i32.const 0) (local.get $x))))
    ;; subnormal: scale up by 2^54 to normalize, then account for it in e
    (if (i32.eqz (local.get $ef)) (then
      (local.set $x (f64.mul (local.get $x) (f64.const 0x1p54)))
      (local.set $bits (i64.reinterpret_f64 (local.get $x)))
      (local.set $ef (i32.wrap_i64 (i64.and (i64.shr_u (local.get $bits) (i64.const 52)) (i64.const 0x7ff))))
      (local.set $e (i32.const -54))
    ))
    (local.set $e (i32.add (local.get $e) (i32.sub (local.get $ef) (i32.const 1022))))
    ;; force the biased exponent to 1022 so the fraction lands in [0.5, 1)
    (local.set $bits (i64.or
      (i64.and (local.get $bits) (i64.const 0x800fffffffffffff))
      (i64.const 0x3fe0000000000000)))
    (local.get $e)
    (f64.reinterpret_i64 (local.get $bits))
  )

  ;; Returns x * 2^exp, handling overflow/underflow by staging the scale factor
  ;; (the musl scalbn approach). Equivalent to scalbn for IEEE doubles.
  (func $ldexp (param $x f64) (param $exp i32) (result f64)
    (local $scale f64)
    (if (i32.gt_s (local.get $exp) (i32.const 1023)) (then
      (local.set $x (f64.mul (local.get $x) (f64.const 0x1p1023)))
      (local.set $exp (i32.sub (local.get $exp) (i32.const 1023)))
      (if (i32.gt_s (local.get $exp) (i32.const 1023)) (then
        (local.set $x (f64.mul (local.get $x) (f64.const 0x1p1023)))
        (local.set $exp (i32.sub (local.get $exp) (i32.const 1023)))
        (if (i32.gt_s (local.get $exp) (i32.const 1023)) (then (local.set $exp (i32.const 1023))))
      ))
    ) (else (if (i32.lt_s (local.get $exp) (i32.const -1022)) (then
      (local.set $x (f64.mul (local.get $x) (f64.const 0x1p-969)))
      (local.set $exp (i32.add (local.get $exp) (i32.const 969)))
      (if (i32.lt_s (local.get $exp) (i32.const -1022)) (then
        (local.set $x (f64.mul (local.get $x) (f64.const 0x1p-969)))
        (local.set $exp (i32.add (local.get $exp) (i32.const 969)))
        (if (i32.lt_s (local.get $exp) (i32.const -1022)) (then (local.set $exp (i32.const -1022))))
      ))
    ))))
    (local.set $scale (f64.reinterpret_i64
      (i64.shl (i64.extend_i32_u (i32.add (local.get $exp) (i32.const 1023))) (i64.const 52))))
    (f64.mul (local.get $x) (local.get $scale))
  )

  ;; Natural logarithm via Cephes: x = m * 2^e (frexp), then log(x) = e*ln2 +
  ;; log(m) with log(m) from a rational minimax approximation around 1. Accurate
  ;; to ~1 ULP. log(x<0) is NaN (errno EDOM); log(0) is -inf (errno ERANGE).
  (func $log (param $x f64) (result f64)
    (local $e i32)
    (local $ef f64)
    (local $m f64)
    (local $z f64)
    (local $y f64)
    (local $p f64)  ;; numerator polynomial P(m)
    (local $q f64)  ;; denominator polynomial Q(m), monic
    ;; domain and special values
    (if (f64.ne (local.get $x) (local.get $x)) (then (return (local.get $x)))) ;; NaN
    (if (f64.lt (local.get $x) (f64.const 0)) (then
      (global.set $errno (global.get $EDOM))
      (return (f64.const nan))
    ))
    (if (f64.eq (local.get $x) (f64.const 0)) (then
      (global.set $errno (global.get $ERANGE))
      (return (f64.const -inf))
    ))
    (if (f64.eq (local.get $x) (f64.const inf)) (then (return (local.get $x))))
    ;; m in [0.5, 1), x == m * 2^e
    (call $frexp (local.get $x))
    (local.set $m)
    (local.set $e)
    ;; bring m into [sqrt(1/2), sqrt(2)) so the series converges around 1
    (if (f64.lt (local.get $m) (f64.const 0.70710678118654752440)) (then
      (local.set $e (i32.sub (local.get $e) (i32.const 1)))
      (local.set $m (f64.sub (f64.add (local.get $m) (local.get $m)) (f64.const 1))) ;; 2m - 1
    ) (else
      (local.set $m (f64.sub (local.get $m) (f64.const 1))) ;; m - 1
    ))
    (local.set $ef (f64.convert_i32_s (local.get $e)))
    (local.set $z (f64.mul (local.get $m) (local.get $m)))
    ;; P(m): Horner over 6 coefficients (degree 5)
    (local.set $p (f64.const 1.01875663804580931796e-4))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $m)) (f64.const 4.97494994976747001425e-1)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $m)) (f64.const 4.70579119878881725854e0)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $m)) (f64.const 1.44989225341610930846e1)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $m)) (f64.const 1.79368678507819816313e1)))
    (local.set $p (f64.add (f64.mul (local.get $p) (local.get $m)) (f64.const 7.70838733755885391666e0)))
    ;; Q(m): monic Horner (leading coefficient 1) over 5 trailing coefficients
    (local.set $q (f64.add (local.get $m) (f64.const 1.12873587189167450590e1)))
    (local.set $q (f64.add (f64.mul (local.get $q) (local.get $m)) (f64.const 4.52279145837532221105e1)))
    (local.set $q (f64.add (f64.mul (local.get $q) (local.get $m)) (f64.const 8.29875266912776603211e1)))
    (local.set $q (f64.add (f64.mul (local.get $q) (local.get $m)) (f64.const 7.11544750618563894466e1)))
    (local.set $q (f64.add (f64.mul (local.get $q) (local.get $m)) (f64.const 2.31251620126765340583e1)))
    ;; y = m * (z * P/Q)
    (local.set $y (f64.mul (local.get $m) (f64.mul (local.get $z) (f64.div (local.get $p) (local.get $q)))))
    ;; reconstruct: log(x) = (m + y) + e*ln2, with ln2 split for precision
    (local.set $y (f64.sub (local.get $y) (f64.mul (local.get $ef) (f64.const 2.121944400546905827679e-4))))
    (local.set $y (f64.sub (local.get $y) (f64.mul (f64.const 0.5) (local.get $z))))
    (local.set $z (f64.add (local.get $m) (local.get $y)))
    (f64.add (local.get $z) (f64.mul (local.get $ef) (f64.const 0.693359375)))
  )

  ;; Base-10 logarithm, derived as log(x) * log10(e). Accurate to a few ULP.
  (func $log10 (param $x f64) (result f64)
    (f64.mul (call $log (local.get $x)) (f64.const 0.43429448190325182765))
  )
  
  ;; Uses multiple return in place of return pointer.
  ;; Splits value into its integral and fractional parts (both keeping value's
  ;; sign) and returns (integral, fractional). For +/-inf the integral part is
  ;; +/-inf and the fractional part is +/-0.
  (func $modf (param $value f64) (result f64 f64)
    (local $ip f64)
    (local.set $ip (f64.trunc (local.get $value)))
    (local.get $ip)
    (if (result f64) (f64.eq (f64.abs (local.get $value)) (f64.const inf))
      (then (f64.copysign (f64.const 0) (local.get $value)))
      (else (f64.sub (local.get $value) (local.get $ip))))
  )
  
  ;; base^n for an integer n via binary exponentiation (internal helper). Each
  ;; multiplication rounds once, so small integer powers are near-exact and a
  ;; negative base gets the right sign automatically. n is taken as i64.
  (func $powi (param $base f64) (param $n i64) (result f64)
    (local $result f64)
    (local $neg i32)
    (local.set $result (f64.const 1))
    (if (i64.lt_s (local.get $n) (i64.const 0)) (then
      (local.set $neg (i32.const 1))
      (local.set $n (i64.sub (i64.const 0) (local.get $n)))
    ))
    (block $done (loop $loop
      (br_if $done (i64.eqz (local.get $n)))
      (if (i64.ne (i64.and (local.get $n) (i64.const 1)) (i64.const 0)) (then
        (local.set $result (f64.mul (local.get $result) (local.get $base)))
      ))
      (local.set $base (f64.mul (local.get $base) (local.get $base)))
      (local.set $n (i64.shr_u (local.get $n) (i64.const 1)))
      (br $loop)
    ))
    (if (result f64) (local.get $neg)
      (then (f64.div (f64.const 1) (local.get $result)))
      (else (local.get $result)))
  )

  ;; x^y. The general (x > 0) case is exp(y * log(x)); the many special cases of
  ;; C99 pow are handled explicitly. A negative base with a non-integer exponent
  ;; is a domain error (NaN, errno EDOM); a zero base with a negative exponent is
  ;; a pole error (+/-inf, errno ERANGE). Note this follows C99 (e.g. pow(+/-1,
  ;; +/-inf) == 1), which differs from JavaScript's Math.pow at those points.
  (func $pow (param $x f64) (param $y f64) (result f64)
    (local $ax f64)     ;; |x|
    (local $yint i32)   ;; y is an integer
    (local $yodd i32)   ;; y is an odd integer
    (local $negzero i32);; x is -0
    (local $r f64)
    ;; pow(x, 0) == 1 for every x (even NaN); pow(1, y) == 1 for every y
    (if (f64.eq (local.get $y) (f64.const 0)) (then (return (f64.const 1))))
    (if (f64.eq (local.get $x) (f64.const 1)) (then (return (f64.const 1))))
    ;; any remaining NaN operand yields NaN
    (if (i32.or (f64.ne (local.get $x) (local.get $x)) (f64.ne (local.get $y) (local.get $y)))
      (then (return (f64.const nan))))

    (local.set $ax (f64.abs (local.get $x)))
    (local.set $yint (f64.eq (f64.floor (local.get $y)) (local.get $y)))
    (local.set $yodd (i32.and (local.get $yint)
      (f64.eq (call $fmod (f64.abs (local.get $y)) (f64.const 2)) (f64.const 1))))

    ;; y == +/- infinity
    (if (f64.eq (local.get $y) (f64.const inf)) (then
      (if (f64.lt (local.get $ax) (f64.const 1)) (then (return (f64.const 0))))
      (if (f64.gt (local.get $ax) (f64.const 1)) (then (return (f64.const inf))))
      (return (f64.const 1)) ;; |x| == 1 (i.e. x == -1): C99 pow(-1, inf) == 1
    ))
    (if (f64.eq (local.get $y) (f64.const -inf)) (then
      (if (f64.lt (local.get $ax) (f64.const 1)) (then (return (f64.const inf))))
      (if (f64.gt (local.get $ax) (f64.const 1)) (then (return (f64.const 0))))
      (return (f64.const 1))
    ))

    ;; x == +/- infinity
    (if (f64.eq (local.get $x) (f64.const inf)) (then
      (return (if (result f64) (f64.gt (local.get $y) (f64.const 0)) (then (f64.const inf)) (else (f64.const 0))))
    ))
    (if (f64.eq (local.get $x) (f64.const -inf)) (then
      ;; equivalent to pow(-0, -y)
      (if (f64.gt (local.get $y) (f64.const 0)) (then
        (return (if (result f64) (local.get $yodd) (then (f64.const -inf)) (else (f64.const inf))))
      ))
      (return (if (result f64) (local.get $yodd) (then (f64.const -0)) (else (f64.const 0))))
    ))

    ;; x == 0 (+0 or -0)
    (if (f64.eq (local.get $x) (f64.const 0)) (then
      (local.set $negzero (i64.lt_s (i64.reinterpret_f64 (local.get $x)) (i64.const 0)))
      (if (f64.gt (local.get $y) (f64.const 0)) (then
        (return (if (result f64) (i32.and (local.get $negzero) (local.get $yodd))
          (then (f64.const -0)) (else (f64.const 0))))
      ))
      ;; y < 0: pole error
      (global.set $errno (global.get $ERANGE))
      (return (if (result f64) (i32.and (local.get $negzero) (local.get $yodd))
        (then (f64.const -inf)) (else (f64.const inf))))
    ))

    ;; integer exponent within a safe range: near-exact via binary exponentiation
    ;; (this also yields the correct sign for a negative base)
    (if (i32.and (local.get $yint) (f64.lt (f64.abs (local.get $y)) (f64.const 0x1p31))) (then
      (return (call $powi (local.get $x) (i64.trunc_f64_s (local.get $y))))
    ))

    ;; x < 0 finite, with a non-integer (or out-of-range integer) exponent
    (if (f64.lt (local.get $x) (f64.const 0)) (then
      (if (i32.eqz (local.get $yint)) (then ;; non-integer power of a negative base
        (global.set $errno (global.get $EDOM))
        (return (f64.const nan))
      ))
      (local.set $r (call $exp (f64.mul (local.get $y) (call $log (local.get $ax)))))
      (return (if (result f64) (local.get $yodd) (then (f64.neg (local.get $r))) (else (local.get $r))))
    ))

    ;; general case: x > 0
    (call $exp (f64.mul (local.get $y) (call $log (local.get $x))))
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

  ;; Floating-point remainder of x/y: x - n*y for the integer n = trunc(x/y),
  ;; computed exactly by repeated halving-free doubling and subtraction (each
  ;; subtraction is exact by Sterbenz's lemma). Returns NaN when y is 0 or x is
  ;; non-finite; returns x when |x| < |y| (including when y is infinite).
  (func $fmod (param $x f64) (param $y f64) (result f64)
    (local $ax f64)
    (local $ay f64)
    (local $d f64)
    ;; NaN / inf x / y == 0 all yield NaN
    (if (i32.or
          (i32.or (f64.ne (local.get $x) (local.get $x)) (f64.ne (local.get $y) (local.get $y)))
          (i32.or (f64.eq (f64.abs (local.get $x)) (f64.const inf)) (f64.eq (local.get $y) (f64.const 0)))
        ) (then
      (return (f64.const nan))
    ))
    (local.set $ax (f64.abs (local.get $x)))
    (local.set $ay (f64.abs (local.get $y)))
    (if (f64.lt (local.get $ax) (local.get $ay)) (then (return (local.get $x))))
    (block $done (loop $loop
      (br_if $done (f64.lt (local.get $ax) (local.get $ay)))
      ;; largest d = ay * 2^k with d <= ax
      (local.set $d (local.get $ay))
      (block $inner_done (loop $inner
        (br_if $inner_done (f64.gt (f64.add (local.get $d) (local.get $d)) (local.get $ax)))
        (local.set $d (f64.add (local.get $d) (local.get $d)))
        (br $inner)
      ))
      (local.set $ax (f64.sub (local.get $ax) (local.get $d)))
      (br $loop)
    ))
    (f64.copysign (local.get $ax) (local.get $x))
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

  ;; Swap two regions of `size` bytes at addresses a and b (internal helper).
  (func $memswap (param $a i32) (param $b i32) (param $size i32)
    (local $t i32)
    (block $done (loop $loop
      (br_if $done (i32.eqz (local.get $size)))
      (local.set $t (i32.load8_u (local.get $a)))
      (i32.store8 (local.get $a) (i32.load8_u (local.get $b)))
      (i32.store8 (local.get $b) (local.get $t))
      (local.set $a (i32.add (local.get $a) (i32.const 1)))
      (local.set $b (i32.add (local.get $b) (i32.const 1)))
      (local.set $size (i32.sub (local.get $size) (i32.const 1)))
      (br $loop)
    ))
  )

  ;; void *bsearch(const void *key, const void *base, size_t nmemb, size_t size,
  ;;               int (*compar)(const void *, const void *))
  ;; Binary search over a sorted array. `compar` is an index into the exported
  ;; function table (see $indirect). Returns a pointer to a matching element or
  ;; NULL. compar is called as compar(key, element).
  (func $bsearch (param $key i32) (param $base i32) (param $nmemb i32) (param $size i32) (param $compar i32) (result i32)
    (local $lo i32)
    (local $hi i32)
    (local $mid i32)
    (local $p i32)
    (local $c i32)
    (local.set $hi (local.get $nmemb))
    (block $done (loop $loop
      (br_if $done (i32.ge_u (local.get $lo) (local.get $hi)))
      (local.set $mid (i32.div_u (i32.add (local.get $lo) (local.get $hi)) (i32.const 2)))
      (local.set $p (i32.add (local.get $base) (i32.mul (local.get $mid) (local.get $size))))
      (local.set $c (call_indirect (type $compar_t) (local.get $key) (local.get $p) (local.get $compar)))
      (if (i32.lt_s (local.get $c) (i32.const 0)) (then
        (local.set $hi (local.get $mid))
      ) (else (if (i32.gt_s (local.get $c) (i32.const 0)) (then
        (local.set $lo (i32.add (local.get $mid) (i32.const 1)))
      ) (else
        (return (local.get $p))
      ))))
      (br $loop)
    ))
    (i32.const 0)
  )

  ;; void qsort(void *base, size_t nmemb, size_t size,
  ;;            int (*compar)(const void *, const void *))
  ;; Sorts the array in place using `compar` (an index into the exported
  ;; function table). This is a simple O(n^2) selection sort, chosen for clarity
  ;; over speed; the C standard does not require any particular algorithm or
  ;; stability.
  (func $qsort (param $base i32) (param $nmemb i32) (param $size i32) (param $compar i32)
    (local $i i32)
    (local $j i32)
    (local $pi i32)
    (local $pj i32)
    (block $outer_done (loop $outer
      (br_if $outer_done (i32.ge_u (i32.add (local.get $i) (i32.const 1)) (local.get $nmemb)))
      (local.set $pi (i32.add (local.get $base) (i32.mul (local.get $i) (local.get $size))))
      (local.set $j (i32.add (local.get $i) (i32.const 1)))
      (block $inner_done (loop $inner
        (br_if $inner_done (i32.ge_u (local.get $j) (local.get $nmemb)))
        (local.set $pj (i32.add (local.get $base) (i32.mul (local.get $j) (local.get $size))))
        ;; if element j sorts before element i, swap them
        (if (i32.lt_s
              (call_indirect (type $compar_t) (local.get $pj) (local.get $pi) (local.get $compar))
              (i32.const 0)
            ) (then
          (call $memswap (local.get $pi) (local.get $pj) (local.get $size))
        ))
        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br $inner)
      ))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $outer)
    ))
  )

  ;; int rand(void)
  ;; The C standard's portable reference generator (a linear congruential
  ;; generator). Returns a value in [0, RAND_MAX] where RAND_MAX is 32767.
  (func $rand (result i32)
    (global.set $rand_seed
      (i64.add
        (i64.mul (global.get $rand_seed) (i64.const 1103515245))
        (i64.const 12345)
      )
    )
    ;; (unsigned)(seed / 65536) % 32768
    (i32.wrap_i64
      (i64.and (i64.shr_u (global.get $rand_seed) (i64.const 16)) (i64.const 0x7fff))
    )
  )

  ;; void srand(unsigned int seed)
  (func $srand (param $seed i32)
    (global.set $rand_seed (i64.extend_i32_u (local.get $seed)))
  )

  ;; double atof(const char *nptr)
  ;; Equivalent to strtod(nptr, NULL): the parsed value, discarding the endptr.
  (func $atof (param $nptr i32) (result f64)
    (local $end i32)
    ;; strtod leaves (value, endptr) on the stack; capture endptr, keep value
    (local.set $end (call $strtod (local.get $nptr)))
  )

  ;; int atoi(const char *nptr)
  ;; Skips leading whitespace, accepts an optional sign, and converts the
  ;; following decimal digits. Parsing stops at the first non-digit. As in C,
  ;; overflow is undefined (here it simply wraps mod 2^32).
  (func $atoi (param $nptr i32) (result i32)
    (local $result i32)
    (local $sign i32)
    (local $c i32)
    (local.set $sign (i32.const 1))
    ;; skip leading whitespace
    (block $ws_done
      (loop $ws
        (br_if $ws_done (i32.eqz (call $isspace (i32.load8_u (local.get $nptr)))))
        (local.set $nptr (i32.add (local.get $nptr) (i32.const 1)))
        (br $ws)
      )
    )
    ;; optional sign
    (local.set $c (i32.load8_u (local.get $nptr)))
    (if (i32.eq (local.get $c) (i32.const 45)) (then ;; '-'
      (local.set $sign (i32.const -1))
      (local.set $nptr (i32.add (local.get $nptr) (i32.const 1)))
    ) (else (if (i32.eq (local.get $c) (i32.const 43)) (then ;; '+'
      (local.set $nptr (i32.add (local.get $nptr) (i32.const 1)))
    ))))
    ;; accumulate decimal digits
    (block $done
      (loop $digits
        (local.set $c (i32.load8_u (local.get $nptr)))
        (br_if $done (i32.eqz (call $isdigit (local.get $c))))
        (local.set $result (i32.add
          (i32.mul (local.get $result) (i32.const 10))
          (i32.sub (local.get $c) (i32.const 48))
        ))
        (local.set $nptr (i32.add (local.get $nptr) (i32.const 1)))
        (br $digits)
      )
    )
    (i32.mul (local.get $result) (local.get $sign))
  )

  ;; double strtod(const char *nptr, char **endptr)
  ;; Returns (value, endptr) in place of the char** out-param. Parses an optional
  ;; sign, an integer and/or fractional part, and an optional decimal exponent
  ;; (e/E). The mantissa is accumulated in f64 and scaled by a power of ten, so
  ;; the result is accurate to within a few ULP rather than correctly rounded.
  ;; Over/underflow yields +/-inf or 0 with $errno set to ERANGE. Hexadecimal
  ;; floats and inf/nan spellings are not recognized. When no digits are
  ;; converted the value is 0 and endptr equals nptr.
  (func $strtod (param $nptr i32) (result f64 i32)
    (local $s i32)          ;; scan cursor
    (local $c i32)          ;; current byte
    (local $neg i32)
    (local $any i32)        ;; saw at least one mantissa digit
    (local $value f64)      ;; mantissa
    (local $expo i32)       ;; decimal exponent (fraction digits + explicit exp)
    (local $p i32)          ;; lookahead cursor for the exponent field
    (local $expNeg i32)
    (local $expVal i32)
    (local $expDigits i32)
    (local $scale f64)
    (local $nonzero i32)    ;; mantissa was nonzero (to detect underflow)
    (local.set $s (local.get $nptr))
    (local.set $value (f64.const 0))

    ;; leading whitespace
    (block $ws_done (loop $ws
      (br_if $ws_done (i32.eqz (call $isspace (i32.load8_u (local.get $s)))))
      (local.set $s (i32.add (local.get $s) (i32.const 1)))
      (br $ws)
    ))

    ;; optional sign
    (local.set $c (i32.load8_u (local.get $s)))
    (if (i32.eq (local.get $c) (i32.const 45)) (then ;; '-'
      (local.set $neg (i32.const 1))
      (local.set $s (i32.add (local.get $s) (i32.const 1)))
    ) (else (if (i32.eq (local.get $c) (i32.const 43)) (then ;; '+'
      (local.set $s (i32.add (local.get $s) (i32.const 1)))
    ))))

    ;; integer-part digits
    (block $int_done (loop $int
      (local.set $c (i32.load8_u (local.get $s)))
      (br_if $int_done (i32.eqz (call $isdigit (local.get $c))))
      (local.set $value (f64.add (f64.mul (local.get $value) (f64.const 10))
        (f64.convert_i32_u (i32.sub (local.get $c) (i32.const 48)))))
      (local.set $any (i32.const 1))
      (local.set $s (i32.add (local.get $s) (i32.const 1)))
      (br $int)
    ))

    ;; optional fractional part
    (if (i32.eq (i32.load8_u (local.get $s)) (i32.const 46)) (then ;; '.'
      (local.set $s (i32.add (local.get $s) (i32.const 1)))
      (block $frac_done (loop $frac
        (local.set $c (i32.load8_u (local.get $s)))
        (br_if $frac_done (i32.eqz (call $isdigit (local.get $c))))
        (local.set $value (f64.add (f64.mul (local.get $value) (f64.const 10))
          (f64.convert_i32_u (i32.sub (local.get $c) (i32.const 48)))))
        (local.set $expo (i32.sub (local.get $expo) (i32.const 1)))
        (local.set $any (i32.const 1))
        (local.set $s (i32.add (local.get $s) (i32.const 1)))
        (br $frac)
      ))
    ))

    ;; no mantissa digits at all: no conversion
    (if (i32.eqz (local.get $any)) (then
      (return (f64.const 0) (local.get $nptr))
    ))

    ;; optional exponent: only consumed if e/E is followed by (sign and) a digit
    (local.set $c (i32.load8_u (local.get $s)))
    (if (i32.or (i32.eq (local.get $c) (i32.const 101)) (i32.eq (local.get $c) (i32.const 69))) (then ;; 'e'/'E'
      (local.set $p (i32.add (local.get $s) (i32.const 1)))
      (local.set $c (i32.load8_u (local.get $p)))
      (if (i32.eq (local.get $c) (i32.const 45)) (then ;; '-'
        (local.set $expNeg (i32.const 1))
        (local.set $p (i32.add (local.get $p) (i32.const 1)))
      ) (else (if (i32.eq (local.get $c) (i32.const 43)) (then ;; '+'
        (local.set $p (i32.add (local.get $p) (i32.const 1)))
      ))))
      (block $exp_done (loop $exp
        (local.set $c (i32.load8_u (local.get $p)))
        (br_if $exp_done (i32.eqz (call $isdigit (local.get $c))))
        (local.set $expVal (i32.add (i32.mul (local.get $expVal) (i32.const 10))
          (i32.sub (local.get $c) (i32.const 48))))
        (local.set $expDigits (i32.const 1))
        (local.set $p (i32.add (local.get $p) (i32.const 1)))
        (br $exp)
      ))
      (if (local.get $expDigits) (then ;; commit the exponent field
        (if (local.get $expNeg) (then (local.set $expVal (i32.sub (i32.const 0) (local.get $expVal)))))
        (local.set $expo (i32.add (local.get $expo) (local.get $expVal)))
        (local.set $s (local.get $p))
      ))
    ))

    ;; scale the mantissa by 10^expo (computed by repeated multiplication)
    (local.set $nonzero (f64.ne (local.get $value) (f64.const 0)))
    (local.set $scale (f64.const 1))
    (local.set $expVal (if (result i32) (i32.lt_s (local.get $expo) (i32.const 0))
      (then (i32.sub (i32.const 0) (local.get $expo)))
      (else (local.get $expo))))
    (block $pow_done (loop $pow
      (br_if $pow_done (i32.eqz (local.get $expVal)))
      (local.set $scale (f64.mul (local.get $scale) (f64.const 10)))
      (local.set $expVal (i32.sub (local.get $expVal) (i32.const 1)))
      (br $pow)
    ))
    (local.set $value (if (result f64) (i32.lt_s (local.get $expo) (i32.const 0))
      (then (f64.div (local.get $value) (local.get $scale)))
      (else (f64.mul (local.get $value) (local.get $scale)))))

    ;; ERANGE on overflow (result became infinite) or underflow (a nonzero
    ;; mantissa scaled all the way to zero)
    (if (i32.or
          (f64.eq (f64.abs (local.get $value)) (f64.const inf))
          (i32.and (local.get $nonzero) (f64.eq (local.get $value) (f64.const 0)))
        ) (then
      (global.set $errno (global.get $ERANGE))
    ))

    (if (local.get $neg) (then (local.set $value (f64.neg (local.get $value)))))
    (local.get $value)
    (local.get $s)
  )

  ;; long strtol(const char *nptr, char **endptr, int base)
  ;; Returns (value, endptr) in place of the char** out-param. Skips leading
  ;; whitespace, accepts an optional sign and (for base 0 or 16) a "0x" prefix.
  ;; base 0 auto-detects: "0x" -> 16, leading "0" -> 8, otherwise 10. On overflow
  ;; the result is clamped to LONG_MAX / LONG_MIN and $errno is set to ERANGE.
  ;; When no digits are converted the value is 0 and endptr equals nptr.
  ;; (Classic BSD algorithm, with C `long` represented as i64.)
  (func $strtol (param $nptr i32) (param $base i32) (result i64 i32)
    (local $s i32)       ;; scan cursor
    (local $c i32)       ;; current byte
    (local $d i32)       ;; current digit value
    (local $neg i32)
    (local $any i32)     ;; 0 = nothing yet, 1 = converted, -1 = overflowed
    (local $acc i64)     ;; unsigned accumulator
    (local $cutoff i64)
    (local $cutlim i64)
    (local $baseI64 i64)
    (local.set $s (local.get $nptr))

    ;; skip leading whitespace
    (block $ws_done (loop $ws
      (br_if $ws_done (i32.eqz (call $isspace (i32.load8_u (local.get $s)))))
      (local.set $s (i32.add (local.get $s) (i32.const 1)))
      (br $ws)
    ))

    ;; optional sign
    (local.set $c (i32.load8_u (local.get $s)))
    (if (i32.eq (local.get $c) (i32.const 45)) (then ;; '-'
      (local.set $neg (i32.const 1))
      (local.set $s (i32.add (local.get $s) (i32.const 1)))
    ) (else (if (i32.eq (local.get $c) (i32.const 43)) (then ;; '+'
      (local.set $s (i32.add (local.get $s) (i32.const 1)))
    ))))

    ;; optional "0x"/"0X" prefix when base is 0 or 16
    (if (i32.and
          (i32.or (i32.eqz (local.get $base)) (i32.eq (local.get $base) (i32.const 16)))
          (i32.and
            (i32.eq (i32.load8_u (local.get $s)) (i32.const 48)) ;; '0'
            (i32.or
              (i32.eq (i32.load8_u (i32.add (local.get $s) (i32.const 1))) (i32.const 120))  ;; 'x'
              (i32.eq (i32.load8_u (i32.add (local.get $s) (i32.const 1))) (i32.const 88))    ;; 'X'
            )
          )
        ) (then
      (local.set $s (i32.add (local.get $s) (i32.const 2)))
      (local.set $base (i32.const 16))
    ))

    ;; base 0 auto-detection
    (if (i32.eqz (local.get $base)) (then
      (local.set $base (if (result i32) (i32.eq (i32.load8_u (local.get $s)) (i32.const 48))
        (then (i32.const 8)) (else (i32.const 10))))
    ))

    ;; cutoff/cutlim: the largest acc (and final digit) that cannot overflow.
    ;; For a negative result the magnitude limit is (unsigned)LONG_MAX + 1 = 2^63.
    (local.set $baseI64 (i64.extend_i32_u (local.get $base)))
    (local.set $cutoff (if (result i64) (local.get $neg)
      (then (i64.const 0x8000000000000000))
      (else (i64.const 0x7fffffffffffffff))))
    (local.set $cutlim (i64.rem_u (local.get $cutoff) (local.get $baseI64)))
    (local.set $cutoff (i64.div_u (local.get $cutoff) (local.get $baseI64)))

    ;; convert digits
    (local.set $acc (i64.const 0))
    (local.set $any (i32.const 0))
    (block $loop_done (loop $loop
      (local.set $c (i32.load8_u (local.get $s)))
      (if (call $isdigit (local.get $c)) (then
        (local.set $d (i32.sub (local.get $c) (i32.const 48)))
      ) (else (if (call $isalpha (local.get $c)) (then
        ;; 'A'..'Z' -> 10.., 'a'..'z' -> 10..  ('A'-10 = 55, 'a'-10 = 87)
        (local.set $d (i32.sub (local.get $c)
          (if (result i32) (call $isupper (local.get $c)) (then (i32.const 55)) (else (i32.const 87)))))
      ) (else
        (br $loop_done)
      ))))
      (br_if $loop_done (i32.ge_s (local.get $d) (local.get $base))) ;; digit not valid for base
      (if (i32.or
            (i32.lt_s (local.get $any) (i32.const 0))
            (i32.or
              (i64.gt_u (local.get $acc) (local.get $cutoff))
              (i32.and
                (i64.eq (local.get $acc) (local.get $cutoff))
                (i64.gt_u (i64.extend_i32_u (local.get $d)) (local.get $cutlim))
              )
            )
          ) (then
        (local.set $any (i32.const -1))
      ) (else
        (local.set $any (i32.const 1))
        (local.set $acc (i64.add
          (i64.mul (local.get $acc) (local.get $baseI64))
          (i64.extend_i32_u (local.get $d))))
      ))
      (local.set $s (i32.add (local.get $s) (i32.const 1)))
      (br $loop)
    ))

    ;; finalize: clamp on overflow, otherwise apply the sign
    (if (i32.lt_s (local.get $any) (i32.const 0)) (then
      (local.set $acc (if (result i64) (local.get $neg)
        (then (i64.const 0x8000000000000000))   ;; LONG_MIN
        (else (i64.const 0x7fffffffffffffff))))  ;; LONG_MAX
      (global.set $errno (global.get $ERANGE))
    ) (else (if (local.get $neg) (then
      (local.set $acc (i64.sub (i64.const 0) (local.get $acc)))
    ))))

    ;; (value, endptr): endptr is the stop position if anything was consumed,
    ;; otherwise the original nptr.
    (local.get $acc)
    (if (result i32) (local.get $any) (then (local.get $s)) (else (local.get $nptr)))
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
  ;; Transforms src for locale-aware comparison and stores up to n bytes
  ;; (including the NUL) in dst, returning strlen(src). In the ASCII "C" locale
  ;; this library targets the transform is the identity, so this is a length-
  ;; returning copy. Per the C spec, when the return value is >= n the contents
  ;; of dst are indeterminate; here we still copy n bytes in that case.
  (func $strxfrm (param $dst i32) (param $src i32) (param $n i32) (result i32)
    (local $len i32)
    (local.set $len (call $strlen (local.get $src)))
    (if (i32.gt_u (local.get $n) (local.get $len)) (then
      ;; room for the whole string plus its terminating NUL
      (drop (call $memcpy (local.get $dst) (local.get $src) (i32.add (local.get $len) (i32.const 1))))
    ) (else (if (local.get $n) (then
      ;; not enough room: copy n bytes (no guaranteed NUL, per the spec)
      (drop (call $memcpy (local.get $dst) (local.get $src) (local.get $n)))
    ))))
    (local.get $len)
  )

  ;; char *strchr(const char *s, int c)
  ;; Returns a pointer to the first occurrence of c (as an unsigned char) in s,
  ;; or NULL if absent. A search for '\0' matches the terminating NUL.
  (func $strchr (param $s i32) (param $c i32) (result i32)
    (local $ch i32)
    (local.set $c (i32.and (local.get $c) (i32.const 0xff)))
    (loop $loop
      (local.set $ch (i32.load8_u (local.get $s)))
      ;; match first, so a search for '\0' returns the terminating NUL
      (if (i32.eq (local.get $ch) (local.get $c)) (then (return (local.get $s))))
      (if (i32.eqz (local.get $ch)) (then (return (i32.const 0)))) ;; end of s, not found
      (local.set $s (i32.add (local.get $s) (i32.const 1)))
      (br $loop)
    )
    (unreachable)
  )

  ;; size_t strcspn(const char *s, const char *reject)
  ;; Length of the initial run of s containing no bytes from reject.
  (func $strcspn (param $s i32) (param $reject i32) (result i32)
    (local $cursor i32)
    (local $c i32)
    (local.set $cursor (local.get $s))
    (block $done
      (loop $loop
        (local.set $c (i32.load8_u (local.get $cursor)))
        (br_if $done (i32.eqz (local.get $c)))                            ;; end of s
        (br_if $done (call $strchr (local.get $reject) (local.get $c)))   ;; c is in reject
        (local.set $cursor (i32.add (local.get $cursor) (i32.const 1)))
        (br $loop)
      )
    )
    (i32.sub (local.get $cursor) (local.get $s))
  )

  ;; char *strpbrk(const char *s, const char *accept)
  ;; Returns a pointer to the first byte of s that is in accept, or NULL.
  (func $strpbrk (param $s i32) (param $accept i32) (result i32)
    (local $c i32)
    (block $done
      (loop $loop
        (local.set $c (i32.load8_u (local.get $s)))
        (br_if $done (i32.eqz (local.get $c)))                       ;; end of s, no match
        (if (call $strchr (local.get $accept) (local.get $c)) (then
          (return (local.get $s))
        ))
        (local.set $s (i32.add (local.get $s) (i32.const 1)))
        (br $loop)
      )
    )
    (i32.const 0)
  )

  ;; char *strrchr(const char *s, int c)
  ;; Returns a pointer to the last occurrence of c (as an unsigned char) in s,
  ;; or NULL. A search for '\0' matches the terminating NUL.
  (func $strrchr (param $s i32) (param $c i32) (result i32)
    (local $ch i32)
    (local $last i32)
    (local.set $c (i32.and (local.get $c) (i32.const 0xff)))
    (local.set $last (i32.const 0))
    (loop $loop
      (local.set $ch (i32.load8_u (local.get $s)))
      (if (i32.eq (local.get $ch) (local.get $c)) (then (local.set $last (local.get $s))))
      (if (local.get $ch) (then ;; not yet at the NUL: keep scanning
        (local.set $s (i32.add (local.get $s) (i32.const 1)))
        (br $loop)
      ))
    )
    (local.get $last)
  )

  ;; size_t strspn(const char *s, const char *accept)
  ;; Length of the initial run of s consisting entirely of bytes from accept.
  (func $strspn (param $s i32) (param $accept i32) (result i32)
    (local $cursor i32)
    (local $c i32)
    (local.set $cursor (local.get $s))
    (block $done
      (loop $loop
        (local.set $c (i32.load8_u (local.get $cursor)))
        (br_if $done (i32.eqz (local.get $c)))                             ;; end of s
        (br_if $done (i32.eqz (call $strchr (local.get $accept) (local.get $c)))) ;; c not in accept
        (local.set $cursor (i32.add (local.get $cursor) (i32.const 1)))
        (br $loop)
      )
    )
    (i32.sub (local.get $cursor) (local.get $s))
  )

  ;; char *strstr(const char *haystack, const char *needle)
  ;; Returns a pointer to the first occurrence of needle in haystack, or NULL.
  ;; An empty needle matches at the start of haystack. (Naive O(n*m) scan.)
  (func $strstr (param $haystack i32) (param $needle i32) (result i32)
    (local $h i32)
    (local $n i32)
    (local $hc i32)
    (local $nc i32)
    (if (i32.eqz (i32.load8_u (local.get $needle))) (then (return (local.get $haystack))))
    (block $notfound
      (loop $outer
        (br_if $notfound (i32.eqz (i32.load8_u (local.get $haystack)))) ;; haystack exhausted
        (local.set $h (local.get $haystack))
        (local.set $n (local.get $needle))
        (block $mismatch
          (loop $inner
            (local.set $nc (i32.load8_u (local.get $n)))
            (if (i32.eqz (local.get $nc)) (then (return (local.get $haystack)))) ;; full match
            (local.set $hc (i32.load8_u (local.get $h)))
            ;; differs (also catches haystack end, since hc==0 != nc)
            (br_if $mismatch (i32.ne (local.get $hc) (local.get $nc)))
            (local.set $h (i32.add (local.get $h) (i32.const 1)))
            (local.set $n (i32.add (local.get $n) (i32.const 1)))
            (br $inner)
          )
        )
        (local.set $haystack (i32.add (local.get $haystack) (i32.const 1)))
        (br $outer)
      )
    )
    (i32.const 0)
  )

  ;; char *strtok(char *str, const char *delim)
  ;; Splits a string into tokens delimited by any byte in delim. The first call
  ;; passes the string; subsequent calls pass NULL to continue from the saved
  ;; position (see $strtok_save). Writes a NUL over the delimiter ending each
  ;; token and returns the token, or NULL when none remain.
  (func $strtok (param $str i32) (param $delim i32) (result i32)
    (local $token i32)
    ;; NULL str resumes from where the previous call left off
    (if (i32.eqz (local.get $str)) (then
      (local.set $str (global.get $strtok_save))
    ))
    ;; skip any leading delimiters
    (local.set $str (i32.add (local.get $str) (call $strspn (local.get $str) (local.get $delim))))
    ;; nothing left but the terminating NUL: no more tokens
    (if (i32.eqz (i32.load8_u (local.get $str))) (then
      (global.set $strtok_save (local.get $str))
      (return (i32.const 0))
    ))
    (local.set $token (local.get $str))
    ;; advance to the first delimiter (or the terminating NUL)
    (local.set $str (i32.add (local.get $str) (call $strcspn (local.get $str) (local.get $delim))))
    (if (i32.load8_u (local.get $str)) (then
      ;; terminate this token and remember the byte after it
      (i32.store8 (local.get $str) (i32.const 0))
      (global.set $strtok_save (i32.add (local.get $str) (i32.const 1)))
    ) (else
      ;; token runs to the end of the string
      (global.set $strtok_save (local.get $str))
    ))
    (local.get $token)
  )

  ;; strerror message table.
  ;; These NUL-terminated strings live in a small reserved region of linear
  ;; memory (bytes 16..255); a host must not overwrite that region if it relies
  ;; on strerror. The offsets below are referenced directly by $strerror.
  (data (i32.const 16)  "Success\00")                          ;; errnum 0
  (data (i32.const 48)  "Numerical argument out of domain\00") ;; EDOM (1)
  (data (i32.const 96)  "Numerical result out of range\00")    ;; ERANGE (2)
  (data (i32.const 144) "Unknown error\00")                    ;; fallback

  ;; char *strerror(int errnum)
  ;; Returns a pointer to a static message for errnum. This library only defines
  ;; EDOM and ERANGE; any other non-zero value maps to "Unknown error".
  (func $strerror (param $errnum i32) (result i32)
    (if (i32.eqz (local.get $errnum)) (then (return (i32.const 16))))
    (if (i32.eq (local.get $errnum) (global.get $EDOM)) (then (return (i32.const 48))))
    (if (i32.eq (local.get $errnum) (global.get $ERANGE)) (then (return (i32.const 96))))
    (i32.const 144)
  )

  ;; Exports
  ;; The linear memory and every implemented function are exported so the
  ;; library can be consumed from a host runtime (and exercised by tests).
  (export "memory" (memory 0))

  ;; Function table for caller-supplied comparators (bsearch/qsort). A host
  ;; installs a comparator here and passes its slot index.
  (export "__indirect_function_table" (table $indirect))

  ;; errno and its values, so a host can observe error reporting (e.g. ERANGE
  ;; from strtol overflow). errno is mutable; EDOM/ERANGE are constants.
  (export "errno" (global $errno))
  (export "EDOM" (global $EDOM))
  (export "ERANGE" (global $ERANGE))

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
  (export "toascii" (func $toascii))

  ;; math.h
  (export "sqrt" (func $sqrt))
  (export "ceil" (func $ceil))
  (export "fabs" (func $fabs))
  (export "floor" (func $floor))
  (export "fmod" (func $fmod))
  (export "frexp" (func $frexp))
  (export "ldexp" (func $ldexp))
  (export "modf" (func $modf))
  (export "exp" (func $exp))
  (export "log" (func $log))
  (export "log10" (func $log10))
  (export "pow" (func $pow))
  (export "sin" (func $sin))
  (export "cos" (func $cos))
  (export "tan" (func $tan))
  (export "atan" (func $atan))
  (export "atan2" (func $atan2))
  (export "asin" (func $asin))
  (export "acos" (func $acos))

  ;; stdlib.h
  (export "itoa_s" (func $itoa_s))
  (export "abs" (func $abs))
  (export "labs" (func $labs))
  (export "div" (func $div))
  (export "ldiv" (func $ldiv))
  (export "atoi" (func $atoi))
  (export "rand" (func $rand))
  (export "srand" (func $srand))
  (export "strtol" (func $strtol))
  (export "strtod" (func $strtod))
  (export "atof" (func $atof))
  (export "bsearch" (func $bsearch))
  (export "qsort" (func $qsort))

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
  (export "strchr" (func $strchr))
  (export "strrchr" (func $strrchr))
  (export "strspn" (func $strspn))
  (export "strcspn" (func $strcspn))
  (export "strpbrk" (func $strpbrk))
  (export "strstr" (func $strstr))
  (export "strxfrm" (func $strxfrm))
  (export "strtok" (func $strtok))
  (export "strerror" (func $strerror))
)