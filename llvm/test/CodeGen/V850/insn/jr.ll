; RUN: llc -march=v850 -O0 < %s | FileCheck %s

; Test JR instruction - jump relative

; CHECK-LABEL: test_jr:
; CHECK: jr .LBB
define void @test_jr(i32 %a) {
entry:
  %cmp = icmp eq i32 %a, 0
  br i1 %cmp, label %then, label %end

then:
  call void asm sideeffect "nop", ""()
  br label %end

end:
  ret void
}

