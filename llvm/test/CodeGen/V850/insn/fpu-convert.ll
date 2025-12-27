; RUN: llc -march=v850 -mcpu=v850e2m -O0 < %s | FileCheck %s

; Test FPU conversion operations with native instruction selection

; CHECK-LABEL: test_sitofp:
; CHECK: cvtf.ws
define float @test_sitofp(i32 %a) {
  %c = sitofp i32 %a to float
  ret float %c
}

; CHECK-LABEL: test_fptosi:
; CHECK: trncf.sw
define i32 @test_fptosi(float %a) {
  %c = fptosi float %a to i32
  ret i32 %c
}
