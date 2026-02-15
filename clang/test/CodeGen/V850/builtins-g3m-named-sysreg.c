// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu g3m -emit-llvm -o - %s | FileCheck %s

// Test named builtins for RH850G3M system registers (groups 1-2).
// These expand to ldsr/stsr with the correct regID and selID.

// === Group 1: Machine Configuration ===

// CHECK-LABEL: @test_read_rbase
unsigned int test_read_rbase(void) {
  // CHECK: call i32 @llvm.v850.stsr.sel(i32 2, i32 1)
  return __builtin_v850_read_rbase();
}

// CHECK-LABEL: @test_write_rbase
void test_write_rbase(unsigned int val) {
  // CHECK: call void @llvm.v850.ldsr.sel(i32 %{{.*}}, i32 2, i32 1)
  __builtin_v850_write_rbase(val);
}

// CHECK-LABEL: @test_read_ebase
unsigned int test_read_ebase(void) {
  // CHECK: call i32 @llvm.v850.stsr.sel(i32 3, i32 1)
  return __builtin_v850_read_ebase();
}

// CHECK-LABEL: @test_write_ebase
void test_write_ebase(unsigned int val) {
  // CHECK: call void @llvm.v850.ldsr.sel(i32 %{{.*}}, i32 3, i32 1)
  __builtin_v850_write_ebase(val);
}

// CHECK-LABEL: @test_read_intbp
unsigned int test_read_intbp(void) {
  // CHECK: call i32 @llvm.v850.stsr.sel(i32 4, i32 1)
  return __builtin_v850_read_intbp();
}

// CHECK-LABEL: @test_write_intbp
void test_write_intbp(unsigned int val) {
  // CHECK: call void @llvm.v850.ldsr.sel(i32 %{{.*}}, i32 4, i32 1)
  __builtin_v850_write_intbp(val);
}

// CHECK-LABEL: @test_read_scbp
unsigned int test_read_scbp(void) {
  // CHECK: call i32 @llvm.v850.stsr.sel(i32 12, i32 1)
  return __builtin_v850_read_scbp();
}

// CHECK-LABEL: @test_write_scbp
void test_write_scbp(unsigned int val) {
  // CHECK: call void @llvm.v850.ldsr.sel(i32 %{{.*}}, i32 12, i32 1)
  __builtin_v850_write_scbp(val);
}

// === Group 2: Thread/Interrupt ===

// CHECK-LABEL: @test_read_mea
unsigned int test_read_mea(void) {
  // CHECK: call i32 @llvm.v850.stsr.sel(i32 6, i32 2)
  return __builtin_v850_read_mea();
}

// CHECK-LABEL: @test_write_mea
void test_write_mea(unsigned int val) {
  // CHECK: call void @llvm.v850.ldsr.sel(i32 %{{.*}}, i32 6, i32 2)
  __builtin_v850_write_mea(val);
}

// CHECK-LABEL: @test_read_mei
unsigned int test_read_mei(void) {
  // CHECK: call i32 @llvm.v850.stsr.sel(i32 8, i32 2)
  return __builtin_v850_read_mei();
}

// CHECK-LABEL: @test_write_mei
void test_write_mei(unsigned int val) {
  // CHECK: call void @llvm.v850.ldsr.sel(i32 %{{.*}}, i32 8, i32 2)
  __builtin_v850_write_mei(val);
}

// CHECK-LABEL: @test_read_ispr
unsigned int test_read_ispr(void) {
  // CHECK: call i32 @llvm.v850.stsr.sel(i32 10, i32 2)
  return __builtin_v850_read_ispr();
}

// CHECK-LABEL: @test_write_ispr
void test_write_ispr(unsigned int val) {
  // CHECK: call void @llvm.v850.ldsr.sel(i32 %{{.*}}, i32 10, i32 2)
  __builtin_v850_write_ispr(val);
}

// CHECK-LABEL: @test_read_pmr
unsigned int test_read_pmr(void) {
  // CHECK: call i32 @llvm.v850.stsr.sel(i32 11, i32 2)
  return __builtin_v850_read_pmr();
}

// CHECK-LABEL: @test_write_pmr
void test_write_pmr(unsigned int val) {
  // CHECK: call void @llvm.v850.ldsr.sel(i32 %{{.*}}, i32 11, i32 2)
  __builtin_v850_write_pmr(val);
}

// CHECK-LABEL: @test_read_icsr
unsigned int test_read_icsr(void) {
  // CHECK: call i32 @llvm.v850.stsr.sel(i32 12, i32 2)
  return __builtin_v850_read_icsr();
}

// CHECK-LABEL: @test_read_intcfg
unsigned int test_read_intcfg(void) {
  // CHECK: call i32 @llvm.v850.stsr.sel(i32 13, i32 2)
  return __builtin_v850_read_intcfg();
}

// CHECK-LABEL: @test_write_intcfg
void test_write_intcfg(unsigned int val) {
  // CHECK: call void @llvm.v850.ldsr.sel(i32 %{{.*}}, i32 13, i32 2)
  __builtin_v850_write_intcfg(val);
}
