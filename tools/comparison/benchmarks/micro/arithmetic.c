/*
 * Micro-benchmark: Integer Arithmetic Operations
 *
 * Tests basic arithmetic operations to compare instruction selection.
 */

/* Basic arithmetic */
int add_i32(int a, int b) { return a + b; }
int sub_i32(int a, int b) { return a - b; }
int mul_i32(int a, int b) { return a * b; }
int div_i32(int a, int b) { return a / b; }
int mod_i32(int a, int b) { return a % b; }
int neg_i32(int a) { return -a; }

/* Unsigned arithmetic */
unsigned add_u32(unsigned a, unsigned b) { return a + b; }
unsigned sub_u32(unsigned a, unsigned b) { return a - b; }
unsigned mul_u32(unsigned a, unsigned b) { return a * b; }
unsigned div_u32(unsigned a, unsigned b) { return a / b; }
unsigned mod_u32(unsigned a, unsigned b) { return a % b; }

/* 64-bit arithmetic (tests multi-register operations) */
long long add_i64(long long a, long long b) { return a + b; }
long long sub_i64(long long a, long long b) { return a - b; }
long long mul_i64(long long a, long long b) { return a * b; }
long long div_i64(long long a, long long b) { return a / b; }

/* Mixed width operations */
long long mul_i32_to_i64(int a, int b) { return (long long)a * b; }
unsigned long long mul_u32_to_u64(unsigned a, unsigned b) {
    return (unsigned long long)a * b;
}

/* Multiply-accumulate (tests MAC instruction) */
long long mac_i32(int a, int b, long long acc) {
    return acc + (long long)a * b;
}
unsigned long long macu_i32(unsigned a, unsigned b, unsigned long long acc) {
    return acc + (unsigned long long)a * b;
}

/* Compound operations */
int add_mul(int a, int b, int c) { return a + b * c; }
int sub_mul(int a, int b, int c) { return a - b * c; }
int mul_add(int a, int b, int c) { return a * b + c; }

/* Immediate operations */
int add_imm5(int a) { return a + 5; }
int add_imm16(int a) { return a + 1000; }
int add_imm32(int a) { return a + 100000; }
int mul_imm2(int a) { return a * 2; }
int mul_imm3(int a) { return a * 3; }
int mul_imm4(int a) { return a * 4; }
int mul_imm5(int a) { return a * 5; }
int mul_imm7(int a) { return a * 7; }
int mul_imm8(int a) { return a * 8; }
int mul_imm10(int a) { return a * 10; }

/* Division by constant (tests strength reduction) */
int div_const2(int a) { return a / 2; }
int div_const3(int a) { return a / 3; }
int div_const4(int a) { return a / 4; }
int div_const5(int a) { return a / 5; }
int div_const7(int a) { return a / 7; }
int div_const10(int a) { return a / 10; }
int div_const100(int a) { return a / 100; }
unsigned udiv_const3(unsigned a) { return a / 3; }
unsigned udiv_const10(unsigned a) { return a / 10; }

/* Modulo by constant */
int mod_const2(int a) { return a % 2; }
int mod_const4(int a) { return a % 4; }
int mod_const8(int a) { return a % 8; }
unsigned umod_const3(unsigned a) { return a % 3; }

/* Saturating arithmetic (tests SATADD/SATSUB) */
/* Use builtins — manual overflow checks on signed int are UB in C and get
   optimized away, resulting in plain add/sub instead of satadd/satsub. */
int sat_add(int a, int b) {
    return __builtin_v850_satadd(a, b);
}

int sat_sub(int a, int b) {
    return __builtin_v850_satsub(a, b);
}

/* Absolute value */
int abs_i32(int a) { return (a < 0) ? -a : a; }
int abs_branchless(int a) {
    int mask = a >> 31;
    return (a + mask) ^ mask;
}

/* Min/Max */
int min_i32(int a, int b) { return (a < b) ? a : b; }
int max_i32(int a, int b) { return (a > b) ? a : b; }
unsigned min_u32(unsigned a, unsigned b) { return (a < b) ? a : b; }
unsigned max_u32(unsigned a, unsigned b) { return (a > b) ? a : b; }

/* Sign extension (tests SXB/SXH) */
int sign_extend_8(char a) { return a; }
int sign_extend_16(short a) { return a; }

/* Zero extension (tests ZXB/ZXH) */
unsigned zero_extend_8(unsigned char a) { return a; }
unsigned zero_extend_16(unsigned short a) { return a; }
