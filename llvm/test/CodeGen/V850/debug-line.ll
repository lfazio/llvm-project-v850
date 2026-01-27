; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m -filetype=obj %s -o %t.o
; RUN: llvm-dwarfdump --debug-line %t.o | FileCheck %s

; Test that debug line information is properly generated for V850.

; CHECK: .debug_line contents:
; CHECK: debug_line[0x00000000]
; CHECK: Line table prologue:
; CHECK:   address_size: 4
; CHECK:   min_inst_length: 2

; Source file and line table check
; CHECK: include_directories
; CHECK: file_names

; Line number entries check
; CHECK: Address
; CHECK: is_stmt

define i32 @foo(i32 %x) !dbg !5 {
entry:
  %add = add nsw i32 %x, 42, !dbg !9
  ret i32 %add, !dbg !10
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "test.c", directory: "/tmp")
!2 = !{}
!3 = !{i32 7, !"Dwarf Version", i32 5}
!4 = !{i32 2, !"Debug Info Version", i32 3}
!5 = distinct !DISubprogram(name: "foo", scope: !1, file: !1, line: 1, type: !6, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0)
!6 = !DISubroutineType(types: !7)
!7 = !{!8, !8}
!8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!9 = !DILocation(line: 2, column: 12, scope: !5)
!10 = !DILocation(line: 2, column: 5, scope: !5)
