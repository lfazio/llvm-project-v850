// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu g3m -emit-llvm -o - %s | FileCheck %s

// Test G3M-specific builtins

// CHECK-LABEL: @test_synci
void test_synci(void) {
  // CHECK: call void @llvm.v850.synci()
  __builtin_v850_synci();
}

// CHECK-LABEL: @test_snooze
void test_snooze(void) {
  // CHECK: call void @llvm.v850.snooze()
  __builtin_v850_snooze();
}

// CHECK-LABEL: @test_cll
void test_cll(void) {
  // CHECK: call void @llvm.v850.cll()
  __builtin_v850_cll();
}

// CHECK-LABEL: @test_ldl_w
unsigned int test_ldl_w(const unsigned int *addr) {
  // CHECK: call i32 @llvm.v850.ldl.w(ptr %{{.*}})
  return __builtin_v850_ldl_w(addr);
}

// CHECK-LABEL: @test_stc_w
int test_stc_w(unsigned int *addr, unsigned int value) {
  // CHECK: call i32 @llvm.v850.stc.w(ptr %{{.*}}, i32 %{{.*}})
  return __builtin_v850_stc_w(addr, value);
}

// CHECK-LABEL: @test_atomic_add
unsigned int test_atomic_add(unsigned int *addr, unsigned int value) {
  // This function shows how LDL/STC can be used for atomic operations
  unsigned int old;
  do {
    __builtin_v850_cll();
    old = __builtin_v850_ldl_w(addr);
  } while (!__builtin_v850_stc_w(addr, old + value));
  return old;
}
