// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu v850 -DTEST_V850E1_ON_BASE -emit-llvm -verify -o /dev/null %s
// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu v850 -DTEST_V850E2M_ON_BASE -emit-llvm -verify -o /dev/null %s
// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu v850e1 -DTEST_V850E2M_ON_E1 -emit-llvm -verify -o /dev/null %s
// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu v850 -DTEST_FPU_ON_BASE -emit-llvm -verify -o /dev/null %s
// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu v850 -DTEST_V850E1_SYSREG_ON_BASE -emit-llvm -verify -o /dev/null %s
// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu v850 -DTEST_V850E2M_SYSREG_ON_BASE -emit-llvm -verify -o /dev/null %s
// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu v850e1 -DTEST_V850E2M_SYSREG_ON_E1 -emit-llvm -verify -o /dev/null %s
// REQUIRES: v850-registered-target
//
// Test that V850 builtins are rejected when the required features are not present.
// Each RUN line tests a specific feature requirement.
//

#ifdef TEST_V850E1_ON_BASE
// Test that V850E1 builtins fail on base V850
void test_set1(void *addr, unsigned int bit) {
  __builtin_v850_set1(addr, bit); // expected-error {{'__builtin_v850_set1' needs target feature v850e1}}
}
#endif

#ifdef TEST_V850E2M_ON_BASE
// Test that V850E2M builtins fail on base V850
void test_syncp(void) {
  __builtin_v850_syncp(); // expected-error {{'__builtin_v850_syncp' needs target feature v850e2m}}
}
#endif

#ifdef TEST_V850E2M_ON_E1
// Test that V850E2M builtins fail on V850E1
void test_syncp(void) {
  __builtin_v850_syncp(); // expected-error {{'__builtin_v850_syncp' needs target feature v850e2m}}
}
#endif

#ifdef TEST_FPU_ON_BASE
// Test that FPU builtins fail without FPU feature
void test_fpsr(void) {
  (void)__builtin_v850_read_fpsr(); // expected-error {{'__builtin_v850_read_fpsr' needs target feature v850fpu}}
}
#endif

#ifdef TEST_V850E1_SYSREG_ON_BASE
// Test that V850E1+ system register builtins fail on base V850
void test_ctpc(void) {
  (void)__builtin_v850_read_ctpc(); // expected-error {{'__builtin_v850_read_ctpc' needs target feature v850e1}}
}
#endif

#ifdef TEST_V850E2M_SYSREG_ON_BASE
// Test that V850E2M+ system register builtins fail on base V850
void test_eiwr(void) {
  (void)__builtin_v850_read_eiwr(); // expected-error {{'__builtin_v850_read_eiwr' needs target feature v850e2m}}
}
#endif

#ifdef TEST_V850E2M_SYSREG_ON_E1
// Test that V850E2M+ system register builtins fail on V850E1
void test_bsel(void) {
  __builtin_v850_write_bsel(0); // expected-error {{'__builtin_v850_write_bsel' needs target feature v850e2m}}
}
#endif
