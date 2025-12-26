; RUN: llc -march=v850 -O2 < %s | FileCheck %s

; Test JMP instruction via indirect call

; CHECK-LABEL: test_indirect_call:
; CHECK: jmp [r{{[0-9]+}}]
define i32 @test_indirect_call(ptr %func) {
  %result = call i32 %func()
  ret i32 %result
}
