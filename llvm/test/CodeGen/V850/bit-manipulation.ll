; RUN: llc -mtriple=v850 -O2 < %s | FileCheck %s

; Test SET1/CLR1/NOT1 bit manipulation pattern matching
; These patterns combine load-modify-store sequences into single atomic RMW instructions

;============================================================================
; SET1 - Set bit in memory
;============================================================================

; CHECK-LABEL: set_bit0:
; CHECK:       set1 0, 0[r6]
; CHECK-NEXT:  jmp [r31]
define void @set_bit0(ptr %p) {
entry:
  %val = load i8, ptr %p
  %or = or i8 %val, 1
  store i8 %or, ptr %p
  ret void
}

; CHECK-LABEL: set_bit2:
; CHECK:       set1 2, 0[r6]
; CHECK-NEXT:  jmp [r31]
define void @set_bit2(ptr %p) {
entry:
  %val = load i8, ptr %p
  %or = or i8 %val, 4
  store i8 %or, ptr %p
  ret void
}

; CHECK-LABEL: set_bit7:
; CHECK:       set1 7, 0[r6]
; CHECK-NEXT:  jmp [r31]
define void @set_bit7(ptr %p) {
entry:
  %val = load i8, ptr %p
  %or = or i8 %val, 128
  store i8 %or, ptr %p
  ret void
}

;============================================================================
; CLR1 - Clear bit in memory
;============================================================================

; CHECK-LABEL: clear_bit0:
; CHECK:       clr1 0, 0[r6]
; CHECK-NEXT:  jmp [r31]
define void @clear_bit0(ptr %p) {
entry:
  %val = load i8, ptr %p
  %and = and i8 %val, -2  ; ~1 = 0xFE
  store i8 %and, ptr %p
  ret void
}

; CHECK-LABEL: clear_bit3:
; CHECK:       clr1 3, 0[r6]
; CHECK-NEXT:  jmp [r31]
define void @clear_bit3(ptr %p) {
entry:
  %val = load i8, ptr %p
  %and = and i8 %val, -9  ; ~8 = 0xF7
  store i8 %and, ptr %p
  ret void
}

; CHECK-LABEL: clear_bit7:
; CHECK:       clr1 7, 0[r6]
; CHECK-NEXT:  jmp [r31]
define void @clear_bit7(ptr %p) {
entry:
  %val = load i8, ptr %p
  %and = and i8 %val, 127  ; ~128 = 0x7F
  store i8 %and, ptr %p
  ret void
}

;============================================================================
; NOT1 - Toggle bit in memory
;============================================================================

; CHECK-LABEL: toggle_bit0:
; CHECK:       not1 0, 0[r6]
; CHECK-NEXT:  jmp [r31]
define void @toggle_bit0(ptr %p) {
entry:
  %val = load i8, ptr %p
  %xor = xor i8 %val, 1
  store i8 %xor, ptr %p
  ret void
}

; CHECK-LABEL: toggle_bit4:
; CHECK:       not1 4, 0[r6]
; CHECK-NEXT:  jmp [r31]
define void @toggle_bit4(ptr %p) {
entry:
  %val = load i8, ptr %p
  %xor = xor i8 %val, 16
  store i8 %xor, ptr %p
  ret void
}

; CHECK-LABEL: toggle_bit7:
; CHECK:       not1 7, 0[r6]
; CHECK-NEXT:  jmp [r31]
define void @toggle_bit7(ptr %p) {
entry:
  %val = load i8, ptr %p
  %xor = xor i8 %val, 128
  store i8 %xor, ptr %p
  ret void
}

;============================================================================
; Negative tests - these should NOT use SET1/CLR1/NOT1
;============================================================================

; Multiple bits set - cannot use SET1
; CHECK-LABEL: set_multiple_bits:
; CHECK-NOT:   set1
; CHECK:       ld.b
; CHECK:       ori
; CHECK:       st.b
define void @set_multiple_bits(ptr %p) {
entry:
  %val = load i8, ptr %p
  %or = or i8 %val, 5  ; bits 0 and 2
  store i8 %or, ptr %p
  ret void
}

; Volatile load - should not combine
; CHECK-LABEL: volatile_load:
; CHECK-NOT:   set1
; CHECK:       ld.b
; CHECK:       ori
; CHECK:       st.b
define void @volatile_load(ptr %p) {
entry:
  %val = load volatile i8, ptr %p
  %or = or i8 %val, 4
  store i8 %or, ptr %p
  ret void
}

; Volatile store - should not combine
; CHECK-LABEL: volatile_store:
; CHECK-NOT:   set1
; CHECK:       ld.b
; CHECK:       ori
; CHECK:       st.b
define void @volatile_store(ptr %p) {
entry:
  %val = load i8, ptr %p
  %or = or i8 %val, 4
  store volatile i8 %or, ptr %p
  ret void
}
