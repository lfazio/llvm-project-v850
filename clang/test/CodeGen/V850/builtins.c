// RUN: %clang_cc1 -triple v850-unknown-elf -target-cpu v850e2m -emit-llvm -o - %s | FileCheck %s

//===----------------------------------------------------------------------===//
// Test V850 builtin functions
//
// This test uses v850e2m (which includes FPU by default) to test all builtins.
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Atomic Bit Operations (V850E1+)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_set1(
// CHECK: call void @llvm.v850.set1(ptr %{{.*}}, i32 %{{.*}})
void test_set1(void *addr, unsigned int bit) {
  __builtin_v850_set1(addr, bit);
}

// CHECK-LABEL: @test_clr1(
// CHECK: call void @llvm.v850.clr1(ptr %{{.*}}, i32 %{{.*}})
void test_clr1(void *addr, unsigned int bit) {
  __builtin_v850_clr1(addr, bit);
}

// CHECK-LABEL: @test_not1(
// CHECK: call void @llvm.v850.not1(ptr %{{.*}}, i32 %{{.*}})
void test_not1(void *addr, unsigned int bit) {
  __builtin_v850_not1(addr, bit);
}

// CHECK-LABEL: @test_tst1(
// CHECK: call i32 @llvm.v850.tst1(ptr %{{.*}}, i32 %{{.*}})
int test_tst1(void *addr, unsigned int bit) {
  return __builtin_v850_tst1(addr, bit);
}

//===----------------------------------------------------------------------===//
// Byte/Halfword Swap Operations (V850E1+)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_hsw(
// CHECK: call i32 @llvm.v850.hsw(i32 %{{.*}})
unsigned int test_hsw(unsigned int x) {
  return __builtin_v850_hsw(x);
}

// CHECK-LABEL: @test_bsh(
// CHECK: call i32 @llvm.v850.bsh(i32 %{{.*}})
unsigned int test_bsh(unsigned int x) {
  return __builtin_v850_bsh(x);
}

//===----------------------------------------------------------------------===//
// Memory Barrier Operations (V850E2M+)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_syncp(
// CHECK: call void @llvm.v850.syncp()
void test_syncp(void) {
  __builtin_v850_syncp();
}

// CHECK-LABEL: @test_syncm(
// CHECK: call void @llvm.v850.syncm()
void test_syncm(void) {
  __builtin_v850_syncm();
}

// CHECK-LABEL: @test_synce(
// CHECK: call void @llvm.v850.synce()
void test_synce(void) {
  __builtin_v850_synce();
}

//===----------------------------------------------------------------------===//
// Interrupt Control Operations (Base V850)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_di(
// CHECK: call void @llvm.v850.di()
void test_di(void) {
  __builtin_v850_di();
}

// CHECK-LABEL: @test_ei(
// CHECK: call void @llvm.v850.ei()
void test_ei(void) {
  __builtin_v850_ei();
}

//===----------------------------------------------------------------------===//
// System Register Access (Base V850)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_ldsr(
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 5)
void test_ldsr(unsigned int value) {
  __builtin_v850_ldsr(value, 5);  // PSW = regID 5
}

// CHECK-LABEL: @test_stsr(
// CHECK: call i32 @llvm.v850.stsr(i32 5)
unsigned int test_stsr(void) {
  return __builtin_v850_stsr(5);  // PSW = regID 5
}

//===----------------------------------------------------------------------===//
// Saturating Arithmetic Operations (Base V850)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_satadd(
// CHECK: call i32 @llvm.sadd.sat.i32(i32 %{{.*}}, i32 %{{.*}})
int test_satadd(int a, int b) {
  return __builtin_v850_satadd(a, b);
}

// CHECK-LABEL: @test_satsub(
// CHECK: call i32 @llvm.ssub.sat.i32(i32 %{{.*}}, i32 %{{.*}})
int test_satsub(int a, int b) {
  return __builtin_v850_satsub(a, b);
}

// CHECK-LABEL: @test_satsubr(
// CHECK: call i32 @llvm.v850.satsubr(i32 %{{.*}}, i32 %{{.*}})
int test_satsubr(int a, int b) {
  return __builtin_v850_satsubr(a, b);
}

//===----------------------------------------------------------------------===//
// FPU System Register Access (V850E2M+ with FPU)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_read_fpsr(
// CHECK: call i32 @llvm.v850.read.fpsr()
unsigned int test_read_fpsr(void) {
  return __builtin_v850_read_fpsr();
}

