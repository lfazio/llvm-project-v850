; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test ST.W instruction - store word

; CHECK-LABEL: test_stw:
; CHECK: st.w r{{[0-9]+}}, 0[r{{[0-9]+}}]
define void @test_stw(ptr %p, i32 %v) {
  store i32 %v, ptr %p
  ret void
}

; CHECK-LABEL: test_stw_offset:
; CHECK: st.w r{{[0-9]+}}, {{[0-9]+}}[r{{[0-9]+}}]
define void @test_stw_offset(ptr %p, i32 %v) {
  %ptr = getelementptr i32, ptr %p, i32 5
  store i32 %v, ptr %ptr
  ret void
}
