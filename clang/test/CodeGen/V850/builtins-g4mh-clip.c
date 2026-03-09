// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu g4mh -emit-llvm -o - %s | FileCheck %s
// REQUIRES: v850-registered-target

// CLIP.B - Clamp signed value to byte range [-128, 127]
int test_clip_b(int x) {
  // CHECK-LABEL: @test_clip_b
  // CHECK: call i32 @llvm.v850.clip.b(i32 %{{.*}})
  return __builtin_v850_clip_b(x);
}

// CLIP.BU - Clamp value to unsigned byte range [0, 255]
unsigned int test_clip_bu(int x) {
  // CHECK-LABEL: @test_clip_bu
  // CHECK: call i32 @llvm.v850.clip.bu(i32 %{{.*}})
  return __builtin_v850_clip_bu(x);
}

// CLIP.H - Clamp signed value to halfword range [-32768, 32767]
int test_clip_h(int x) {
  // CHECK-LABEL: @test_clip_h
  // CHECK: call i32 @llvm.v850.clip.h(i32 %{{.*}})
  return __builtin_v850_clip_h(x);
}

// CLIP.HU - Clamp value to unsigned halfword range [0, 65535]
unsigned int test_clip_hu(int x) {
  // CHECK-LABEL: @test_clip_hu
  // CHECK: call i32 @llvm.v850.clip.hu(i32 %{{.*}})
  return __builtin_v850_clip_hu(x);
}