// CHECK-LABEL: @test_write_fpsr(
// CHECK: call void @llvm.v850.write.fpsr(i32 %{{.*}})
void test_write_fpsr(unsigned int val) {
  __builtin_v850_write_fpsr(val);
}

// CHECK-LABEL: @test_read_fpst(
// CHECK: call i32 @llvm.v850.read.fpst()
unsigned int test_read_fpst(void) {
  return __builtin_v850_read_fpst();
}

// CHECK-LABEL: @test_write_fpcc(
// CHECK: call void @llvm.v850.write.fpcc(i32 %{{.*}})
void test_write_fpcc(unsigned int val) {
  __builtin_v850_write_fpcc(val);
}

//===----------------------------------------------------------------------===//
// Use Case: Critical Section
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @critical_section(
// CHECK: call void @llvm.v850.di()
// CHECK: store volatile
// CHECK: call void @llvm.v850.ei()
void critical_section(volatile int *p, int val) {
  __builtin_v850_di();
  *p = val;
  __builtin_v850_ei();
}

//===----------------------------------------------------------------------===//
// Use Case: Atomic Bit Manipulation
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @set_flag(
// CHECK: call void @llvm.v850.set1(ptr %{{.*}}, i32 %{{.*}})
void set_flag(unsigned char *flags, unsigned int bit) {
  __builtin_v850_set1(flags, bit);
}

// CHECK-LABEL: @clear_flag(
// CHECK: call void @llvm.v850.clr1(ptr %{{.*}}, i32 %{{.*}})
void clear_flag(unsigned char *flags, unsigned int bit) {
  __builtin_v850_clr1(flags, bit);
}

// CHECK-LABEL: @toggle_flag(
// CHECK: call void @llvm.v850.not1(ptr %{{.*}}, i32 %{{.*}})
void toggle_flag(unsigned char *flags, unsigned int bit) {
  __builtin_v850_not1(flags, bit);
}

//===----------------------------------------------------------------------===//
// Multiply-Accumulate Operations (V850E1+)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_mac(
// CHECK: call { i32, i32 } @llvm.v850.mac(i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}})
long long test_mac(int a, int b, long long acc) {
  return __builtin_v850_mac(a, b, acc);
}

// CHECK-LABEL: @test_macu(
// CHECK: call { i32, i32 } @llvm.v850.macu(i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}})
unsigned long long test_macu(unsigned int a, unsigned int b, unsigned long long acc) {
  return __builtin_v850_macu(a, b, acc);
}

//===----------------------------------------------------------------------===//
// Named System Register Access (Base V850)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_read_eipc(
// CHECK: call i32 @llvm.v850.stsr(i32 0)
unsigned int test_read_eipc(void) {
  return __builtin_v850_read_eipc();
}

// CHECK-LABEL: @test_write_eipc(
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 0)
void test_write_eipc(unsigned int val) {
  __builtin_v850_write_eipc(val);
}

// CHECK-LABEL: @test_read_eipsw(
// CHECK: call i32 @llvm.v850.stsr(i32 1)
unsigned int test_read_eipsw(void) {
  return __builtin_v850_read_eipsw();
}

// CHECK-LABEL: @test_write_eipsw(
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 1)
void test_write_eipsw(unsigned int val) {
  __builtin_v850_write_eipsw(val);
}

// CHECK-LABEL: @test_read_fepc(
// CHECK: call i32 @llvm.v850.stsr(i32 2)
unsigned int test_read_fepc(void) {
  return __builtin_v850_read_fepc();
}

// CHECK-LABEL: @test_write_fepc(
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 2)
void test_write_fepc(unsigned int val) {
  __builtin_v850_write_fepc(val);
}

// CHECK-LABEL: @test_read_fepsw(
// CHECK: call i32 @llvm.v850.stsr(i32 3)
unsigned int test_read_fepsw(void) {
  return __builtin_v850_read_fepsw();
}

// CHECK-LABEL: @test_write_fepsw(
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 3)
void test_write_fepsw(unsigned int val) {
  __builtin_v850_write_fepsw(val);
}

// CHECK-LABEL: @test_read_ecr(
// CHECK: call i32 @llvm.v850.stsr(i32 4)
unsigned int test_read_ecr(void) {
  return __builtin_v850_read_ecr();
}

