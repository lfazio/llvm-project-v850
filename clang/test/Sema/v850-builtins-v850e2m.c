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

  // Base V850 named system register builtins
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

  // V850E1 builtins
  __builtin_v850_set1(addr, bit);
  __builtin_v850_clr1(addr, bit);
  __builtin_v850_not1(addr, bit);
  (void)__builtin_v850_tst1(addr, bit);
  (void)__builtin_v850_hsw(0);
  (void)__builtin_v850_bsh(0);

  // V850E1+ system register builtins
  (void)__builtin_v850_read_ctpc();
  __builtin_v850_write_ctpc(0);
  (void)__builtin_v850_read_ctpsw();
  __builtin_v850_write_ctpsw(0);
  (void)__builtin_v850_read_ctbp();
  __builtin_v850_write_ctbp(0);

  // V850E1+ debug system register builtins
  (void)__builtin_v850_read_dbpc();
  __builtin_v850_write_dbpc(0);
  (void)__builtin_v850_read_dbpsw();
  __builtin_v850_write_dbpsw(0);
  (void)__builtin_v850_read_dir();
  (void)__builtin_v850_read_bpc();
  __builtin_v850_write_bpc(0);
  (void)__builtin_v850_read_asid();
  __builtin_v850_write_asid(0);
  (void)__builtin_v850_read_bpav();
  __builtin_v850_write_bpav(0);
  (void)__builtin_v850_read_bpam();
  __builtin_v850_write_bpam(0);
  (void)__builtin_v850_read_bpdv();
  __builtin_v850_write_bpdv(0);
  (void)__builtin_v850_read_bpdm();
  __builtin_v850_write_bpdm(0);

  // V850E2+ exception cause register builtins
  (void)__builtin_v850_read_eiic();
  __builtin_v850_write_eiic(0);
  (void)__builtin_v850_read_feic();
  __builtin_v850_write_feic(0);

  // V850E2 bit search builtins
  (void)__builtin_v850_sch1l(0);
  (void)__builtin_v850_sch1r(0);
  (void)__builtin_v850_sch0l(0);
  (void)__builtin_v850_sch0r(0);

  // V850E2 byte/halfword swap builtins
  (void)__builtin_v850_hsh(0);

  // V850E2 3-operand saturating arithmetic builtins
  (void)__builtin_v850_satadd3(1, 2);
  (void)__builtin_v850_satsub3(1, 2);

  // V850E2M builtins
  __builtin_v850_syncp();
  __builtin_v850_syncm();
  __builtin_v850_synce();

  // V850E2M atomic builtins
  (void)__builtin_v850_caxi(addr, 0, 1);

  // V850E2M+ system register builtins
  (void)__builtin_v850_read_eiwr();
  __builtin_v850_write_eiwr(0);
  (void)__builtin_v850_read_fewr();
  __builtin_v850_write_fewr(0);
  (void)__builtin_v850_read_dbwr();
  __builtin_v850_write_dbwr(0);
  (void)__builtin_v850_read_bsel();
  __builtin_v850_write_bsel(0);

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
