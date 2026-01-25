; RUN: llc -mtriple=v850 -mcpu=v850e2m -filetype=obj %s -o %t.o
; RUN: llvm-readelf -S %t.o | FileCheck %s --check-prefix=CHECK-SECTIONS
; RUN: llvm-readelf -r %t.o | FileCheck %s --check-prefix=CHECK-RELOC

; Test that object files are generated with correct sections and relocations.

; CHECK-SECTIONS: .text
; CHECK-SECTIONS: .eh_frame
; CHECK-SECTIONS: .symtab

; CHECK-RELOC: Relocation section '.rela.text'
; CHECK-RELOC: external

define i32 @test_call_external(i32 %a) {
entry:
  %result = call i32 @external(i32 %a)
  ret i32 %result
}

declare i32 @external(i32)
