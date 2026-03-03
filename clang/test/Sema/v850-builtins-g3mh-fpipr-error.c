// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu g3mh -emit-llvm -verify -o /dev/null %s
// REQUIRES: v850-registered-target
//
// Test that FPIPR builtins are NOT available on G3MH (FPIPR register was
// removed — FPINT exception replaces FPP/FPI on G3MH).

unsigned int test_read_fpipr(void) {
  return __builtin_v850_read_fpipr(); // expected-error {{needs target feature v850-fpipr}}
}
