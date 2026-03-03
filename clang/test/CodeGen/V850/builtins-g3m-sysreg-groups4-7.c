// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu g3m -emit-llvm -o - %s | FileCheck %s

// Test named builtins for RH850G3M system registers (groups 4-5 and ASID_G2).
// These expand to ldsr/stsr with unified 10-bit encoding: (selID << 5) | regID.
// Groups 6-7 (MPU region registers) use __builtin_v850_ldsr_group/stsr_group.

// === ASID at G3M location (regID=7, selID=2) ===

// CHECK-LABEL: @test_read_asid_g2
unsigned int test_read_asid_g2(void) {
  // enc = (2 << 5) | 7 = 71
  // CHECK: call i32 @llvm.v850.stsr(i32 71)
  return __builtin_v850_read_asid_g2();
}

// CHECK-LABEL: @test_write_asid_g2
void test_write_asid_g2(unsigned int val) {
  // enc = (2 << 5) | 7 = 71
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 71)
  __builtin_v850_write_asid_g2(val);
}

// === Group 4: Instruction Cache Control (selID=4) ===

// CHECK-LABEL: @test_write_ictagl
void test_write_ictagl(unsigned int val) {
  // enc = (4 << 5) | 16 = 144 (write-only)
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 144)
  __builtin_v850_write_ictagl(val);
}

// CHECK-LABEL: @test_write_ictagh
void test_write_ictagh(unsigned int val) {
  // enc = (4 << 5) | 17 = 145 (write-only)
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 145)
  __builtin_v850_write_ictagh(val);
}

// CHECK-LABEL: @test_write_icdatl
void test_write_icdatl(unsigned int val) {
  // enc = (4 << 5) | 18 = 146 (write-only)
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 146)
  __builtin_v850_write_icdatl(val);
}

// CHECK-LABEL: @test_write_icdath
void test_write_icdath(unsigned int val) {
  // enc = (4 << 5) | 19 = 147 (write-only)
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 147)
  __builtin_v850_write_icdath(val);
}

// CHECK-LABEL: @test_read_icctrl
unsigned int test_read_icctrl(void) {
  // enc = (4 << 5) | 24 = 152
  // CHECK: call i32 @llvm.v850.stsr(i32 152)
  return __builtin_v850_read_icctrl();
}

// CHECK-LABEL: @test_write_icctrl
void test_write_icctrl(unsigned int val) {
  // enc = (4 << 5) | 24 = 152
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 152)
  __builtin_v850_write_icctrl(val);
}

// CHECK-LABEL: @test_read_iccfg
unsigned int test_read_iccfg(void) {
  // enc = (4 << 5) | 26 = 154 (read-only)
  // CHECK: call i32 @llvm.v850.stsr(i32 154)
  return __builtin_v850_read_iccfg();
}

// CHECK-LABEL: @test_read_icerr
unsigned int test_read_icerr(void) {
  // enc = (4 << 5) | 28 = 156
  // CHECK: call i32 @llvm.v850.stsr(i32 156)
  return __builtin_v850_read_icerr();
}

// CHECK-LABEL: @test_write_icerr
void test_write_icerr(unsigned int val) {
  // enc = (4 << 5) | 28 = 156
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 156)
  __builtin_v850_write_icerr(val);
}

// === Group 5: MPU Mode/Control (selID=5) ===

// CHECK-LABEL: @test_read_mpm
unsigned int test_read_mpm(void) {
  // enc = (5 << 5) | 0 = 160
  // CHECK: call i32 @llvm.v850.stsr(i32 160)
  return __builtin_v850_read_mpm();
}

// CHECK-LABEL: @test_write_mpm
void test_write_mpm(unsigned int val) {
  // enc = (5 << 5) | 0 = 160
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 160)
  __builtin_v850_write_mpm(val);
}

// CHECK-LABEL: @test_read_mprc
unsigned int test_read_mprc(void) {
  // enc = (5 << 5) | 1 = 161
  // CHECK: call i32 @llvm.v850.stsr(i32 161)
  return __builtin_v850_read_mprc();
}

// CHECK-LABEL: @test_write_mprc
void test_write_mprc(unsigned int val) {
  // enc = (5 << 5) | 1 = 161
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 161)
  __builtin_v850_write_mprc(val);
}

// CHECK-LABEL: @test_read_mpbrgn
unsigned int test_read_mpbrgn(void) {
  // enc = (5 << 5) | 4 = 164 (read-only)
  // CHECK: call i32 @llvm.v850.stsr(i32 164)
  return __builtin_v850_read_mpbrgn();
}

// CHECK-LABEL: @test_read_mptrgn
unsigned int test_read_mptrgn(void) {
  // enc = (5 << 5) | 5 = 165 (read-only)
  // CHECK: call i32 @llvm.v850.stsr(i32 165)
  return __builtin_v850_read_mptrgn();
}

// CHECK-LABEL: @test_read_mca
unsigned int test_read_mca(void) {
  // enc = (5 << 5) | 8 = 168
  // CHECK: call i32 @llvm.v850.stsr(i32 168)
  return __builtin_v850_read_mca();
}

// CHECK-LABEL: @test_write_mca
void test_write_mca(unsigned int val) {
  // enc = (5 << 5) | 8 = 168
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 168)
  __builtin_v850_write_mca(val);
}

// CHECK-LABEL: @test_read_mcs
unsigned int test_read_mcs(void) {
  // enc = (5 << 5) | 9 = 169
  // CHECK: call i32 @llvm.v850.stsr(i32 169)
  return __builtin_v850_read_mcs();
}

// CHECK-LABEL: @test_write_mcs
void test_write_mcs(unsigned int val) {
  // enc = (5 << 5) | 9 = 169
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 169)
  __builtin_v850_write_mcs(val);
}

// CHECK-LABEL: @test_read_mcc
unsigned int test_read_mcc(void) {
  // enc = (5 << 5) | 10 = 170
  // CHECK: call i32 @llvm.v850.stsr(i32 170)
  return __builtin_v850_read_mcc();
}

// CHECK-LABEL: @test_write_mcc
void test_write_mcc(unsigned int val) {
  // enc = (5 << 5) | 10 = 170
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 170)
  __builtin_v850_write_mcc(val);
}

// CHECK-LABEL: @test_read_mcr
unsigned int test_read_mcr(void) {
  // enc = (5 << 5) | 11 = 171 (read-only)
  // CHECK: call i32 @llvm.v850.stsr(i32 171)
  return __builtin_v850_read_mcr();
}
