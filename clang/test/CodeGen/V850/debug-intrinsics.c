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

// CHECK-LABEL: @test_write_dir
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 21)
void test_write_dir(unsigned int val) {
  __builtin_v850_write_dir(val);
}

//===----------------------------------------------------------------------===//
// Breakpoint Channel Selection
//===----------------------------------------------------------------------===//

// V850E1+ has 2 breakpoint channels selected via DIR.CS bit (bit 0).
// select_bp_channel performs read-modify-write on DIR to set/clear CS bit.

// CHECK-LABEL: @test_select_bp_channel
// CHECK: [[DIR:%.*]] = call i32 @llvm.v850.stsr(i32 21)
// CHECK: [[CMP:%.*]] = icmp eq i32 %{{.*}}, 0
// CHECK: [[CLEARED:%.*]] = and i32 [[DIR]], -2
// CHECK: [[SET:%.*]] = or i32 [[DIR]], 1
// CHECK: [[NEWDIR:%.*]] = select i1 [[CMP]], i32 [[CLEARED]], i32 [[SET]]
// CHECK: call void @llvm.v850.ldsr(i32 [[NEWDIR]], i32 21)
void test_select_bp_channel(unsigned int channel) {
  __builtin_v850_select_bp_channel(channel);
}

// CHECK-LABEL: @test_select_channel_0
// CHECK: call i32 @llvm.v850.stsr(i32 21)
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 21)
void test_select_channel_0(void) {
  __builtin_v850_select_bp_channel(0);
}

// CHECK-LABEL: @test_select_channel_1
// CHECK: call i32 @llvm.v850.stsr(i32 21)
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 21)
void test_select_channel_1(void) {
  __builtin_v850_select_bp_channel(1);
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

//===----------------------------------------------------------------------===//
// Example: Setting up a breakpoint on channel 1
//===----------------------------------------------------------------------===//

// This example shows how to set up a hardware breakpoint on channel 1.
// V850E1+ has 2 breakpoint channels (0 and 1) selected via DIR.CS bit.
// CHECK-LABEL: @setup_breakpoint_channel1
void setup_breakpoint_channel1(unsigned int addr, unsigned int mask) {
  // Select breakpoint channel 1
  __builtin_v850_select_bp_channel(1);

  // Write breakpoint address and mask (applies to selected channel)
  __builtin_v850_write_bpav(addr);
  __builtin_v850_write_bpam(mask);

  // Enable the breakpoint
  unsigned int bpc = __builtin_v850_read_bpc();
  bpc |= 0x1;
  __builtin_v850_write_bpc(bpc);

  // Switch back to channel 0 if needed
  __builtin_v850_select_bp_channel(0);
}
