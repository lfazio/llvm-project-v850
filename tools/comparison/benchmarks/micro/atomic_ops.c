/*
 * Micro-benchmark: Atomic Operations
 *
 * Compares stdatomic (C11) patterns vs G3M LL/SC intrinsics.
 *
 * On V850E2M: atomics use CAXI (compare-and-exchange instruction).
 * On RH850G3M: atomics SHOULD use LDL.W/STC.W (load-linked/store-conditional)
 *   but currently also use CAXI. The G3M intrinsics section demonstrates the
 *   more efficient LL/SC approach.
 *
 * Key instructions tested:
 *   V850E2M: CAXI, SYNCP, SYNCM, SYNCE
 *   RH850G3M: LDL.W, STC.W, CLL, SYNCI (+ all V850E2M instructions)
 */

#include <stdatomic.h>
#include <stdint.h>

/*=========================================================================
 * Section 1: C11 stdatomic operations
 *
 * These should generate CAXI-based loops on V850E2M.
 * On G3M, they COULD use LDL.W/STC.W but currently don't.
 *=========================================================================*/

/* Basic atomic load/store */
int atomic_load_i32(const atomic_int *p) {
    return atomic_load_explicit(p, memory_order_acquire);
}

void atomic_store_i32(atomic_int *p, int val) {
    atomic_store_explicit(p, val, memory_order_release);
}

/* Atomic read-modify-write operations */
int atomic_add_i32(atomic_int *p, int val) {
    return atomic_fetch_add_explicit(p, val, memory_order_seq_cst);
}

int atomic_sub_i32(atomic_int *p, int val) {
    return atomic_fetch_sub_explicit(p, val, memory_order_seq_cst);
}

int atomic_and_i32(atomic_int *p, int val) {
    return atomic_fetch_and_explicit(p, val, memory_order_seq_cst);
}

int atomic_or_i32(atomic_int *p, int val) {
    return atomic_fetch_or_explicit(p, val, memory_order_seq_cst);
}

int atomic_xor_i32(atomic_int *p, int val) {
    return atomic_fetch_xor_explicit(p, val, memory_order_seq_cst);
}

int atomic_exchange_i32(atomic_int *p, int val) {
    return atomic_exchange_explicit(p, val, memory_order_seq_cst);
}

/* Compare-and-swap */
int atomic_cas_i32(atomic_int *p, int expected, int desired) {
    atomic_compare_exchange_strong_explicit(p, &expected, desired,
                                            memory_order_seq_cst,
                                            memory_order_seq_cst);
    return expected;
}

/* Weak CAS (may fail spuriously - natural fit for LL/SC) */
int atomic_cas_weak_i32(atomic_int *p, int expected, int desired) {
    atomic_compare_exchange_weak_explicit(p, &expected, desired,
                                          memory_order_seq_cst,
                                          memory_order_seq_cst);
    return expected;
}

/* Memory ordering variants */
int atomic_add_relaxed(atomic_int *p, int val) {
    return atomic_fetch_add_explicit(p, val, memory_order_relaxed);
}

int atomic_add_acquire(atomic_int *p, int val) {
    return atomic_fetch_add_explicit(p, val, memory_order_acquire);
}

int atomic_add_release(atomic_int *p, int val) {
    return atomic_fetch_add_explicit(p, val, memory_order_release);
}

int atomic_add_acq_rel(atomic_int *p, int val) {
    return atomic_fetch_add_explicit(p, val, memory_order_acq_rel);
}

/* Memory fences */
void fence_acquire(void) { atomic_thread_fence(memory_order_acquire); }
void fence_release(void) { atomic_thread_fence(memory_order_release); }
void fence_acq_rel(void) { atomic_thread_fence(memory_order_acq_rel); }
void fence_seq_cst(void) { atomic_thread_fence(memory_order_seq_cst); }

/*=========================================================================
 * Section 2: Lock-free data structure patterns
 *
 * These patterns are common in embedded RTOS and demonstrate where
 * LL/SC would be more efficient than CAXI.
 *=========================================================================*/

