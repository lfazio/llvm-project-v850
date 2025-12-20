; RUN: llc -mtriple=v850 -version 2>&1 | FileCheck %s

; CHECK: Registered Targets:
; CHECK: v850 - NEC V850
