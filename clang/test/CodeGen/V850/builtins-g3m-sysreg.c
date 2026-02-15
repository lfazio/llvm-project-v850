// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu g3m -emit-llvm -o - %s | FileCheck %s

// Test LDSR/STSR with group specification builtins for RH850G3M.

// CHECK-LABEL: @test_read_ebase
unsigned int test_read_ebase(void) {
  // CHECK: call i32 @llvm.v850.stsr.sel(i32 3, i32 1)
  return __builtin_v850_stsr_group(3, 1);
}

// CHECK-LABEL: @test_write_ebase
void test_write_ebase(unsigned int val) {
  // CHECK: call void @llvm.v850.ldsr.sel(i32 %{{.*}}, i32 3, i32 1)
  __builtin_v850_ldsr_group(val, 3, 1);
}

// CHECK-LABEL: @test_read_mea
unsigned int test_read_mea(void) {
  // CHECK: call i32 @llvm.v850.stsr.sel(i32 6, i32 2)
  return __builtin_v850_stsr_group(6, 2);
}

// CHECK-LABEL: @test_write_pmr
void test_write_pmr(unsigned int val) {
  // CHECK: call void @llvm.v850.ldsr.sel(i32 %{{.*}}, i32 11, i32 2)
  __builtin_v850_ldsr_group(val, 11, 2);
}

// CHECK-LABEL: @test_read_ispr
unsigned int test_read_ispr(void) {
  // CHECK: call i32 @llvm.v850.stsr.sel(i32 10, i32 2)
  return __builtin_v850_stsr_group(10, 2);
}

// CHECK-LABEL: @test_read_write_intbp
// Test reading and writing INTBP (regID=4, selID=1)
unsigned int test_read_write_intbp(unsigned int val) {
  unsigned int old = __builtin_v850_stsr_group(4, 1);
  // CHECK: call i32 @llvm.v850.stsr.sel(i32 4, i32 1)
  __builtin_v850_ldsr_group(val, 4, 1);
  // CHECK: call void @llvm.v850.ldsr.sel(i32 %{{.*}}, i32 4, i32 1)
  return old;
}
