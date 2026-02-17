; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s

;===----------------------------------------------------------------------===;
; Test FPU system register access via BSEL banking intrinsics
;
; V850E2M requires BSEL bank switching to access FPU system registers.
; These intrinsics automatically generate the proper sequence:
;   1. movhi 0x20, r0, $scratch  ; $scratch = 0x2000 (FPU bank)
;   2. ldsr  $scratch, bsel      ; Select FPU bank
;   3. stsr/ldsr fpu_reg         ; Access FPU register
;   4. mov   r0, $scratch        ; $scratch = 0
;   5. ldsr  $scratch, bsel      ; Restore CPU main bank
;===----------------------------------------------------------------------===;

declare i32 @llvm.v850.read.fpsr()
declare i32 @llvm.v850.read.fpepc()
declare i32 @llvm.v850.read.fpst()
declare i32 @llvm.v850.read.fpcc()
declare i32 @llvm.v850.read.fpcfg()
declare i32 @llvm.v850.read.fpec()

declare void @llvm.v850.write.fpsr(i32)
declare void @llvm.v850.write.fpepc(i32)
declare void @llvm.v850.write.fpst(i32)
declare void @llvm.v850.write.fpcc(i32)
declare void @llvm.v850.write.fpcfg(i32)
declare void @llvm.v850.write.fpec(i32)

;===----------------------------------------------------------------------===;
; Read FPU Registers Tests
;===----------------------------------------------------------------------===;

; Test reading FPSR (regID 6) with BSEL banking
; CHECK-LABEL: test_read_fpsr:
; CHECK:       movhi r0, 32, [[SCRATCH:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH]], bsel
; CHECK-NEXT:  stsr fpsr, [[RESULT:r[0-9]+]]
; CHECK-NEXT:  mov r0, [[SCRATCH2:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH2]], bsel
; CHECK:       jmp [r31]
define i32 @test_read_fpsr() {
entry:
  %0 = call i32 @llvm.v850.read.fpsr()
  ret i32 %0
}

; Test reading FPEPC (regID 7) with BSEL banking
; CHECK-LABEL: test_read_fpepc:
; CHECK:       movhi r0, 32, [[SCRATCH:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH]], bsel
; CHECK-NEXT:  stsr fpepc, [[RESULT:r[0-9]+]]
; CHECK-NEXT:  mov r0, [[SCRATCH2:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH2]], bsel
define i32 @test_read_fpepc() {
entry:
  %0 = call i32 @llvm.v850.read.fpepc()
  ret i32 %0
}

; Test reading FPST (regID 8) with BSEL banking
; CHECK-LABEL: test_read_fpst:
; CHECK:       movhi r0, 32, [[SCRATCH:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH]], bsel
; CHECK-NEXT:  stsr fpst, [[RESULT:r[0-9]+]]
; CHECK-NEXT:  mov r0, [[SCRATCH2:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH2]], bsel
define i32 @test_read_fpst() {
entry:
  %0 = call i32 @llvm.v850.read.fpst()
  ret i32 %0
}

; Test reading FPCC (regID 9) with BSEL banking
; CHECK-LABEL: test_read_fpcc:
; CHECK:       movhi r0, 32, [[SCRATCH:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH]], bsel
; CHECK-NEXT:  stsr fpcc, [[RESULT:r[0-9]+]]
; CHECK-NEXT:  mov r0, [[SCRATCH2:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH2]], bsel
define i32 @test_read_fpcc() {
entry:
  %0 = call i32 @llvm.v850.read.fpcc()
  ret i32 %0
}

; Test reading FPCFG (regID 10) with BSEL banking
; CHECK-LABEL: test_read_fpcfg:
; CHECK:       movhi r0, 32, [[SCRATCH:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH]], bsel
; CHECK-NEXT:  stsr fpcfg, [[RESULT:r[0-9]+]]
; CHECK-NEXT:  mov r0, [[SCRATCH2:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH2]], bsel
define i32 @test_read_fpcfg() {
entry:
  %0 = call i32 @llvm.v850.read.fpcfg()
  ret i32 %0
}

; Test reading FPEC (regID 11) with BSEL banking
; CHECK-LABEL: test_read_fpec:
; CHECK:       movhi r0, 32, [[SCRATCH:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH]], bsel
; CHECK-NEXT:  stsr sccfg, [[RESULT:r[0-9]+]]
; CHECK-NEXT:  mov r0, [[SCRATCH2:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH2]], bsel
define i32 @test_read_fpec() {
entry:
  %0 = call i32 @llvm.v850.read.fpec()
  ret i32 %0
}

;===----------------------------------------------------------------------===;
; Write FPU Registers Tests
;===----------------------------------------------------------------------===;

; Test writing FPSR (regID 6) with BSEL banking
; CHECK-LABEL: test_write_fpsr:
; CHECK:       movhi r0, 32, [[SCRATCH:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH]], bsel
; CHECK-NEXT:  ldsr r6, fpsr
; CHECK-NEXT:  mov r0, [[SCRATCH2:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH2]], bsel
define void @test_write_fpsr(i32 %value) {
entry:
  call void @llvm.v850.write.fpsr(i32 %value)
  ret void
}

