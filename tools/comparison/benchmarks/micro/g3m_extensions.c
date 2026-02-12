/*
 * Micro-benchmark: RH850G3M Extension Instructions
 *
 * Tests code generation for instructions introduced in the RH850G3M variant.
 * Compile with: -mcpu=g3m
 *
 * New G3M instructions tested:
 *   - ROTL (rotate left, immediate and register)
 *   - BINS (bitfield insert, 3 encoding variants)
 *   - LD.DW / ST.DW (64-bit load/store, 48-bit encoding)
 *   - LOOP (hardware loop with branch prediction)
 *   - PUSHSP / POPSP (bulk register save/restore)
 *   - CACHE / PREF (cache control and prefetch)
 *   - SYNCI (instruction synchronization)
 *   - SNOOZE (low-power wait)
 *   - CLL (clear load link)
 *   - LDL.W / STC.W (load-linked/store-conditional)
 *   - Bcond disp17 (extended branch displacement)
 */

#include <stdint.h>

/*=========================================================================
 * Section 1: Rotate operations
 *
 * G3M introduces ROTL instruction (both immediate and register forms).
 * Standard C rotate idiom should map to ROTL on G3M, HSW for 16-bit
 * rotation on earlier CPUs.
 *=========================================================================*/

/* Rotate left by constant - should use ROTL imm5 */
unsigned rotl_1(unsigned x) { return (x << 1) | (x >> 31); }
unsigned rotl_3(unsigned x) { return (x << 3) | (x >> 29); }
unsigned rotl_7(unsigned x) { return (x << 7) | (x >> 25); }
unsigned rotl_8(unsigned x) { return (x << 8) | (x >> 24); }
unsigned rotl_15(unsigned x) { return (x << 15) | (x >> 17); }
unsigned rotl_16(unsigned x) { return (x << 16) | (x >> 16); } /* HSW on E1+ */
unsigned rotl_24(unsigned x) { return (x << 24) | (x >> 8); }
unsigned rotl_31(unsigned x) { return (x << 31) | (x >> 1); }

/* Rotate left by variable - should use ROTL reg on G3M */
unsigned rotl_var(unsigned x, unsigned n) {
    return (x << n) | (x >> (32 - n));
}

/* Rotate right by constant (synthesized from ROTL with 32-n) */
unsigned rotr_1(unsigned x) { return (x >> 1) | (x << 31); }
unsigned rotr_8(unsigned x) { return (x >> 8) | (x << 24); }

/* Rotate right by variable */
unsigned rotr_var(unsigned x, unsigned n) {
    return (x >> n) | (x << (32 - n));
}

/* Practical rotate use: CRC step */
unsigned crc_rotate_step(unsigned crc, unsigned data) {
    crc ^= data;
    for (int i = 0; i < 8; i++) {
        if (crc & 1)
            crc = (crc >> 1) ^ 0xEDB88320u;
        else
            crc >>= 1;
    }
    return crc;
}

/*=========================================================================
 * Section 2: Bitfield insert operations
 *
 * G3M introduces BINS instruction for efficient bitfield insertion.
 * The compiler should recognize insert_bits patterns and use BINS.
 * Three encoding variants: BINS0 (msb >= 16, lsb >= 16),
 *   BINS1 (msb >= 16, lsb < 16), BINS2 (msb < 16, lsb < 16).
 *=========================================================================*/

/* Insert a field into a value: val[pos+width-1:pos] = bits[width-1:0] */
unsigned insert_field(unsigned val, unsigned bits, unsigned pos,
                      unsigned width) {
    unsigned mask = ((1u << width) - 1) << pos;
    return (val & ~mask) | ((bits << pos) & mask);
}

/* Fixed-position inserts (should map to BINS with known lsb/msb) */
unsigned insert_byte0(unsigned val, unsigned byte) {
    return (val & 0xFFFFFF00u) | (byte & 0xFF);
}

unsigned insert_byte1(unsigned val, unsigned byte) {
    return (val & 0xFFFF00FFu) | ((byte & 0xFF) << 8);
}

unsigned insert_byte2(unsigned val, unsigned byte) {
    return (val & 0xFF00FFFFu) | ((byte & 0xFF) << 16);
}

unsigned insert_byte3(unsigned val, unsigned byte) {
    return (val & 0x00FFFFFFu) | ((byte & 0xFF) << 24);
}

/* Insert halfword */
unsigned insert_lo16(unsigned val, unsigned hw) {
    return (val & 0xFFFF0000u) | (hw & 0xFFFF);
}

unsigned insert_hi16(unsigned val, unsigned hw) {
    return (val & 0x0000FFFFu) | (hw << 16);
}

/* Automotive CAN-style signal packing (common embedded pattern) */
/* Pack RPM (12 bits at [11:0]) and gear (4 bits at [15:12]) */
unsigned pack_engine_status(unsigned rpm, unsigned gear) {
    unsigned val = 0;
    val = (val & ~0x0FFFu) | (rpm & 0x0FFF);
    val = (val & ~0xF000u) | ((gear & 0xF) << 12);
    return val;
}

