; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m -O2 < %s | FileCheck %s

; Test that small global variables use GP-relative addressing

@small_int = internal global i32 0
@small_short = internal global i16 0
@small_char = internal global i8 0

; CHECK-LABEL: load_small_int:
; CHECK: ld.w small_int[r4]
define i32 @load_small_int() {
  %val = load i32, ptr @small_int
  ret i32 %val
}

; CHECK-LABEL: store_small_int:
; CHECK: st.w r6, small_int[r4]
define void @store_small_int(i32 %val) {
  store i32 %val, ptr @small_int
  ret void
}

; CHECK-LABEL: load_small_short:
; CHECK: ld.h small_short[r4]
define i32 @load_small_short() {
  %val = load i16, ptr @small_short
  %ext = sext i16 %val to i32
  ret i32 %ext
}

; CHECK-LABEL: store_small_short:
; CHECK: st.h r6, small_short[r4]
define void @store_small_short(i16 %val) {
  store i16 %val, ptr @small_short
  ret void
}

; CHECK-LABEL: load_small_char:
; CHECK: ld.b small_char[r4]
define i32 @load_small_char() {
  %val = load i8, ptr @small_char
  %ext = sext i8 %val to i32
  ret i32 %ext
}

; CHECK-LABEL: store_small_char:
; CHECK: st.b r6, small_char[r4]
define void @store_small_char(i8 %val) {
  store i8 %val, ptr @small_char
  ret void
}

; Note: Testing large globals (that should NOT use GP-relative addressing)
; requires absolute address materialization which uses a separate code path.
