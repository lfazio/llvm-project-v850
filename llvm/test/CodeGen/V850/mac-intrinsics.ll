; RUN: llc -march=v850 -mcpu=v850e2m < %s | FileCheck %s

;===----------------------------------------------------------------------===;
; Test MAC/MACU intrinsics
;
; These intrinsics provide direct access to the MAC/MACU instructions:
; - llvm.v850.mac: Signed 32x32 multiply with 64-bit accumulate
; - llvm.v850.macu: Unsigned 32x32 multiply with 64-bit accumulate
;
; Both intrinsics take 4 i32 arguments (a, b, acc_hi, acc_lo) and return
; a pair of i32 values (result_hi, result_lo).
;===----------------------------------------------------------------------===;

declare {i32, i32} @llvm.v850.mac(i32, i32, i32, i32)
declare {i32, i32} @llvm.v850.macu(i32, i32, i32, i32)

;===----------------------------------------------------------------------===;
; Basic MAC intrinsic test
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_mac_intrinsic:
; CHECK: mac r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: jmp [r31]
define {i32, i32} @test_mac_intrinsic(i32 %a, i32 %b, i32 %hi, i32 %lo) {
entry:
  %result = call {i32, i32} @llvm.v850.mac(i32 %a, i32 %b, i32 %hi, i32 %lo)
  ret {i32, i32} %result
}

;===----------------------------------------------------------------------===;
; Basic MACU intrinsic test
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_macu_intrinsic:
; CHECK: macu r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: jmp [r31]
define {i32, i32} @test_macu_intrinsic(i32 %a, i32 %b, i32 %hi, i32 %lo) {
entry:
  %result = call {i32, i32} @llvm.v850.macu(i32 %a, i32 %b, i32 %hi, i32 %lo)
  ret {i32, i32} %result
}

;===----------------------------------------------------------------------===;
; Test MAC with immediate-like values (accumulator starts at 0)
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_mac_zero_accum:
; CHECK: mac r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: jmp [r31]
define {i32, i32} @test_mac_zero_accum(i32 %a, i32 %b) {
entry:
  %result = call {i32, i32} @llvm.v850.mac(i32 %a, i32 %b, i32 0, i32 0)
  ret {i32, i32} %result
}

;===----------------------------------------------------------------------===;
; Test MACU with immediate-like values (accumulator starts at 0)
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_macu_zero_accum:
; CHECK: macu r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: jmp [r31]
define {i32, i32} @test_macu_zero_accum(i32 %a, i32 %b) {
entry:
  %result = call {i32, i32} @llvm.v850.macu(i32 %a, i32 %b, i32 0, i32 0)
  ret {i32, i32} %result
}

;===----------------------------------------------------------------------===;
; Test extracting only the low part of MAC result
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_mac_extract_lo:
; CHECK: mac r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: jmp [r31]
define i32 @test_mac_extract_lo(i32 %a, i32 %b, i32 %hi, i32 %lo) {
entry:
  %result = call {i32, i32} @llvm.v850.mac(i32 %a, i32 %b, i32 %hi, i32 %lo)
  %lo_result = extractvalue {i32, i32} %result, 1
  ret i32 %lo_result
}

;===----------------------------------------------------------------------===;
; Test extracting only the high part of MAC result
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_mac_extract_hi:
; CHECK: mac r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: jmp [r31]
define i32 @test_mac_extract_hi(i32 %a, i32 %b, i32 %hi, i32 %lo) {
entry:
  %result = call {i32, i32} @llvm.v850.mac(i32 %a, i32 %b, i32 %hi, i32 %lo)
  %hi_result = extractvalue {i32, i32} %result, 0
  ret i32 %hi_result
}

;===----------------------------------------------------------------------===;
; Test chained MAC operations (accumulating multiple products)
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_mac_chain:
; CHECK: mac r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: mac r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: jmp [r31]
define {i32, i32} @test_mac_chain(i32 %a, i32 %b, i32 %c, i32 %d) {
entry:
  ; First MAC: 0 + a*b
  %result1 = call {i32, i32} @llvm.v850.mac(i32 %a, i32 %b, i32 0, i32 0)
  %hi1 = extractvalue {i32, i32} %result1, 0
  %lo1 = extractvalue {i32, i32} %result1, 1
  ; Second MAC: (a*b) + c*d
  %result2 = call {i32, i32} @llvm.v850.mac(i32 %c, i32 %d, i32 %hi1, i32 %lo1)
  ret {i32, i32} %result2
}

;===----------------------------------------------------------------------===;
; Test chained MACU operations (accumulating multiple products)
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_macu_chain:
; CHECK: macu r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: macu r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: jmp [r31]
define {i32, i32} @test_macu_chain(i32 %a, i32 %b, i32 %c, i32 %d) {
entry:
  ; First MACU: 0 + a*b
  %result1 = call {i32, i32} @llvm.v850.macu(i32 %a, i32 %b, i32 0, i32 0)
  %hi1 = extractvalue {i32, i32} %result1, 0
  %lo1 = extractvalue {i32, i32} %result1, 1
  ; Second MACU: (a*b) + c*d
  %result2 = call {i32, i32} @llvm.v850.macu(i32 %c, i32 %d, i32 %hi1, i32 %lo1)
  ret {i32, i32} %result2
}

;===----------------------------------------------------------------------===;
; Test combining MAC result into i64
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_mac_to_i64:
; CHECK: mac r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}, r{{[0-9]+}}
; CHECK: jmp [r31]
define i64 @test_mac_to_i64(i32 %a, i32 %b, i32 %hi, i32 %lo) {
entry:
  %result = call {i32, i32} @llvm.v850.mac(i32 %a, i32 %b, i32 %hi, i32 %lo)
  %hi_result = extractvalue {i32, i32} %result, 0
  %lo_result = extractvalue {i32, i32} %result, 1
  ; Combine hi:lo into i64
  %hi_ext = zext i32 %hi_result to i64
  %hi_shifted = shl i64 %hi_ext, 32
  %lo_ext = zext i32 %lo_result to i64
  %combined = or i64 %hi_shifted, %lo_ext
  ret i64 %combined
}