/* Pack temperature (8 bits at [23:16]) into existing status */
unsigned pack_temperature(unsigned status, unsigned temp) {
    return (status & ~0x00FF0000u) | ((temp & 0xFF) << 16);
}

/* Multi-field pack (tests multiple BINS in sequence) */
unsigned pack_sensor_data(unsigned pressure, unsigned temp, unsigned status_bits,
                          unsigned seq) {
    unsigned word = 0;
    word |= (pressure & 0x3FF);            /* bits [9:0] */
    word |= (temp & 0x3FF) << 10;          /* bits [19:10] */
    word |= (status_bits & 0xF) << 20;     /* bits [23:20] */
    word |= (seq & 0xFF) << 24;            /* bits [31:24] */
    return word;
}

/* Extract + modify + insert (read-modify-write on bitfield) */
unsigned update_field_4_8(unsigned val, unsigned new_bits) {
    /* Update bits [11:4] */
    return (val & ~0x0FF0u) | ((new_bits & 0xFF) << 4);
}

/*=========================================================================
 * Section 3: 64-bit load/store patterns
 *
 * G3M introduces LD.DW (load double word) and ST.DW (store double word)
 * for efficient 64-bit memory access in a single instruction.
 * These are 48-bit (6-byte) instructions that cannot dual-issue.
 *=========================================================================*/

/* 64-bit load/store via struct */
typedef struct {
    uint32_t lo;
    uint32_t hi;
} pair64_t;

uint64_t load_i64(const uint64_t *ptr) { return *ptr; }
void store_i64(uint64_t *ptr, uint64_t val) { *ptr = val; }

/* 64-bit array access */
void copy_i64_array(uint64_t *dst, const uint64_t *src, int n) {
    for (int i = 0; i < n; i++) {
        dst[i] = src[i];
    }
}

/* 64-bit pair operations (common for timestamps, counters) */
pair64_t load_pair(const pair64_t *p) { return *p; }
void store_pair(pair64_t *p, pair64_t val) { *p = val; }

/* Structure with mixed 32-bit and 64-bit fields */
typedef struct {
    uint32_t id;
    uint64_t timestamp;
    uint32_t flags;
} event_t;

uint64_t get_event_timestamp(const event_t *e) { return e->timestamp; }

void set_event_timestamp(event_t *e, uint64_t ts) { e->timestamp = ts; }

void copy_event(event_t *dst, const event_t *src) { *dst = *src; }

/* 64-bit counter pattern */
uint64_t load_counter(const volatile uint64_t *cnt) { return *cnt; }

/* Double-word aligned buffer copy (should prefer LD.DW/ST.DW) */
void copy_aligned_64(uint64_t *dst, const uint64_t *src, int count) {
    while (count-- > 0) {
        *dst++ = *src++;
    }
}

/*=========================================================================
 * Section 4: Loop patterns
 *
 * G3M introduces the LOOP instruction for hardware-assisted loops.
 * The LOOP instruction has branch prediction, making tight loops faster.
 * Pattern: LOOP reg, disp16 (decrement reg, branch if non-zero)
 *=========================================================================*/

/* Simple counted loop (ideal LOOP candidate) */
int sum_array(const int *arr, int n) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
        sum += arr[i];
    }
    return sum;
}

/* Tight loop - memset-like (LOOP + ST.W) */
void fill_array(int *arr, int val, int n) {
    for (int i = 0; i < n; i++) {
        arr[i] = val;
    }
}

/* Counted loop with body (LOOP optimization) */
void scale_array(int *arr, int factor, int n) {
    for (int i = 0; i < n; i++) {
        arr[i] *= factor;
    }
}

/* Nested counted loop */
int matrix_trace(const int *m, int n) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
        sum += m[i * n + i];
    }
    return sum;
}

/* Countdown loop (natural fit for LOOP instruction) */
void countdown_fill(int *arr, int n) {
    int i = n;
    while (i-- > 0) {
        arr[i] = i;
    }
}

/*=========================================================================
 * Section 5: Functions with many callee-saved registers
 *
 * G3M PUSHSP/POPSP can save/restore register ranges more efficiently
 * than individual ST.W/LD.W or PREPARE/DISPOSE for non-standard ranges.
 * These patterns stress callee-saved register usage.
 *=========================================================================*/

/* Force use of many callee-saved registers */
int many_regs(int a, int b, int c, int d) {
    int r20 = a + 1;
    int r21 = b + 2;
    int r22 = c + 3;
    int r23 = d + 4;
    int r24 = a * 2;
    int r25 = b * 3;
    int r26 = c * 4;
    int r27 = d * 5;
    int r28 = a + b;

    /* Use all values to prevent optimization */
    return r20 + r21 + r22 + r23 + r24 + r25 + r26 + r27 + r28;
}

/* Deep call chain (tests PREPARE/DISPOSE vs PUSHSP/POPSP) */
int __attribute__((noinline)) deep_callee(int a, int b, int c, int d) {
    return a * b + c * d;
}

