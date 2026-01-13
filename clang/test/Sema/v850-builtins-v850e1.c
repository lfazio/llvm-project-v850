// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu v850e1 -emit-llvm -verify -o /dev/null %s
// REQUIRES: v850-registered-target
// expected-no-diagnostics
//
// Test V850E1 builtins availability
//

void test_v850e1_builtins(void *addr, unsigned int bit) {
  // Base V850 builtins should work
  __builtin_v850_di();
  __builtin_v850_ei();
  __builtin_v850_ldsr(0, 5);
  (void)__builtin_v850_stsr(5);
  (void)__builtin_v850_satadd(1, 2);
  (void)__builtin_v850_satsub(1, 2);

  // V850E1 builtins should work
  __builtin_v850_set1(addr, bit);
  __builtin_v850_clr1(addr, bit);
  __builtin_v850_not1(addr, bit);
  (void)__builtin_v850_tst1(addr, bit);
  (void)__builtin_v850_hsw(0);
  (void)__builtin_v850_bsh(0);

  // V850E1 multiply-accumulate should work
  (void)__builtin_v850_mac(1, 2, 0LL);
  (void)__builtin_v850_macu(1, 2, 0ULL);
}
