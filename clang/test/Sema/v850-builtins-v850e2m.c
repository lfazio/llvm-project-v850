// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu v850e2m -emit-llvm -verify -o /dev/null %s
// REQUIRES: v850-registered-target
// expected-no-diagnostics
//
// Test that all V850 builtins are available on V850E2M (which includes FPU by default)
//

void test_all_builtins(void *addr, unsigned int bit) {
  // Base V850 builtins
  __builtin_v850_di();
  __builtin_v850_ei();
  __builtin_v850_ldsr(0, 5);
  (void)__builtin_v850_stsr(5);
  (void)__builtin_v850_satadd(1, 2);
  (void)__builtin_v850_satsub(1, 2);

  // V850E1 builtins
  __builtin_v850_set1(addr, bit);
  __builtin_v850_clr1(addr, bit);
  __builtin_v850_not1(addr, bit);
  (void)__builtin_v850_tst1(addr, bit);
  (void)__builtin_v850_hsw(0);
  (void)__builtin_v850_bsh(0);

  // V850E2M builtins
  __builtin_v850_syncp();
  __builtin_v850_syncm();
  __builtin_v850_synce();

  // FPU builtins (V850E2M includes FPU by default)
  (void)__builtin_v850_read_fpsr();
  (void)__builtin_v850_read_fpepc();
  (void)__builtin_v850_read_fpst();
  (void)__builtin_v850_read_fpcc();
  (void)__builtin_v850_read_fpcfg();
  (void)__builtin_v850_read_fpec();
  __builtin_v850_write_fpsr(0);
  __builtin_v850_write_fpepc(0);
  __builtin_v850_write_fpst(0);
  __builtin_v850_write_fpcc(0);
  __builtin_v850_write_fpcfg(0);
  __builtin_v850_write_fpec(0);
}