int deep_caller(int x) {
    int a = x + 1, b = x + 2, c = x + 3, d = x + 4;
    int e = x + 5, f = x + 6, g = x + 7, h = x + 8;
    int r1 = deep_callee(a, b, c, d);
    int r2 = deep_callee(e, f, g, h);
    return r1 + r2 + a + b + c + d + e + f + g + h;
}

/*=========================================================================
 * Section 6: Cache and prefetch patterns
 *
 * G3M introduces CACHE (cache operations) and PREF (prefetch hint).
 * PREF is user-accessible; CACHE requires supervisor mode.
 *=========================================================================*/

/* Array traversal with prefetch hint pattern */
/* Note: without __builtin_v850_prefetch, compiler may insert PREF
 * via __builtin_prefetch if the target supports it */
int sum_with_prefetch(const int *arr, int n) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
        /* Prefetch next cache line (64 bytes ahead = 16 ints) */
        if (i + 16 < n)
            __builtin_prefetch(&arr[i + 16], 0, 3);
        sum += arr[i];
    }
    return sum;
}

/*=========================================================================
 * Section 7: G3M-specific intrinsics
 *=========================================================================*/

#if defined(__v850__) && defined(__rh850g3m__)

/* Instruction synchronization (after code modification) */
void g3m_instruction_sync(void) {
    __builtin_v850_synci();
}

/* Low-power wait for interrupt */
void g3m_snooze(void) {
    __builtin_v850_snooze();
}

/* Clear exclusive monitor */
void g3m_clear_link(void) {
    __builtin_v850_cll();
}

/* LDL.W / STC.W basic operations */
unsigned g3m_load_linked(volatile unsigned *ptr) {
    return __builtin_v850_ldl_w(ptr);
}

int g3m_store_conditional(volatile unsigned *ptr, unsigned val) {
    return __builtin_v850_stc_w(ptr, val);
}

/* Combined LL/SC pattern: atomic swap */
unsigned g3m_atomic_swap(volatile unsigned *ptr, unsigned new_val) {
    unsigned old;
    int ok;
    do {
        old = __builtin_v850_ldl_w(ptr);
        ok = __builtin_v850_stc_w(ptr, new_val);
    } while (!ok);
    return old;
}

/* LL/SC with CLL for early abort */
unsigned g3m_atomic_cmpswap(volatile unsigned *ptr, unsigned expected,
                            unsigned desired) {
    unsigned old;
    int ok;
    do {
        old = __builtin_v850_ldl_w(ptr);
        if (old != expected) {
            __builtin_v850_cll();
            return old;
        }
        ok = __builtin_v850_stc_w(ptr, desired);
    } while (!ok);
    return old;
}

/* Sequence: synci after code patching */
void g3m_patch_code(volatile unsigned *code_addr, unsigned new_insn) {
    *code_addr = new_insn;
    __builtin_v850_syncp();  /* Ensure store completes */
    __builtin_v850_synci();  /* Flush instruction pipeline */
}

/* Low-power spin wait pattern */
void g3m_wait_for_interrupt(volatile int *flag) {
    while (!*flag) {
        __builtin_v850_snooze();  /* Low-power wait */
    }
}

#endif /* __v850__ && __rh850g3m__ */

/*=========================================================================
 * Section 8: Extended branch displacement patterns
 *
 * G3M Bcond disp17 allows conditional branches to reach ±64KB
 * (vs ±256 bytes for standard Bcond disp9).
 * These functions have enough code between branch and target to
 * potentially need the extended displacement.
 *=========================================================================*/

/* Large function with distant branch target */
int large_function(int *arr, int n, int threshold) {
    int count = 0;
    int sum = 0;
    int min_val = arr[0];
    int max_val = arr[0];

    for (int i = 0; i < n; i++) {
        int val = arr[i];

        /* Multiple operations to increase code size between branches */
        if (val > threshold) {
            count++;
            sum += val;
            if (val > max_val) max_val = val;
        } else {
            sum -= val;
            if (val < min_val) min_val = val;
        }

        /* More work to push branch targets further apart */
        arr[i] = val * 2 + count;
    }

    return sum + count + min_val + max_val;
}

/*=========================================================================
 * Section 9: V850E2M barrier intrinsics (available on E2M and G3M)
 *=========================================================================*/

#if defined(__v850__) && defined(__v850e2m__)

void e2m_pipeline_sync(void) { __builtin_v850_syncp(); }
void e2m_memory_sync(void) { __builtin_v850_syncm(); }
void e2m_exception_sync(void) { __builtin_v850_synce(); }

/* Barrier pattern: store + fence + signal */
void e2m_write_release(volatile int *data, volatile int *flag, int value) {
    *data = value;
    __builtin_v850_syncp();  /* Full barrier */
    *flag = 1;
}

int e2m_read_acquire(volatile int *flag, volatile int *data) {
    while (!*flag)
        ;
    __builtin_v850_syncp();  /* Full barrier */
    return *data;
}

#endif /* __v850__ && __v850e2m__ */
