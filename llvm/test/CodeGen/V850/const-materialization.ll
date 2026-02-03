; RUN: llc -mtriple=v850 -mcpu=v850e1 < %s | FileCheck %s --check-prefix=V850E1
; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s --check-prefix=V850E1
; RUN: llc -mtriple=v850 -mcpu=v850 < %s | FileCheck %s --check-prefix=V850

;===----------------------------------------------------------------------===;
; Test constant materialization patterns
;
; V850 uses different instructions based on constant range and CPU variant:
; - MOV imm5, reg: 5-bit signed (-16 to 15) [all variants]
; - MOVEA imm16, r0, reg: 16-bit signed (-32768 to 32767) [all variants]
; - MOVHI imm16, r0, reg: high 16 bits only (when low bits are zero) [all variants]
; - MOV imm32, reg: 32-bit immediate in one instruction [V850E1+ only]
; - MOVHI + MOVEA: full 32-bit constants [base V850 fallback]
;===----------------------------------------------------------------------===;

;===----------------------------------------------------------------------===;
; Test 1: 5-bit signed immediate range (-16 to 15)
; Should use MOV instruction (same on all variants)
;===----------------------------------------------------------------------===;

; V850E1-LABEL: const_zero:
; V850E1:       mov 0, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_zero:
; V850:       mov 0, r10
; V850-NEXT:  jmp [r31]
define i32 @const_zero() {
  ret i32 0
}

; V850E1-LABEL: const_one:
; V850E1:       mov 1, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_one:
; V850:       mov 1, r10
; V850-NEXT:  jmp [r31]
define i32 @const_one() {
  ret i32 1
}

; V850E1-LABEL: const_minus_one:
; V850E1:       mov -1, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_minus_one:
; V850:       mov -1, r10
; V850-NEXT:  jmp [r31]
define i32 @const_minus_one() {
  ret i32 -1
}

; V850E1-LABEL: const_15:
; V850E1:       mov 15, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_15:
; V850:       mov 15, r10
; V850-NEXT:  jmp [r31]
define i32 @const_15() {
  ret i32 15
}

; V850E1-LABEL: const_minus_16:
; V850E1:       mov -16, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_minus_16:
; V850:       mov -16, r10
; V850-NEXT:  jmp [r31]
define i32 @const_minus_16() {
  ret i32 -16
}

;===----------------------------------------------------------------------===;
; Test 2: 16-bit signed immediate range (-32768 to 32767)
; Values outside 5-bit range should use MOVEA with r0
;===----------------------------------------------------------------------===;

; V850E1-LABEL: const_16:
; V850E1:       movea 16, r0, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_16:
; V850:       movea 16, r0, r10
; V850-NEXT:  jmp [r31]
define i32 @const_16() {
  ret i32 16
}

; V850E1-LABEL: const_256:
; V850E1:       movea 256, r0, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_256:
; V850:       movea 256, r0, r10
; V850-NEXT:  jmp [r31]
define i32 @const_256() {
  ret i32 256
}

; V850E1-LABEL: const_32767:
; V850E1:       movea 32767, r0, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_32767:
; V850:       movea 32767, r0, r10
; V850-NEXT:  jmp [r31]
define i32 @const_32767() {
  ret i32 32767
}

; V850E1-LABEL: const_minus_32768:
; V850E1:       movea -32768, r0, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_minus_32768:
; V850:       movea -32768, r0, r10
; V850-NEXT:  jmp [r31]
define i32 @const_minus_32768() {
  ret i32 -32768
}

;===----------------------------------------------------------------------===;
; Test 3: Constants with zero low 16 bits (MOVHI optimization)
; Should use single MOVHI instruction instead of MOVHI+MOVEA
;===----------------------------------------------------------------------===;

; 0x00010000 = 65536
; V850E1-LABEL: const_65536:
; V850E1:       movhi 1, r0, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_65536:
; V850:       movhi 1, r0, r10
; V850-NEXT:  jmp [r31]
define i32 @const_65536() {
  ret i32 65536
}

; 0x00020000 = 131072
; V850E1-LABEL: const_131072:
; V850E1:       movhi 2, r0, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_131072:
; V850:       movhi 2, r0, r10
; V850-NEXT:  jmp [r31]
define i32 @const_131072() {
  ret i32 131072
}

