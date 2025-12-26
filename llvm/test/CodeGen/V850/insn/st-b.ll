; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test ST.B instruction - store byte

; CHECK-LABEL: test_stb:
; CHECK: st.b r{{[0-9]+}}, 0[r{{[0-9]+}}]
define void @test_stb(ptr %p, i8 %v) {
  store i8 %v, ptr %p
  ret void
}

; CHECK-LABEL: test_stb_offset:
; CHECK: st.b r{{[0-9]+}}, {{[0-9]+}}[r{{[0-9]+}}]
define void @test_stb_offset(ptr %p, i8 %v) {
  %ptr = getelementptr i8, ptr %p, i32 10
  store i8 %v, ptr %ptr
  ret void
}