; Test writing FPEPC (regID 7) with BSEL banking
; CHECK-LABEL: test_write_fpepc:
; CHECK:       movhi r0, 32, [[SCRATCH:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH]], bsel
; CHECK-NEXT:  ldsr r6, fpepc
; CHECK-NEXT:  mov r0, [[SCRATCH2:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH2]], bsel
define void @test_write_fpepc(i32 %value) {
entry:
  call void @llvm.v850.write.fpepc(i32 %value)
  ret void
}

; Test writing FPST (regID 8) with BSEL banking
; CHECK-LABEL: test_write_fpst:
; CHECK:       movhi r0, 32, [[SCRATCH:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH]], bsel
; CHECK-NEXT:  ldsr r6, fpst
; CHECK-NEXT:  mov r0, [[SCRATCH2:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH2]], bsel
define void @test_write_fpst(i32 %value) {
entry:
  call void @llvm.v850.write.fpst(i32 %value)
  ret void
}

; Test writing FPCC (regID 9) with BSEL banking
; CHECK-LABEL: test_write_fpcc:
; CHECK:       movhi r0, 32, [[SCRATCH:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH]], bsel
; CHECK-NEXT:  ldsr r6, fpcc
; CHECK-NEXT:  mov r0, [[SCRATCH2:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH2]], bsel
define void @test_write_fpcc(i32 %value) {
entry:
  call void @llvm.v850.write.fpcc(i32 %value)
  ret void
}

; Test writing FPCFG (regID 10) with BSEL banking
; CHECK-LABEL: test_write_fpcfg:
; CHECK:       movhi r0, 32, [[SCRATCH:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH]], bsel
; CHECK-NEXT:  ldsr r6, fpcfg
; CHECK-NEXT:  mov r0, [[SCRATCH2:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH2]], bsel
define void @test_write_fpcfg(i32 %value) {
entry:
  call void @llvm.v850.write.fpcfg(i32 %value)
  ret void
}

; Test writing FPEC (regID 11) with BSEL banking
; CHECK-LABEL: test_write_fpec:
; CHECK:       movhi r0, 32, [[SCRATCH:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH]], bsel
; CHECK-NEXT:  ldsr r6, sccfg
; CHECK-NEXT:  mov r0, [[SCRATCH2:r[0-9]+]]
; CHECK-NEXT:  ldsr [[SCRATCH2]], bsel
define void @test_write_fpec(i32 %value) {
entry:
  call void @llvm.v850.write.fpec(i32 %value)
  ret void
}

;===----------------------------------------------------------------------===;
; Combination Tests
;===----------------------------------------------------------------------===;

; Test reading multiple FPU registers
; With constant materialization optimization, the BSEL constant may be reused
; CHECK-LABEL: test_read_multiple:
; CHECK:       movhi r0, 32,
; CHECK:       ldsr {{r[0-9]+}}, bsel
; CHECK:       stsr fpsr,
; CHECK:       mov r0,
; CHECK:       ldsr {{r[0-9]+}}, bsel
; CHECK:       ldsr {{r[0-9]+}}, bsel
; CHECK:       stsr fpcc,
; CHECK:       mov r0,
; CHECK:       ldsr {{r[0-9]+}}, bsel
define i32 @test_read_multiple() {
entry:
  %fpsr = call i32 @llvm.v850.read.fpsr()
  %fpcc = call i32 @llvm.v850.read.fpcc()
  %result = add i32 %fpsr, %fpcc
  ret i32 %result
}

; Test read-modify-write pattern
; With constant materialization optimization, the BSEL constant is reused
; CHECK-LABEL: test_read_modify_write:
; CHECK:       movhi r0, 32,
; CHECK:       ldsr {{r[0-9]+}}, bsel
; CHECK:       stsr fpsr,
; CHECK:       mov r0,
; CHECK:       or
; CHECK:       ldsr {{r[0-9]+}}, bsel
; CHECK:       ldsr {{r[0-9]+}}, bsel
; CHECK:       ldsr {{r[0-9]+}}, fpsr
; CHECK:       mov r0,
; CHECK:       ldsr {{r[0-9]+}}, bsel
define void @test_read_modify_write(i32 %mask) {
entry:
  %fpsr = call i32 @llvm.v850.read.fpsr()
  %new_fpsr = or i32 %fpsr, %mask
  call void @llvm.v850.write.fpsr(i32 %new_fpsr)
  ret void
}

; Test exception handling - save and restore FPU state
; CHECK-LABEL: test_save_restore_fpu_state:
define void @test_save_restore_fpu_state(ptr %save_area) {
entry:
  ; Read and save FPSR
  %fpsr = call i32 @llvm.v850.read.fpsr()
  store i32 %fpsr, ptr %save_area, align 4

  ; Read and save FPCFG
  %fpcfg_ptr = getelementptr i32, ptr %save_area, i32 1
  %fpcfg = call i32 @llvm.v850.read.fpcfg()
  store i32 %fpcfg, ptr %fpcfg_ptr, align 4

  ; Read and save FPCC
  %fpcc_ptr = getelementptr i32, ptr %save_area, i32 2
  %fpcc = call i32 @llvm.v850.read.fpcc()
  store i32 %fpcc, ptr %fpcc_ptr, align 4

  ret void
}
