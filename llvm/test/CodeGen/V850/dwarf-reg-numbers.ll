; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m < %s | FileCheck %s

; Test that DWARF register numbers are correctly used in CFI directives.
;
; V850 DWARF Register Number Mapping:
;   DWARF 0-31:  General purpose registers r0-r31
;   DWARF 64:    PC (Program Counter)
;   DWARF 65:    PSW (Program Status Word)
;   DWARF 66-69: Exception registers (EIPC, EIPSW, FEPC, FEPSW)
;   DWARF 70:    ECR (Exception Cause Register)
;   DWARF 71-73: CALLT registers (CTPC, CTPSW, CTBP)
;   DWARF 74-75: Debug registers (DBPC, DBPSW)

declare void @external()

; Test 1: Function with callee-saved registers
; The CFI directives should reference DWARF register numbers
; CHECK-LABEL: test_csr:
; CHECK:       .cfi_startproc
; CHECK:       .cfi_def_cfa_offset
; CHECK:       .cfi_offset r31, -4
; CHECK:       jarl external, r31
; CHECK:       .cfi_endproc
define void @test_csr() {
  call void @external()
  ret void
}

; Test 2: Function with multiple callee-saved registers
; CHECK-LABEL: test_multi_csr:
; CHECK:       .cfi_startproc
; CHECK:       .cfi_def_cfa_offset
; CHECK:       .cfi_offset r31
; CHECK:       .cfi_endproc
define i32 @test_multi_csr(i32 %a) {
entry:
  %call1 = call i32 @bar(i32 %a)
  %call2 = call i32 @bar(i32 %call1)
  ret i32 %call2
}

declare i32 @bar(i32)

; Test 3: Function with frame pointer (r29)
; CHECK-LABEL: test_fp:
; CHECK:       .cfi_startproc
; CHECK:       .cfi_def_cfa_offset
; CHECK:       .cfi_endproc
define i32 @test_fp(i32 %n) "frame-pointer"="all" {
entry:
  %vla = alloca i32, i32 %n, align 4
  store i32 42, ptr %vla, align 4
  %val = load i32, ptr %vla, align 4
  ret i32 %val
}
