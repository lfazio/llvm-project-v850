; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test STSR instruction (store system register) via inline assembly

; CHECK-LABEL: test_stsr_eipc:
; CHECK: stsr eipc, r{{[0-9]+}}
define i32 @test_stsr_eipc() {
  %val = call i32 asm sideeffect "stsr eipc, $0", "=r"()
  ret i32 %val
}

; CHECK-LABEL: test_stsr_psw:
; CHECK: stsr psw, r{{[0-9]+}}
define i32 @test_stsr_psw() {
  %val = call i32 asm sideeffect "stsr psw, $0", "=r"()
  ret i32 %val
}

