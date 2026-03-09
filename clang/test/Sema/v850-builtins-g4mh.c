// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu g3mh -emit-llvm -verify -o /dev/null %s
// REQUIRES: v850-registered-target
//
// Test that G4MH CLIP builtins are NOT available on G3MH (requires G4MH).
// Only one error is checked because -emit-llvm stops after the first error.

int test_clip_b(int x) {
  return __builtin_v850_clip_b(x); // expected-error {{needs target feature rh850g4mh}}
}
