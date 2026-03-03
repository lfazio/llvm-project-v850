// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu g3m -emit-llvm -verify -o /dev/null %s
// REQUIRES: v850-registered-target
// expected-no-diagnostics
//
// Test that FPIPR builtins are available on G3M (FPIPR exists on G3M).

unsigned int test_read_fpipr(void) {
  return __builtin_v850_read_fpipr();
}

void test_write_fpipr(unsigned int val) {
  __builtin_v850_write_fpipr(val);
}
