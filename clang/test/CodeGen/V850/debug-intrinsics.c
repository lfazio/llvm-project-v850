// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu v850e2m -emit-llvm %s -o - | FileCheck %s

// Test debug intrinsics for V850.
// These intrinsics provide access to debug functionality including:
// - DBTRAP instruction for software breakpoints
// - Debug system register access (DBPC, DBPSW, DIR, BPC, etc.)
// - Breakpoint register access (BPAV, BPAM, BPDV, BPDM)

//===----------------------------------------------------------------------===//
// DBTRAP - Debug Trap (Software Breakpoint)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_dbtrap
// CHECK: call void @llvm.v850.dbtrap()
void test_dbtrap(void) {
  __builtin_v850_dbtrap();
}

//===----------------------------------------------------------------------===//
// Debug System Register Access
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_read_dbpc
// CHECK: call i32 @llvm.v850.stsr(i32 18)
unsigned int test_read_dbpc(void) {
  return __builtin_v850_read_dbpc();
}

// CHECK-LABEL: @test_write_dbpc
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 18)
void test_write_dbpc(unsigned int val) {
  __builtin_v850_write_dbpc(val);
}

// CHECK-LABEL: @test_read_dbpsw
// CHECK: call i32 @llvm.v850.stsr(i32 19)
unsigned int test_read_dbpsw(void) {
  return __builtin_v850_read_dbpsw();
}

// CHECK-LABEL: @test_write_dbpsw
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 19)
void test_write_dbpsw(unsigned int val) {
  __builtin_v850_write_dbpsw(val);
}

// CHECK-LABEL: @test_read_dir
// CHECK: call i32 @llvm.v850.stsr(i32 21)
unsigned int test_read_dir(void) {
  return __builtin_v850_read_dir();
}

//===----------------------------------------------------------------------===//
// Breakpoint Control Register Access
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_read_bpc
// CHECK: call i32 @llvm.v850.stsr(i32 22)
unsigned int test_read_bpc(void) {
  return __builtin_v850_read_bpc();
}

// CHECK-LABEL: @test_write_bpc
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 22)
void test_write_bpc(unsigned int val) {
  __builtin_v850_write_bpc(val);
}

// CHECK-LABEL: @test_read_bpav
// CHECK: call i32 @llvm.v850.stsr(i32 24)
unsigned int test_read_bpav(void) {
  return __builtin_v850_read_bpav();
}

// CHECK-LABEL: @test_write_bpav
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 24)
void test_write_bpav(unsigned int val) {
  __builtin_v850_write_bpav(val);
}

// CHECK-LABEL: @test_read_bpam
// CHECK: call i32 @llvm.v850.stsr(i32 25)
unsigned int test_read_bpam(void) {
  return __builtin_v850_read_bpam();
}

// CHECK-LABEL: @test_write_bpam
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 25)
void test_write_bpam(unsigned int val) {
  __builtin_v850_write_bpam(val);
}

// CHECK-LABEL: @test_read_bpdv
// CHECK: call i32 @llvm.v850.stsr(i32 26)
unsigned int test_read_bpdv(void) {
  return __builtin_v850_read_bpdv();
}

// CHECK-LABEL: @test_write_bpdv
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 26)
void test_write_bpdv(unsigned int val) {
  __builtin_v850_write_bpdv(val);
}

// CHECK-LABEL: @test_read_bpdm
// CHECK: call i32 @llvm.v850.stsr(i32 27)
unsigned int test_read_bpdm(void) {
  return __builtin_v850_read_bpdm();
}

// CHECK-LABEL: @test_write_bpdm
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 27)
void test_write_bpdm(unsigned int val) {
  __builtin_v850_write_bpdm(val);
}

//===----------------------------------------------------------------------===//
// Example: Setting up a hardware breakpoint
//===----------------------------------------------------------------------===//

// This example shows how to set up a hardware breakpoint at a specific address.
// CHECK-LABEL: @setup_address_breakpoint
void setup_address_breakpoint(unsigned int addr, unsigned int mask) {
  // Write breakpoint address and mask
  __builtin_v850_write_bpav(addr);
  __builtin_v850_write_bpam(mask);

  // Enable the breakpoint (BPC bit 0 = enable address breakpoint)
  unsigned int bpc = __builtin_v850_read_bpc();
  bpc |= 0x1;
  __builtin_v850_write_bpc(bpc);
}
