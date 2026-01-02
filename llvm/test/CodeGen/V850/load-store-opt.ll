; RUN: llc -march=v850 -mcpu=v850e1 < %s | FileCheck %s

; Test load/store optimization for V850.
; The optimizer should promote 32-bit LD.W/ST.W to 16-bit SLD.W/SST.W
; when the base register is EP and displacement fits in 7 bits.

; Note: The V850 architecture does not have LD.DW/ST.DW (double-word)
; instructions. FPU double-precision uses register pairs with separate
; 32-bit load/store operations.

; Test basic word load - should use ld.w with non-EP base
define i32 @load_word(ptr %p) {
; CHECK-LABEL: load_word:
; CHECK: ld.w 0[r6], r10
entry:
  %val = load i32, ptr %p
  ret i32 %val
}

; Test basic word store - should use st.w with non-EP base
define void @store_word(ptr %p, i32 %val) {
; CHECK-LABEL: store_word:
; CHECK: st.w r7, 0[r6]
entry:
  store i32 %val, ptr %p
  ret void
}

; Test load with offset
define i32 @load_with_offset(ptr %p) {
; CHECK-LABEL: load_with_offset:
; CHECK: ld.w 16[r6], r10
entry:
  %ptr = getelementptr i32, ptr %p, i32 4
  %val = load i32, ptr %ptr
  ret i32 %val
}

; Test store with offset
define void @store_with_offset(ptr %p, i32 %val) {
; CHECK-LABEL: store_with_offset:
; CHECK: st.w r7, 16[r6]
entry:
  %ptr = getelementptr i32, ptr %p, i32 4
  store i32 %val, ptr %ptr
  ret void
}

; Test multiple loads - demonstrates memory access patterns
define i32 @multiple_loads(ptr %p) {
; CHECK-LABEL: multiple_loads:
; CHECK-DAG: ld.w 0[r6]
; CHECK-DAG: ld.w 4[r6]
entry:
  %val1 = load i32, ptr %p
  %ptr2 = getelementptr i32, ptr %p, i32 1
  %val2 = load i32, ptr %ptr2
  %sum = add i32 %val1, %val2
  ret i32 %sum
}

; Test multiple stores
define void @multiple_stores(ptr %p, i32 %a, i32 %b) {
; CHECK-LABEL: multiple_stores:
; CHECK: st.w
; CHECK: st.w
entry:
  store i32 %a, ptr %p
  %ptr2 = getelementptr i32, ptr %p, i32 1
  store i32 %b, ptr %ptr2
  ret void
}
