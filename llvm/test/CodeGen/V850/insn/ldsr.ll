; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test LDSR instruction (load system register) via inline assembly

; CHECK-LABEL: test_ldsr_eipc:
; CHECK: ldsr r{{[0-9]+}}, eipc
define void @test_ldsr_eipc(i32 %val) {
  call void asm sideeffect "ldsr $0, eipc", "r"(i32 %val)
  ret void
}

; CHECK-LABEL: test_ldsr_psw:
; CHECK: ldsr r{{[0-9]+}}, psw
define void @test_ldsr_psw(i32 %val) {
  call void asm sideeffect "ldsr $0, psw", "r"(i32 %val)
  ret void
}