/* Spinlock using atomic exchange */
void spinlock_acquire(atomic_int *lock) {
    while (atomic_exchange_explicit(lock, 1, memory_order_acquire) != 0) {
        /* spin */
    }
}

void spinlock_release(atomic_int *lock) {
    atomic_store_explicit(lock, 0, memory_order_release);
}

/* Ticket lock */
struct ticket_lock {
    atomic_uint next_ticket;
    atomic_uint now_serving;
};

void ticket_lock_acquire(struct ticket_lock *lock) {
    unsigned my_ticket = atomic_fetch_add_explicit(&lock->next_ticket, 1,
                                                    memory_order_relaxed);
    while (atomic_load_explicit(&lock->now_serving, memory_order_acquire) !=
           my_ticket) {
        /* spin */
    }
}

void ticket_lock_release(struct ticket_lock *lock) {
    unsigned current = atomic_load_explicit(&lock->now_serving,
                                             memory_order_relaxed);
    atomic_store_explicit(&lock->now_serving, current + 1,
                          memory_order_release);
}

/* Atomic counter with saturation */
int atomic_inc_saturate(atomic_int *p, int max_val) {
    int old;
    do {
        old = atomic_load_explicit(p, memory_order_relaxed);
        if (old >= max_val) return old;
    } while (!atomic_compare_exchange_weak_explicit(p, &old, old + 1,
                                                     memory_order_seq_cst,
                                                     memory_order_relaxed));
    return old;
}

/* Lock-free stack push (singly-linked) */
struct node {
    struct node *next;
    int data;
};

void lockfree_push(atomic_uintptr_t *head, struct node *new_node) {
    uintptr_t old_head;
    do {
        old_head = atomic_load_explicit(head, memory_order_relaxed);
        new_node->next = (struct node *)old_head;
    } while (!atomic_compare_exchange_weak_explicit(
        head, &old_head, (uintptr_t)new_node, memory_order_release,
        memory_order_relaxed));
}

struct node *lockfree_pop(atomic_uintptr_t *head) {
    uintptr_t old_head;
    struct node *node;
    do {
        old_head = atomic_load_explicit(head, memory_order_acquire);
        node = (struct node *)old_head;
        if (!node) return (void *)0;
    } while (!atomic_compare_exchange_weak_explicit(
        head, &old_head, (uintptr_t)node->next, memory_order_relaxed,
        memory_order_relaxed));
    return node;
}

/*=========================================================================
 * Section 3: G3M LL/SC intrinsics (RH850G3M+ only)
 *
 * These directly use LDL.W/STC.W instructions, bypassing the CAXI path.
 * Compile with -mcpu=g3m to enable.
 *
 * An LL/SC retry loop is typically 4 instructions vs 6 for CAXI:
 *   LL/SC: ldl.w + op + stc.w + bz   (4 insns per iteration)
 *   CAXI:  ld.w + op + caxi + setf + mov + bnz  (6 insns per iteration)
 *=========================================================================*/

#if defined(__v850__) && defined(__rh850g3m__)

/* Manual atomic add using LDL.W/STC.W */
int g3m_atomic_add(volatile int *ptr, int val) {
    int old, tmp, success;
    do {
        old = __builtin_v850_ldl_w((volatile unsigned int *)ptr);
        tmp = old + val;
        success = __builtin_v850_stc_w((volatile unsigned int *)ptr,
                                        (unsigned int)tmp);
    } while (!success);
    return old;
}

/* Manual atomic sub using LDL.W/STC.W */
int g3m_atomic_sub(volatile int *ptr, int val) {
    int old, tmp, success;
    do {
        old = __builtin_v850_ldl_w((volatile unsigned int *)ptr);
        tmp = old - val;
        success = __builtin_v850_stc_w((volatile unsigned int *)ptr,
                                        (unsigned int)tmp);
    } while (!success);
    return old;
}

/* Manual atomic OR using LDL.W/STC.W */
int g3m_atomic_or(volatile int *ptr, int val) {
    int old, tmp, success;
    do {
        old = __builtin_v850_ldl_w((volatile unsigned int *)ptr);
        tmp = old | val;
        success = __builtin_v850_stc_w((volatile unsigned int *)ptr,
                                        (unsigned int)tmp);
    } while (!success);
    return old;
}

