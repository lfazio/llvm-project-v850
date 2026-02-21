// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu g3m -emit-llvm -o - %s | FileCheck %s

// Test named builtins for RH850G3M system registers (groups 1-2).
// These expand to ldsr/stsr with unified 10-bit encoding: (selID << 5) | regID.

// === Group 1: Machine Configuration (selID=1) ===

// CHECK-LABEL: @test_read_rbase
unsigned int test_read_rbase(void) {
  // enc = (1 << 5) | 2 = 34
  // CHECK: call i32 @llvm.v850.stsr(i32 34)
  return __builtin_v850_read_rbase();
}

// CHECK-LABEL: @test_write_rbase
void test_write_rbase(unsigned int val) {
  // enc = (1 << 5) | 2 = 34
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 34)
  __builtin_v850_write_rbase(val);
}

// CHECK-LABEL: @test_read_ebase
unsigned int test_read_ebase(void) {
  // enc = (1 << 5) | 3 = 35
  // CHECK: call i32 @llvm.v850.stsr(i32 35)
  return __builtin_v850_read_ebase();
}

// CHECK-LABEL: @test_write_ebase
void test_write_ebase(unsigned int val) {
  // enc = (1 << 5) | 3 = 35
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 35)
  __builtin_v850_write_ebase(val);
}

// CHECK-LABEL: @test_read_intbp
unsigned int test_read_intbp(void) {
  // enc = (1 << 5) | 4 = 36
  // CHECK: call i32 @llvm.v850.stsr(i32 36)
  return __builtin_v850_read_intbp();
}

// CHECK-LABEL: @test_write_intbp
void test_write_intbp(unsigned int val) {
  // enc = (1 << 5) | 4 = 36
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 36)
  __builtin_v850_write_intbp(val);
}

// CHECK-LABEL: @test_read_scbp
unsigned int test_read_scbp(void) {
  // enc = (1 << 5) | 12 = 44
  // CHECK: call i32 @llvm.v850.stsr(i32 44)
  return __builtin_v850_read_scbp();
}

// CHECK-LABEL: @test_write_scbp
void test_write_scbp(unsigned int val) {
  // enc = (1 << 5) | 12 = 44
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 44)
  __builtin_v850_write_scbp(val);
}

// === Group 2: Thread/Interrupt (selID=2) ===

// CHECK-LABEL: @test_read_mea
unsigned int test_read_mea(void) {
  // enc = (2 << 5) | 6 = 70
  // CHECK: call i32 @llvm.v850.stsr(i32 70)
  return __builtin_v850_read_mea();
}

// CHECK-LABEL: @test_write_mea
void test_write_mea(unsigned int val) {
  // enc = (2 << 5) | 6 = 70
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 70)
  __builtin_v850_write_mea(val);
}

// CHECK-LABEL: @test_read_mei
unsigned int test_read_mei(void) {
  // enc = (2 << 5) | 8 = 72
  // CHECK: call i32 @llvm.v850.stsr(i32 72)
  return __builtin_v850_read_mei();
}

// CHECK-LABEL: @test_write_mei
void test_write_mei(unsigned int val) {
  // enc = (2 << 5) | 8 = 72
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 72)
  __builtin_v850_write_mei(val);
}

// CHECK-LABEL: @test_read_ispr
unsigned int test_read_ispr(void) {
  // enc = (2 << 5) | 10 = 74
  // CHECK: call i32 @llvm.v850.stsr(i32 74)
  return __builtin_v850_read_ispr();
}

// CHECK-LABEL: @test_write_ispr
void test_write_ispr(unsigned int val) {
  // enc = (2 << 5) | 10 = 74
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 74)
  __builtin_v850_write_ispr(val);
}

// CHECK-LABEL: @test_read_pmr
unsigned int test_read_pmr(void) {
  // enc = (2 << 5) | 11 = 75
  // CHECK: call i32 @llvm.v850.stsr(i32 75)
  return __builtin_v850_read_pmr();
}

// CHECK-LABEL: @test_write_pmr
void test_write_pmr(unsigned int val) {
  // enc = (2 << 5) | 11 = 75
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 75)
  __builtin_v850_write_pmr(val);
}

// CHECK-LABEL: @test_read_icsr
unsigned int test_read_icsr(void) {
  // enc = (2 << 5) | 12 = 76
  // CHECK: call i32 @llvm.v850.stsr(i32 76)
  return __builtin_v850_read_icsr();
}

// CHECK-LABEL: @test_read_intcfg
unsigned int test_read_intcfg(void) {
  // enc = (2 << 5) | 13 = 77
  // CHECK: call i32 @llvm.v850.stsr(i32 77)
  return __builtin_v850_read_intcfg();
}

// CHECK-LABEL: @test_write_intcfg
void test_write_intcfg(unsigned int val) {
  // enc = (2 << 5) | 13 = 77
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 77)
  __builtin_v850_write_intcfg(val);
}
