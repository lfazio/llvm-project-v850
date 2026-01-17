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

  // Base V850 named system registers should work
  (void)__builtin_v850_read_eipc();
  __builtin_v850_write_eipc(0);
  (void)__builtin_v850_read_eipsw();
  __builtin_v850_write_eipsw(0);
  (void)__builtin_v850_read_fepc();
  __builtin_v850_write_fepc(0);
  (void)__builtin_v850_read_fepsw();
  __builtin_v850_write_fepsw(0);
  (void)__builtin_v850_read_ecr();
  (void)__builtin_v850_read_psw();
  __builtin_v850_write_psw(0);

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

  // V850E1+ system register builtins should work
  (void)__builtin_v850_read_ctpc();
  __builtin_v850_write_ctpc(0);
  (void)__builtin_v850_read_ctpsw();
  __builtin_v850_write_ctpsw(0);
  (void)__builtin_v850_read_ctbp();
  __builtin_v850_write_ctbp(0);
}