// CHECK-LABEL: @test_read_psw(
// CHECK: call i32 @llvm.v850.stsr(i32 5)
unsigned int test_read_psw(void) {
  return __builtin_v850_read_psw();
}

// CHECK-LABEL: @test_write_psw(
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 5)
void test_write_psw(unsigned int val) {
  __builtin_v850_write_psw(val);
}

//===----------------------------------------------------------------------===//
// Named System Register Access (V850E1+)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_read_ctpc(
// CHECK: call i32 @llvm.v850.stsr(i32 16)
unsigned int test_read_ctpc(void) {
  return __builtin_v850_read_ctpc();
}

// CHECK-LABEL: @test_write_ctpc(
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 16)
void test_write_ctpc(unsigned int val) {
  __builtin_v850_write_ctpc(val);
}

// CHECK-LABEL: @test_read_ctpsw(
// CHECK: call i32 @llvm.v850.stsr(i32 17)
unsigned int test_read_ctpsw(void) {
  return __builtin_v850_read_ctpsw();
}

// CHECK-LABEL: @test_write_ctpsw(
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 17)
void test_write_ctpsw(unsigned int val) {
  __builtin_v850_write_ctpsw(val);
}

// CHECK-LABEL: @test_read_ctbp(
// CHECK: call i32 @llvm.v850.stsr(i32 20)
unsigned int test_read_ctbp(void) {
  return __builtin_v850_read_ctbp();
}

// CHECK-LABEL: @test_write_ctbp(
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 20)
void test_write_ctbp(unsigned int val) {
  __builtin_v850_write_ctbp(val);
}

//===----------------------------------------------------------------------===//
// Bit Search Operations (V850E2+)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_sch1l(
// CHECK: call i32 @llvm.v850.sch1l(i32 %{{.*}})
unsigned int test_sch1l(unsigned int x) {
  return __builtin_v850_sch1l(x);
}

// CHECK-LABEL: @test_sch1r(
// CHECK: call i32 @llvm.v850.sch1r(i32 %{{.*}})
unsigned int test_sch1r(unsigned int x) {
  return __builtin_v850_sch1r(x);
}

// CHECK-LABEL: @test_sch0l(
// CHECK: call i32 @llvm.v850.sch0l(i32 %{{.*}})
unsigned int test_sch0l(unsigned int x) {
  return __builtin_v850_sch0l(x);
}

// CHECK-LABEL: @test_sch0r(
// CHECK: call i32 @llvm.v850.sch0r(i32 %{{.*}})
unsigned int test_sch0r(unsigned int x) {
  return __builtin_v850_sch0r(x);
}

//===----------------------------------------------------------------------===//
// Atomic Operations (V850E2M+)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_caxi(
// CHECK: call i32 @llvm.v850.caxi(ptr %{{.*}}, i32 %{{.*}}, i32 %{{.*}})
unsigned int test_caxi(void *addr, unsigned int expected, unsigned int desired) {
  return __builtin_v850_caxi(addr, expected, desired);
}

//===----------------------------------------------------------------------===//
// Named System Register Access (V850E2M+)
//===----------------------------------------------------------------------===//

// CHECK-LABEL: @test_read_eiwr(
// CHECK: call i32 @llvm.v850.stsr(i32 28)
unsigned int test_read_eiwr(void) {
  return __builtin_v850_read_eiwr();
}

// CHECK-LABEL: @test_write_eiwr(
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 28)
void test_write_eiwr(unsigned int val) {
  __builtin_v850_write_eiwr(val);
}

// CHECK-LABEL: @test_read_fewr(
// CHECK: call i32 @llvm.v850.stsr(i32 29)
unsigned int test_read_fewr(void) {
  return __builtin_v850_read_fewr();
}

// CHECK-LABEL: @test_write_fewr(
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 29)
void test_write_fewr(unsigned int val) {
  __builtin_v850_write_fewr(val);
}

// CHECK-LABEL: @test_read_bsel(
// CHECK: call i32 @llvm.v850.stsr(i32 31)
unsigned int test_read_bsel(void) {
  return __builtin_v850_read_bsel();
}

// CHECK-LABEL: @test_write_bsel(
// CHECK: call void @llvm.v850.ldsr(i32 %{{.*}}, i32 31)
void test_write_bsel(unsigned int val) {
  __builtin_v850_write_bsel(val);
}
