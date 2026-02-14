; RUN: llc -mtriple=v850-unknown-elf -mcpu=g3m -O2 < %s | FileCheck %s --check-prefix=G3M
; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m -O2 < %s | FileCheck %s --check-prefix=E2M

; Test that atomic RMW operations use LDL.W/STC.W on G3M (LLSC expansion)
; and CAXI on V850E2M (CmpXchg expansion).

; --- atomic add ---

define i32 @atomic_add(ptr %ptr, i32 %val) {
; G3M-LABEL: atomic_add:
; G3M:       syncp
; G3M:       ldl.w [r6], r{{[0-9]+}}
; G3M:       add r7, r{{[0-9]+}}
; G3M:       stc.w r{{[0-9]+}}, [r6]
; G3M:       syncp
;
; E2M-LABEL: atomic_add:
; E2M:       caxi [r6], r{{[0-9]+}}, r{{[0-9]+}}
  %result = atomicrmw add ptr %ptr, i32 %val seq_cst
  ret i32 %result
}

; --- atomic sub ---

define i32 @atomic_sub(ptr %ptr, i32 %val) {
; G3M-LABEL: atomic_sub:
; G3M:       syncp
; G3M:       ldl.w [r6], r{{[0-9]+}}
; G3M:       sub r7, r{{[0-9]+}}
; G3M:       stc.w r{{[0-9]+}}, [r6]
; G3M:       syncp
;
; E2M-LABEL: atomic_sub:
; E2M:       caxi [r6], r{{[0-9]+}}, r{{[0-9]+}}
  %result = atomicrmw sub ptr %ptr, i32 %val seq_cst
  ret i32 %result
}

; --- atomic or ---

define i32 @atomic_or(ptr %ptr, i32 %val) {
; G3M-LABEL: atomic_or:
; G3M:       syncp
; G3M:       ldl.w [r6], r{{[0-9]+}}
; G3M:       or r7, r{{[0-9]+}}
; G3M:       stc.w r{{[0-9]+}}, [r6]
; G3M:       syncp
;
; E2M-LABEL: atomic_or:
; E2M:       caxi [r6], r{{[0-9]+}}, r{{[0-9]+}}
  %result = atomicrmw or ptr %ptr, i32 %val seq_cst
  ret i32 %result
}

; --- atomic and ---

define i32 @atomic_and(ptr %ptr, i32 %val) {
; G3M-LABEL: atomic_and:
; G3M:       syncp
; G3M:       ldl.w [r6], r{{[0-9]+}}
; G3M:       and r7, r{{[0-9]+}}
; G3M:       stc.w r{{[0-9]+}}, [r6]
; G3M:       syncp
;
; E2M-LABEL: atomic_and:
; E2M:       caxi [r6], r{{[0-9]+}}, r{{[0-9]+}}
  %result = atomicrmw and ptr %ptr, i32 %val seq_cst
  ret i32 %result
}

; --- atomic xor ---

define i32 @atomic_xor(ptr %ptr, i32 %val) {
; G3M-LABEL: atomic_xor:
; G3M:       syncp
; G3M:       ldl.w [r6], r{{[0-9]+}}
; G3M:       xor r7, r{{[0-9]+}}
; G3M:       stc.w r{{[0-9]+}}, [r6]
; G3M:       syncp
;
; E2M-LABEL: atomic_xor:
; E2M:       caxi [r6], r{{[0-9]+}}, r{{[0-9]+}}
  %result = atomicrmw xor ptr %ptr, i32 %val seq_cst
  ret i32 %result
}

; --- atomic xchg ---

define i32 @atomic_xchg(ptr %ptr, i32 %val) {
; G3M-LABEL: atomic_xchg:
; G3M:       syncp
; G3M:       ldl.w [r6], r{{[0-9]+}}
; G3M:       stc.w r{{[0-9]+}}, [r6]
; G3M:       syncp
;
; E2M-LABEL: atomic_xchg:
; E2M:       caxi [r6], r{{[0-9]+}}, r{{[0-9]+}}
  %result = atomicrmw xchg ptr %ptr, i32 %val seq_cst
  ret i32 %result
}

; --- Test memory ordering: relaxed atomicrmw should not have fences ---

define i32 @atomic_add_relaxed(ptr %ptr, i32 %val) {
; G3M-LABEL: atomic_add_relaxed:
; G3M-NOT:   syncp
; G3M:       ldl.w [r6], r{{[0-9]+}}
; G3M:       add r7, r{{[0-9]+}}
; G3M:       stc.w r{{[0-9]+}}, [r6]
; G3M-NOT:   syncp
  %result = atomicrmw add ptr %ptr, i32 %val monotonic
  ret i32 %result
}

; --- Test memory ordering: acquire atomicrmw ---

define i32 @atomic_add_acquire(ptr %ptr, i32 %val) {
; G3M-LABEL: atomic_add_acquire:
; G3M-NOT:   syncp
; G3M:       ldl.w [r6], r{{[0-9]+}}
; G3M:       add r7, r{{[0-9]+}}
; G3M:       stc.w r{{[0-9]+}}, [r6]
; G3M:       syncp
  %result = atomicrmw add ptr %ptr, i32 %val acquire
  ret i32 %result
}

; --- Test memory ordering: release atomicrmw ---

define i32 @atomic_add_release(ptr %ptr, i32 %val) {
; G3M-LABEL: atomic_add_release:
; G3M:       syncp
; G3M:       ldl.w [r6], r{{[0-9]+}}
; G3M:       add r7, r{{[0-9]+}}
; G3M:       stc.w r{{[0-9]+}}, [r6]
; G3M-NOT:   syncp
  %result = atomicrmw add ptr %ptr, i32 %val release
  ret i32 %result
}