/* Manual atomic AND using LDL.W/STC.W */
int g3m_atomic_and(volatile int *ptr, int val) {
    int old, tmp, success;
    do {
        old = __builtin_v850_ldl_w((volatile unsigned int *)ptr);
        tmp = old & val;
        success = __builtin_v850_stc_w((volatile unsigned int *)ptr,
                                        (unsigned int)tmp);
    } while (!success);
    return old;
}

/* Manual atomic exchange using LDL.W/STC.W */
int g3m_atomic_exchange(volatile int *ptr, int val) {
    int old, success;
    do {
        old = __builtin_v850_ldl_w((volatile unsigned int *)ptr);
        success = __builtin_v850_stc_w((volatile unsigned int *)ptr,
                                        (unsigned int)val);
    } while (!success);
    return old;
}

/* Manual CAS using LDL.W/STC.W (strong) */
int g3m_atomic_cas(volatile int *ptr, int expected, int desired) {
    int old, success;
    do {
        old = __builtin_v850_ldl_w((volatile unsigned int *)ptr);
        if (old != expected) {
            __builtin_v850_cll();  /* Clear link without storing */
            return old;
        }
        success = __builtin_v850_stc_w((volatile unsigned int *)ptr,
                                        (unsigned int)desired);
    } while (!success);
    return old;
}

/* Spinlock using LDL.W/STC.W (more efficient than CAXI exchange) */
void g3m_spinlock_acquire(volatile int *lock) {
    int success;
    do {
        while (__builtin_v850_ldl_w((volatile unsigned int *)lock) != 0) {
            /* spin - wait for lock to be released */
        }
        /* Try to acquire: ldl.w already done by while check above,
         * but we need a fresh ldl.w for the stc.w */
        (void)__builtin_v850_ldl_w((volatile unsigned int *)lock);
        success = __builtin_v850_stc_w((volatile unsigned int *)lock, 1);
    } while (!success);
}

void g3m_spinlock_release(volatile int *lock) {
    *lock = 0;
    __builtin_v850_syncp();  /* Ensure store is visible */
}

/* Atomic increment with max check using CLL for early exit */
int g3m_atomic_inc_max(volatile int *ptr, int max_val) {
    int old, success;
    do {
        old = __builtin_v850_ldl_w((volatile unsigned int *)ptr);
        if (old >= max_val) {
            __builtin_v850_cll();  /* Clear link - don't store */
            return old;
        }
        success = __builtin_v850_stc_w((volatile unsigned int *)ptr,
                                        (unsigned int)(old + 1));
    } while (!success);
    return old;
}

/* Atomic min/max using LDL.W/STC.W */
int g3m_atomic_max(volatile int *ptr, int val) {
    int old, success;
    do {
        old = __builtin_v850_ldl_w((volatile unsigned int *)ptr);
        if (old >= val) {
            __builtin_v850_cll();
            return old;
        }
        success = __builtin_v850_stc_w((volatile unsigned int *)ptr,
                                        (unsigned int)val);
    } while (!success);
    return old;
}

/*=========================================================================
 * Section 4: G3M memory barrier intrinsics
 *=========================================================================*/

/* Instruction synchronization (e.g., after self-modifying code) */
void g3m_synci(void) { __builtin_v850_synci(); }

/* Clear load link (release exclusive monitor without storing) */
void g3m_cll(void) { __builtin_v850_cll(); }

#endif /* __v850__ && __rh850g3m__ */

/*=========================================================================
 * Section 5: V850E2M barrier intrinsics (available on both E2M and G3M)
 *=========================================================================*/

#if defined(__v850__) && defined(__v850e2m__)

void barrier_syncp(void) { __builtin_v850_syncp(); }
void barrier_syncm(void) { __builtin_v850_syncm(); }
void barrier_synce(void) { __builtin_v850_synce(); }

#endif /* __v850__ && __v850e2m__ */
