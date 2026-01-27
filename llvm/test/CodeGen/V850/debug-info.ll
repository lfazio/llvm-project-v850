; RUN: llc -mtriple=v850-unknown-elf -mcpu=v850e2m -filetype=obj %s -o %t.o
; RUN: llvm-dwarfdump --debug-info %t.o | FileCheck %s

; Test that debug info is properly generated for V850.

; CHECK: .debug_info contents:
; CHECK: DW_TAG_compile_unit
; CHECK: DW_AT_producer
; CHECK: DW_AT_language (DW_LANG_C11)
; CHECK: DW_AT_name ("test.c")

; CHECK: DW_TAG_subprogram
; CHECK: DW_AT_name ("add")
; CHECK: DW_AT_type

; CHECK: DW_TAG_formal_parameter
; CHECK: DW_AT_name ("a")

; CHECK: DW_TAG_formal_parameter
; CHECK: DW_AT_name ("b")

; CHECK: DW_TAG_variable
; CHECK: DW_AT_name ("result")

define i32 @add(i32 %a, i32 %b) !dbg !5 {
entry:
  call void @llvm.dbg.value(metadata i32 %a, metadata !11, metadata !DIExpression()), !dbg !13
  call void @llvm.dbg.value(metadata i32 %b, metadata !12, metadata !DIExpression()), !dbg !13
  %sum = add nsw i32 %a, %b, !dbg !14
  call void @llvm.dbg.value(metadata i32 %sum, metadata !15, metadata !DIExpression()), !dbg !13
  ret i32 %sum, !dbg !16
}

declare void @llvm.dbg.value(metadata, metadata, metadata)

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3, !4}

!0 = distinct !DICompileUnit(language: DW_LANG_C11, file: !1, producer: "clang version 21", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "test.c", directory: "/tmp")
!2 = !{}
!3 = !{i32 7, !"Dwarf Version", i32 5}
!4 = !{i32 2, !"Debug Info Version", i32 3}
!5 = distinct !DISubprogram(name: "add", scope: !1, file: !1, line: 1, type: !6, scopeLine: 1, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0)
!6 = !DISubroutineType(types: !7)
!7 = !{!8, !8, !8}
!8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!11 = !DILocalVariable(name: "a", arg: 1, scope: !5, file: !1, line: 1, type: !8)
!12 = !DILocalVariable(name: "b", arg: 2, scope: !5, file: !1, line: 1, type: !8)
!13 = !DILocation(line: 0, scope: !5)
!14 = !DILocation(line: 2, column: 16, scope: !5)
!15 = !DILocalVariable(name: "result", scope: !5, file: !1, line: 2, type: !8)
!16 = !DILocation(line: 3, column: 5, scope: !5)
