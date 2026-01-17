; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s

;===----------------------------------------------------------------------===;
; Test system register access intrinsics (LDSR/STSR)
;
; V850 provides LDSR/STSR instructions for accessing system registers.
; These intrinsics allow direct access to system registers by regID.
;===----------------------------------------------------------------------===;

declare i32 @llvm.v850.stsr(i32)
declare void @llvm.v850.ldsr(i32, i32)

;===----------------------------------------------------------------------===;
; STSR (Store from System Register) Tests
;===----------------------------------------------------------------------===;

; Test reading EIPC (regID 0)
; CHECK-LABEL: test_stsr_eipc:
; CHECK: stsr eipc, r{{[0-9]+}}
; CHECK: jmp [r31]
define i32 @test_stsr_eipc() {
entry:
  %val = call i32 @llvm.v850.stsr(i32 0)
  ret i32 %val
}

; Test reading EIPSW (regID 1)
; CHECK-LABEL: test_stsr_eipsw:
; CHECK: stsr eipsw, r{{[0-9]+}}
; CHECK: jmp [r31]
define i32 @test_stsr_eipsw() {
entry:
  %val = call i32 @llvm.v850.stsr(i32 1)
  ret i32 %val
}

; Test reading FEPC (regID 2)
; CHECK-LABEL: test_stsr_fepc:
; CHECK: stsr fepc, r{{[0-9]+}}
; CHECK: jmp [r31]
define i32 @test_stsr_fepc() {
entry:
  %val = call i32 @llvm.v850.stsr(i32 2)
  ret i32 %val
}

; Test reading FEPSW (regID 3)
; CHECK-LABEL: test_stsr_fepsw:
; CHECK: stsr fepsw, r{{[0-9]+}}
; CHECK: jmp [r31]
define i32 @test_stsr_fepsw() {
entry:
  %val = call i32 @llvm.v850.stsr(i32 3)
  ret i32 %val
}

; Test reading ECR (regID 4)
; CHECK-LABEL: test_stsr_ecr:
; CHECK: stsr ecr, r{{[0-9]+}}
; CHECK: jmp [r31]
define i32 @test_stsr_ecr() {
entry:
  %val = call i32 @llvm.v850.stsr(i32 4)
  ret i32 %val
}

; Test reading PSW (regID 5)
; CHECK-LABEL: test_stsr_psw:
; CHECK: stsr psw, r{{[0-9]+}}
; CHECK: jmp [r31]
define i32 @test_stsr_psw() {
entry:
  %val = call i32 @llvm.v850.stsr(i32 5)
  ret i32 %val
}

; Test reading CTPC (regID 16) - V850E1+
; CHECK-LABEL: test_stsr_ctpc:
; CHECK: stsr ctpc, r{{[0-9]+}}
; CHECK: jmp [r31]
define i32 @test_stsr_ctpc() {
entry:
  %val = call i32 @llvm.v850.stsr(i32 16)
  ret i32 %val
}

; Test reading CTPSW (regID 17) - V850E1+
; CHECK-LABEL: test_stsr_ctpsw:
; CHECK: stsr ctpsw, r{{[0-9]+}}
; CHECK: jmp [r31]
define i32 @test_stsr_ctpsw() {
entry:
  %val = call i32 @llvm.v850.stsr(i32 17)
  ret i32 %val
}

; Test reading CTBP (regID 20) - V850E1+
; CHECK-LABEL: test_stsr_ctbp:
; CHECK: stsr ctbp, r{{[0-9]+}}
; CHECK: jmp [r31]
define i32 @test_stsr_ctbp() {
entry:
  %val = call i32 @llvm.v850.stsr(i32 20)
  ret i32 %val
}

; Test reading EIWR (regID 28)
; CHECK-LABEL: test_stsr_eiwr:
; CHECK: stsr eiwr, r{{[0-9]+}}
; CHECK: jmp [r31]
define i32 @test_stsr_eiwr() {
entry:
  %val = call i32 @llvm.v850.stsr(i32 28)
  ret i32 %val
}

; Test reading FEWR (regID 29)
; CHECK-LABEL: test_stsr_fewr:
; CHECK: stsr fewr, r{{[0-9]+}}
; CHECK: jmp [r31]
define i32 @test_stsr_fewr() {
entry:
  %val = call i32 @llvm.v850.stsr(i32 29)
  ret i32 %val
}

; Test reading BSEL (regID 31)
; CHECK-LABEL: test_stsr_bsel:
; CHECK: stsr bsel, r{{[0-9]+}}
; CHECK: jmp [r31]
define i32 @test_stsr_bsel() {
entry:
  %val = call i32 @llvm.v850.stsr(i32 31)
  ret i32 %val
}

;===----------------------------------------------------------------------===;
; LDSR (Load to System Register) Tests
;===----------------------------------------------------------------------===;

; Test writing EIPC (regID 0)
; CHECK-LABEL: test_ldsr_eipc:
; CHECK: ldsr r{{[0-9]+}}, eipc
; CHECK: jmp [r31]
define void @test_ldsr_eipc(i32 %val) {
entry:
  call void @llvm.v850.ldsr(i32 %val, i32 0)
  ret void
}

; Test writing EIPSW (regID 1)
; CHECK-LABEL: test_ldsr_eipsw:
; CHECK: ldsr r{{[0-9]+}}, eipsw
; CHECK: jmp [r31]
define void @test_ldsr_eipsw(i32 %val) {
entry:
  call void @llvm.v850.ldsr(i32 %val, i32 1)
  ret void
}

; Test writing PSW (regID 5)
; CHECK-LABEL: test_ldsr_psw:
; CHECK: ldsr r{{[0-9]+}}, psw
; CHECK: jmp [r31]
define void @test_ldsr_psw(i32 %val) {
entry:
  call void @llvm.v850.ldsr(i32 %val, i32 5)
  ret void
}

; Test writing BSEL (regID 31)
; CHECK-LABEL: test_ldsr_bsel:
; CHECK: ldsr r{{[0-9]+}}, bsel
; CHECK: jmp [r31]
define void @test_ldsr_bsel(i32 %val) {
entry:
  call void @llvm.v850.ldsr(i32 %val, i32 31)
  ret void
}

;===----------------------------------------------------------------------===;
; Combined LDSR/STSR Pattern Tests
;===----------------------------------------------------------------------===;

; Test read-modify-write pattern on PSW
; CHECK-LABEL: test_psw_modify:
; CHECK: stsr psw, r{{[0-9]+}}
; CHECK: or
; CHECK: ldsr r{{[0-9]+}}, psw
; CHECK: jmp [r31]
define void @test_psw_modify(i32 %mask) {
entry:
  %old = call i32 @llvm.v850.stsr(i32 5)
  %new = or i32 %old, %mask
  call void @llvm.v850.ldsr(i32 %new, i32 5)
  ret void
}

; Test saving and restoring PSW
; CHECK-LABEL: test_psw_save_restore:
; CHECK: stsr psw, r{{[0-9]+}}
; CHECK: ldsr r{{[0-9]+}}, psw
; CHECK: jmp [r31]
define i32 @test_psw_save_restore(i32 %temp_psw) {
entry:
  %old = call i32 @llvm.v850.stsr(i32 5)
  call void @llvm.v850.ldsr(i32 %temp_psw, i32 5)
  ; Do some work...
  call void @llvm.v850.ldsr(i32 %old, i32 5)
  ret i32 %old
}
