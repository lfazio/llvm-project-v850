// RUN: %clang_cc1 -triple v850 -target-cpu v850e2m -emit-llvm -o - %s | FileCheck %s

// Test FPU code generation from C

// CHECK-LABEL: define{{.*}} float @test_fadd
float test_fadd(float a, float b) {
  // CHECK: fadd float
  return a + b;
}

// CHECK-LABEL: define{{.*}} float @test_fsub
float test_fsub(float a, float b) {
  // CHECK: fsub float
  return a - b;
}

// CHECK-LABEL: define{{.*}} float @test_fmul
float test_fmul(float a, float b) {
  // CHECK: fmul float
  return a * b;
}

// CHECK-LABEL: define{{.*}} float @test_fdiv
float test_fdiv(float a, float b) {
  // CHECK: fdiv float
  return a / b;
}

// CHECK-LABEL: define{{.*}} float @test_fneg
float test_fneg(float a) {
  // CHECK: fneg float
  return -a;
}

// CHECK-LABEL: define{{.*}} float @test_sitofp
float test_sitofp(int a) {
  // CHECK: sitofp i32 {{.*}} to float
  return (float)a;
}

// CHECK-LABEL: define{{.*}} i32 @test_fptosi
int test_fptosi(float a) {
  // CHECK: fptosi float {{.*}} to i32
  return (int)a;
}
