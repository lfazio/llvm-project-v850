/*
 * Micro-benchmark: Bitwise Operations
 *
 * Tests bit manipulation to compare instruction selection.
 */

/* Basic bitwise */
int and_i32(int a, int b) { return a & b; }
int or_i32(int a, int b) { return a | b; }
int xor_i32(int a, int b) { return a ^ b; }
int not_i32(int a) { return ~a; }

/* Shifts */
int shl_i32(int a, int n) { return a << n; }
int shr_i32(int a, int n) { return a >> n; }  /* Arithmetic shift */
unsigned lshr_u32(unsigned a, unsigned n) { return a >> n; }  /* Logical shift */

/* Shift by constant (tests immediate encoding) */
int shl_const1(int a) { return a << 1; }
int shl_const2(int a) { return a << 2; }
int shl_const3(int a) { return a << 3; }
int shl_const4(int a) { return a << 4; }
int shl_const8(int a) { return a << 8; }
int shl_const16(int a) { return a << 16; }
int shr_const1(int a) { return a >> 1; }
int shr_const8(int a) { return a >> 8; }
int shr_const16(int a) { return a >> 16; }

/* Rotate (tests HSW or synthesized rotate) */
unsigned rotl_32(unsigned a, unsigned n) {
    return (a << n) | (a >> (32 - n));
}
unsigned rotr_32(unsigned a, unsigned n) {
    return (a >> n) | (a << (32 - n));
}
unsigned rotl_16(unsigned a) { return (a << 16) | (a >> 16); }

/* Bit counting (tests SCH1L/SCH1R/SCH0L/SCH0R) */
int clz_u32(unsigned a) {
    if (a == 0) return 32;
    int n = 0;
    if (a <= 0x0000FFFF) { n += 16; a <<= 16; }
    if (a <= 0x00FFFFFF) { n += 8;  a <<= 8; }
    if (a <= 0x0FFFFFFF) { n += 4;  a <<= 4; }
    if (a <= 0x3FFFFFFF) { n += 2;  a <<= 2; }
    if (a <= 0x7FFFFFFF) { n += 1; }
    return n;
}

int ctz_u32(unsigned a) {
    if (a == 0) return 32;
    int n = 0;
    if ((a & 0x0000FFFF) == 0) { n += 16; a >>= 16; }
    if ((a & 0x000000FF) == 0) { n += 8;  a >>= 8; }
    if ((a & 0x0000000F) == 0) { n += 4;  a >>= 4; }
    if ((a & 0x00000003) == 0) { n += 2;  a >>= 2; }
    if ((a & 0x00000001) == 0) { n += 1; }
    return n;
}

int popcount_u32(unsigned a) {
    a = a - ((a >> 1) & 0x55555555);
    a = (a & 0x33333333) + ((a >> 2) & 0x33333333);
    a = (a + (a >> 4)) & 0x0F0F0F0F;
    a = a + (a >> 8);
    a = a + (a >> 16);
    return a & 0x3F;
}

int parity_u32(unsigned a) {
    a ^= a >> 16;
    a ^= a >> 8;
    a ^= a >> 4;
    a ^= a >> 2;
    a ^= a >> 1;
    return a & 1;
}

/* Byte swap (tests BSW/BSH/HSW) */
unsigned bswap_32(unsigned a) {
    return ((a & 0xFF000000) >> 24) |
           ((a & 0x00FF0000) >> 8)  |
           ((a & 0x0000FF00) << 8)  |
           ((a & 0x000000FF) << 24);
}

unsigned short bswap_16(unsigned short a) {
    return (a >> 8) | (a << 8);
}

unsigned hswap_32(unsigned a) {
    return (a >> 16) | (a << 16);
}

/* Bit field operations */
unsigned extract_bits(unsigned val, int pos, int width) {
    return (val >> pos) & ((1u << width) - 1);
}

unsigned insert_bits(unsigned val, unsigned bits, int pos, int width) {
    unsigned mask = ((1u << width) - 1) << pos;
    return (val & ~mask) | ((bits << pos) & mask);
}

int test_bit(unsigned val, int pos) {
    return (val >> pos) & 1;
}

unsigned set_bit(unsigned val, int pos) {
    return val | (1u << pos);
}

unsigned clear_bit(unsigned val, int pos) {
    return val & ~(1u << pos);
}

unsigned toggle_bit(unsigned val, int pos) {
    return val ^ (1u << pos);
}

/* Specific bit positions (tests SET1/CLR1/NOT1/TST1) */
unsigned set_bit0(unsigned val) { return val | 0x01; }
unsigned set_bit7(unsigned val) { return val | 0x80; }
unsigned set_bit15(unsigned val) { return val | 0x8000; }
unsigned set_bit31(unsigned val) { return val | 0x80000000; }

unsigned clear_bit0(unsigned val) { return val & ~0x01; }
unsigned clear_bit7(unsigned val) { return val & ~0x80; }
unsigned clear_bit31(unsigned val) { return val & ~0x80000000; }

/* Mask operations */
unsigned mask_lower_bits(unsigned val, int n) {
    return val & ((1u << n) - 1);
}

unsigned mask_upper_bits(unsigned val, int n) {
    return val & ~((1u << (32 - n)) - 1);
}

/* Find first set (ffs) */
int ffs_u32(unsigned a) {
    if (a == 0) return 0;
    int n = 1;
    if ((a & 0x0000FFFF) == 0) { n += 16; a >>= 16; }
    if ((a & 0x000000FF) == 0) { n += 8;  a >>= 8; }
    if ((a & 0x0000000F) == 0) { n += 4;  a >>= 4; }
    if ((a & 0x00000003) == 0) { n += 2;  a >>= 2; }
    if ((a & 0x00000001) == 0) { n += 1; }
    return n;
}

/* Bit reverse */
unsigned bitrev_32(unsigned a) {
    a = ((a & 0x55555555) << 1) | ((a & 0xAAAAAAAA) >> 1);
    a = ((a & 0x33333333) << 2) | ((a & 0xCCCCCCCC) >> 2);
    a = ((a & 0x0F0F0F0F) << 4) | ((a & 0xF0F0F0F0) >> 4);
    a = ((a & 0x00FF00FF) << 8) | ((a & 0xFF00FF00) >> 8);
    a = (a << 16) | (a >> 16);
    return a;
}

/* Power of 2 operations */
int is_power_of_2(unsigned a) {
    return a && !(a & (a - 1));
}

unsigned next_power_of_2(unsigned a) {
    a--;
    a |= a >> 1;
    a |= a >> 2;
    a |= a >> 4;
    a |= a >> 8;
    a |= a >> 16;
    a++;
    return a;
}
