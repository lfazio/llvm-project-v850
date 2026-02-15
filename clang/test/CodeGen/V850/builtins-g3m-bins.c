// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu g3m -emit-llvm -o - %s | FileCheck %s

// Test BINS builtin for RH850G3M.

// CHECK-LABEL: @test_bins_byte
unsigned int test_bins_byte(unsigned int dst, unsigned int src) {
  // CHECK: call i32 @llvm.v850.bins(i32 %{{.*}}, i32 %{{.*}}, i32 0, i32 8)
  return __builtin_v850_bins(dst, src, 0, 8);
}

// CHECK-LABEL: @test_bins_nibble
unsigned int test_bins_nibble(unsigned int dst, unsigned int src) {
  // CHECK: call i32 @llvm.v850.bins(i32 %{{.*}}, i32 %{{.*}}, i32 4, i32 4)
  return __builtin_v850_bins(dst, src, 4, 4);
}

// CHECK-LABEL: @test_bins_high
unsigned int test_bins_high(unsigned int dst, unsigned int src) {
  // CHECK: call i32 @llvm.v850.bins(i32 %{{.*}}, i32 %{{.*}}, i32 24, i32 8)
  return __builtin_v850_bins(dst, src, 24, 8);
}

// CHECK-LABEL: @test_bins_protocol_field
// Typical embedded use: insert a protocol field into a message register
unsigned int test_bins_protocol_field(unsigned int reg, unsigned int field) {
  // Insert 3-bit field at position 5
  // CHECK: call i32 @llvm.v850.bins(i32 %{{.*}}, i32 %{{.*}}, i32 5, i32 3)
  return __builtin_v850_bins(reg, field, 5, 3);
}