; 0x12340000 = 305397760
; V850E1-LABEL: const_0x12340000:
; V850E1:       movhi 4660, r0, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_0x12340000:
; V850:       movhi 4660, r0, r10
; V850-NEXT:  jmp [r31]
define i32 @const_0x12340000() {
  ret i32 305397760
}

; 0xFFFF0000 = -65536 (high bits all ones)
; V850E1-LABEL: const_minus_65536:
; V850E1:       movhi 65535, r0, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_minus_65536:
; V850:       movhi 65535, r0, r10
; V850-NEXT:  jmp [r31]
define i32 @const_minus_65536() {
  ret i32 -65536
}

; 0x80000000 = -2147483648 (min int32)
; V850E1-LABEL: const_min_int32:
; V850E1:       movhi 32768, r0, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_min_int32:
; V850:       movhi 32768, r0, r10
; V850-NEXT:  jmp [r31]
define i32 @const_min_int32() {
  ret i32 -2147483648
}

;===----------------------------------------------------------------------===;
; Test 4: Full 32-bit constants
; E1+: Uses MOV imm32 (6 bytes, single instruction)
; Base: Uses MOVHI + MOVEA (8 bytes, two instructions)
;===----------------------------------------------------------------------===;

; 0x00008000 = 32768 (just outside simm16 range)
; V850E1-LABEL: const_32768:
; V850E1:       mov 32768, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_32768:
; V850:       movhi 1, r0, r10
; V850-NEXT:  movea -32768, r10, r10
; V850-NEXT:  jmp [r31]
define i32 @const_32768() {
  ret i32 32768
}

; 0x12345678
; V850E1-LABEL: const_0x12345678:
; V850E1:       mov 305419896, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_0x12345678:
; V850:       movhi 4660, r0, r10
; V850-NEXT:  movea 22136, r10, r10
; V850-NEXT:  jmp [r31]
define i32 @const_0x12345678() {
  ret i32 305419896
}

; 0xDEADBEEF
; V850E1-LABEL: const_0xDEADBEEF:
; V850E1:       mov -559038737, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_0xDEADBEEF:
; V850:       movhi 57006, r0, r10
; V850-NEXT:  movea -16657, r10, r10
; V850-NEXT:  jmp [r31]
define i32 @const_0xDEADBEEF() {
  ret i32 -559038737
}

; 0x7FFFFFFF = max int32
; V850E1-LABEL: const_max_int32:
; V850E1:       mov 2147483647, r10
; V850E1-NEXT:  jmp [r31]
; V850-LABEL: const_max_int32:
; V850:       movhi 32768, r0, r10
; V850-NEXT:  movea -1, r10, r10
; V850-NEXT:  jmp [r31]
define i32 @const_max_int32() {
  ret i32 2147483647
}

;===----------------------------------------------------------------------===;
; Test 5: Constants used in arithmetic operations
; Verify optimization applies in expression contexts
;===----------------------------------------------------------------------===;

; Add with optimized constant (zero low bits - uses MOVHI on all variants)
; V850E1-LABEL: add_with_const:
; V850E1:       movhi 1, r0, r{{[0-9]+}}
; V850E1:       add r{{[0-9]+}}, r{{[0-9]+}}
; V850E1:       jmp [r31]
; V850-LABEL: add_with_const:
; V850:       movhi 1, r0, r{{[0-9]+}}
; V850:       add r{{[0-9]+}}, r{{[0-9]+}}
; V850:       jmp [r31]
define i32 @add_with_const(i32 %a) {
  %result = add i32 %a, 65536
  ret i32 %result
}

; And with optimized constant (zero low bits - uses MOVHI on all variants)
; V850E1-LABEL: and_with_const:
; V850E1:       movhi 65535, r0, r{{[0-9]+}}
; V850E1:       and r{{[0-9]+}}, r{{[0-9]+}}
; V850E1:       jmp [r31]
; V850-LABEL: and_with_const:
; V850:       movhi 65535, r0, r{{[0-9]+}}
; V850:       and r{{[0-9]+}}, r{{[0-9]+}}
; V850:       jmp [r31]
define i32 @and_with_const(i32 %a) {
  %result = and i32 %a, -65536
  ret i32 %result
}
