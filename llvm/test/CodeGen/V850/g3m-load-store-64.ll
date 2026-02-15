; RUN: llc -mtriple=v850-unknown-elf -mcpu=g3m -O2 < %s | FileCheck %s
; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m -O2 < %s | FileCheck %s --check-prefix=NO-MERGE

; Test LD.DW/ST.DW merge optimization for RH850G3M.
; Adjacent LD.W/ST.W pairs with even-odd register pairs should be merged
; into LD.DW/ST.DW instructions on G3M.

; --- Basic 64-bit load ---

define i64 @load_i64(ptr %p) {
; CHECK-LABEL: load_i64:
; CHECK:       ld.dw 0[r6], r10
; CHECK-NEXT:  jmp [r31]
;
; NO-MERGE-LABEL: load_i64:
; NO-MERGE:       ld.w 0[r6], r10
; NO-MERGE:       ld.w 4[r6], r11
  %v = load i64, ptr %p, align 4
  ret i64 %v
}

; --- Basic 64-bit store ---
; Note: store_i64 passes i64 in r7:r8. r7 is odd so it cannot form an
; even-odd register pair. The optimizer correctly does NOT merge.

define void @store_i64_no_merge(ptr %p, i64 %v) {
; CHECK-LABEL: store_i64_no_merge:
; CHECK:       st.w r8, 4[r6]
; CHECK:       st.w r7, 0[r6]
;
; NO-MERGE-LABEL: store_i64_no_merge:
; NO-MERGE:       st.w r8, 4[r6]
; NO-MERGE:       st.w r7, 0[r6]
  store i64 %v, ptr %p, align 4
  ret void
}

; --- 64-bit load and store ---
; Load produces r10:r11 (even-odd pair), store of same value can merge.

define i64 @load_store_i64(ptr %p, ptr %q) {
; CHECK-LABEL: load_store_i64:
; CHECK:       ld.dw 0[r6], r10
; CHECK:       st.dw r10, 0[r7]
; CHECK:       jmp [r31]
;
; NO-MERGE-LABEL: load_store_i64:
; NO-MERGE:       ld.w 0[r6], r10
; NO-MERGE:       ld.w 4[r6], r11
  %v = load i64, ptr %p, align 4
  store i64 %v, ptr %q, align 4
  ret i64 %v
}

; --- Load with offset ---

define i64 @load_i64_offset(ptr %p) {
; CHECK-LABEL: load_i64_offset:
; CHECK:       ld.dw 16[r6], r10
; CHECK-NEXT:  jmp [r31]
;
; NO-MERGE-LABEL: load_i64_offset:
; NO-MERGE:       ld.w 16[r6], r10
; NO-MERGE:       ld.w 20[r6], r11
  %q = getelementptr i8, ptr %p, i64 16
  %v = load i64, ptr %q, align 4
  ret i64 %v
}

; --- Multiple 64-bit loads ---

define void @load_multiple(ptr %p, ptr %out1, ptr %out2) {
; CHECK-LABEL: load_multiple:
; CHECK-DAG:   ld.dw 0[r6], r{{[0-9]+}}
; CHECK-DAG:   ld.dw 8[r6], r{{[0-9]+}}
; CHECK-DAG:   st.dw r{{[0-9]+}}, 0[r7]
; CHECK-DAG:   st.dw r{{[0-9]+}}, 0[r8]
;
; NO-MERGE-LABEL: load_multiple:
; NO-MERGE-NOT:   ld.dw
  %p1 = getelementptr i64, ptr %p, i64 0
  %p2 = getelementptr i64, ptr %p, i64 1
  %v1 = load i64, ptr %p1, align 4
  %v2 = load i64, ptr %p2, align 4
  store i64 %v1, ptr %out1, align 4
  store i64 %v2, ptr %out2, align 4
  ret void
}

; --- Struct with two i32 fields loads as LD.DW ---

%struct.pair = type { i32, i32 }

define i64 @load_struct_pair(ptr %p) {
; CHECK-LABEL: load_struct_pair:
; CHECK:       ld.dw 0[r6], r10
; CHECK-NEXT:  jmp [r31]
;
; NO-MERGE-LABEL: load_struct_pair:
; NO-MERGE:       ld.w 0[r6], r10
; NO-MERGE:       ld.w 4[r6], r11
  %f0 = getelementptr %struct.pair, ptr %p, i64 0, i32 0
  %f1 = getelementptr %struct.pair, ptr %p, i64 0, i32 1
  %v0 = load i32, ptr %f0, align 4
  %v1 = load i32, ptr %f1, align 4
  %lo = zext i32 %v0 to i64
  %hi = zext i32 %v1 to i64
  %shifted = shl i64 %hi, 32
  %result = or i64 %shifted, %lo
  ret i64 %result
}
