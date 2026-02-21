// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu g3m -emit-llvm -o - %s | FileCheck %s

// Test LDSR/STSR with group specification builtins for RH850G3M.
// The unified 10-bit encoding combines (selID << 5) | regID.
// Constant arguments are folded by the IR builder.

// CHECK-LABEL: @test_read_ebase
unsigned int test_read_ebase(void) {
  // enc = (1 << 5) | 3 = 35
  // CHECK: call i32 @llvm.v850.stsr(i32 35)
  return __builtin_v850_stsr_group(3, 1);
}

// CHECK-LABEL: @test_write_ebase
void test_write_ebase(unsigned int val) {
  // enc = (1 << 5) | 3 = 35
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 35)
  __builtin_v850_ldsr_group(val, 3, 1);
}

// CHECK-LABEL: @test_read_mea
unsigned int test_read_mea(void) {
  // enc = (2 << 5) | 6 = 70
  // CHECK: call i32 @llvm.v850.stsr(i32 70)
  return __builtin_v850_stsr_group(6, 2);
}

// CHECK-LABEL: @test_write_pmr
void test_write_pmr(unsigned int val) {
  // enc = (2 << 5) | 11 = 75
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 75)
  __builtin_v850_ldsr_group(val, 11, 2);
}

// CHECK-LABEL: @test_read_ispr
unsigned int test_read_ispr(void) {
  // enc = (2 << 5) | 10 = 74
  // CHECK: call i32 @llvm.v850.stsr(i32 74)
  return __builtin_v850_stsr_group(10, 2);
}

// CHECK-LABEL: @test_read_write_intbp
// Test reading and writing INTBP (regID=4, selID=1, enc=36)
unsigned int test_read_write_intbp(unsigned int val) {
  unsigned int old = __builtin_v850_stsr_group(4, 1);
  // CHECK: call i32 @llvm.v850.stsr(i32 36)
  __builtin_v850_ldsr_group(val, 4, 1);
  // CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 36)
  return old;
}
