; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test ST.H instruction - store halfword

; CHECK-LABEL: test_sth:
; CHECK: st.h r{{[0-9]+}}, 0[r{{[0-9]+}}]
define void @test_sth(ptr %p, i16 %v) {
  store i16 %v, ptr %p
  ret void
}

; CHECK-LABEL: test_sth_offset:
; CHECK: st.h r{{[0-9]+}}, {{[0-9]+}}[r{{[0-9]+}}]
define void @test_sth_offset(ptr %p, i16 %v) {
  %ptr = getelementptr i16, ptr %p, i32 5
  store i16 %v, ptr %ptr
  ret void
}
