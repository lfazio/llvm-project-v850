; RUN: llc -mtriple=v850 -mcpu=v850e1 < %s | FileCheck %s
; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s

;===----------------------------------------------------------------------===;
; Test constant materialization patterns
;
; V850 uses different instructions based on constant range:
; - MOV imm5, reg: 5-bit signed (-16 to 15)
; - MOVEA imm16, r0, reg: 16-bit signed (-32768 to 32767)
; - MOVHI imm16, r0, reg: high 16 bits only (when low bits are zero)
; - MOVHI + MOVEA: full 32-bit constants
;===----------------------------------------------------------------------===;

;===----------------------------------------------------------------------===;
; Test 1: 5-bit signed immediate range (-16 to 15)
; Should use MOV instruction
;===----------------------------------------------------------------------===;

; CHECK-LABEL: const_zero:
; CHECK:       mov 0, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_zero() {
  ret i32 0
}

; CHECK-LABEL: const_one:
; CHECK:       mov 1, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_one() {
  ret i32 1
}

; CHECK-LABEL: const_minus_one:
; CHECK:       mov -1, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_minus_one() {
  ret i32 -1
}

; CHECK-LABEL: const_15:
; CHECK:       mov 15, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_15() {
  ret i32 15
}

; CHECK-LABEL: const_minus_16:
; CHECK:       mov -16, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_minus_16() {
  ret i32 -16
}

;===----------------------------------------------------------------------===;
; Test 2: 16-bit signed immediate range (-32768 to 32767)
; Values outside 5-bit range should use MOVEA with r0
;===----------------------------------------------------------------------===;

; CHECK-LABEL: const_16:
; CHECK:       movea 16, r0, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_16() {
  ret i32 16
}

; CHECK-LABEL: const_256:
; CHECK:       movea 256, r0, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_256() {
  ret i32 256
}

; CHECK-LABEL: const_32767:
; CHECK:       movea 32767, r0, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_32767() {
  ret i32 32767
}

; CHECK-LABEL: const_minus_32768:
; CHECK:       movea -32768, r0, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_minus_32768() {
  ret i32 -32768
}

;===----------------------------------------------------------------------===;
; Test 3: Constants with zero low 16 bits (MOVHI optimization)
; Should use single MOVHI instruction instead of MOVHI+MOVEA
;===----------------------------------------------------------------------===;

; 0x00010000 = 65536
; CHECK-LABEL: const_65536:
; CHECK:       movhi 1, r0, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_65536() {
  ret i32 65536
}

; 0x00020000 = 131072
; CHECK-LABEL: const_131072:
; CHECK:       movhi 2, r0, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_131072() {
  ret i32 131072
}

; 0x12340000 = 305397760
; CHECK-LABEL: const_0x12340000:
; CHECK:       movhi 4660, r0, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_0x12340000() {
  ret i32 305397760
}

; 0xFFFF0000 = -65536 (high bits all ones)
; CHECK-LABEL: const_minus_65536:
; CHECK:       movhi 65535, r0, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_minus_65536() {
  ret i32 -65536
}

; 0x80000000 = -2147483648 (min int32)
; CHECK-LABEL: const_min_int32:
; CHECK:       movhi 32768, r0, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_min_int32() {
  ret i32 -2147483648
}

;===----------------------------------------------------------------------===;
; Test 4: Full 32-bit constants (MOVHI + MOVEA)
; Constants with non-zero low 16 bits need both instructions
;===----------------------------------------------------------------------===;

; 0x00008000 = 32768 (just outside simm16 range)
; Note: This requires MOVHI 1 + MOVEA -32768 due to sign extension
; CHECK-LABEL: const_32768:
; CHECK:       movhi 1, r0, r10
; CHECK-NEXT:  movea -32768, r10, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_32768() {
  ret i32 32768
}

; 0x12345678
; CHECK-LABEL: const_0x12345678:
; CHECK:       movhi 4660, r0, r10
; CHECK-NEXT:  movea 22136, r10, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_0x12345678() {
  ret i32 305419896
}

; 0xDEADBEEF
; CHECK-LABEL: const_0xDEADBEEF:
; CHECK:       movhi 57006, r0, r10
; CHECK-NEXT:  movea -16657, r10, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_0xDEADBEEF() {
  ret i32 -559038737
}

; 0x7FFFFFFF = max int32
; CHECK-LABEL: const_max_int32:
; CHECK:       movhi 32768, r0, r10
; CHECK-NEXT:  movea -1, r10, r10
; CHECK-NEXT:  jmp [r31]
define i32 @const_max_int32() {
  ret i32 2147483647
}

;===----------------------------------------------------------------------===;
; Test 5: Constants used in arithmetic operations
; Verify optimization applies in expression contexts
;===----------------------------------------------------------------------===;

; Add with optimized constant (zero low bits)
; CHECK-LABEL: add_with_const:
; CHECK:       movhi 1, r0, r{{[0-9]+}}
; CHECK:       add r{{[0-9]+}}, r{{[0-9]+}}
; CHECK:       jmp [r31]
define i32 @add_with_const(i32 %a) {
  %result = add i32 %a, 65536
  ret i32 %result
}

; And with optimized constant
; CHECK-LABEL: and_with_const:
; CHECK:       movhi 65535, r0, r{{[0-9]+}}
; CHECK:       and r{{[0-9]+}}, r{{[0-9]+}}
; CHECK:       jmp [r31]
define i32 @and_with_const(i32 %a) {
  %result = and i32 %a, -65536
  ret i32 %result
}
