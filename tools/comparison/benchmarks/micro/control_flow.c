/*
 * Micro-benchmark: Control Flow
 *
 * Tests branching and control flow to compare code generation.
 */

/* Simple conditionals (tests CMOV vs branch) */
int select_gt(int a, int b, int x, int y) {
    return (a > b) ? x : y;
}

int select_eq(int a, int b, int x, int y) {
    return (a == b) ? x : y;
}

int select_ne(int a, int b, int x, int y) {
    return (a != b) ? x : y;
}

int select_lt(int a, int b, int x, int y) {
    return (a < b) ? x : y;
}

unsigned select_ugt(unsigned a, unsigned b, unsigned x, unsigned y) {
    return (a > b) ? x : y;
}

/* Chained conditions */
int clamp(int val, int lo, int hi) {
    if (val < lo) return lo;
    if (val > hi) return hi;
    return val;
}

int clamp_ternary(int val, int lo, int hi) {
    return (val < lo) ? lo : (val > hi) ? hi : val;
}

/* Multiple comparisons */
int in_range(int val, int lo, int hi) {
    return val >= lo && val <= hi;
}

int classify_value(int val) {
    if (val < 0) return -1;
    if (val == 0) return 0;
    if (val < 10) return 1;
    if (val < 100) return 2;
    return 3;
}

/* Switch statements (tests jump table vs cascaded branches) */
int switch_small(int x) {
    switch (x) {
    case 0: return 10;
    case 1: return 20;
    case 2: return 30;
    case 3: return 40;
    default: return 0;
    }
}

int switch_medium(int x) {
    switch (x) {
    case 0: return 100;
    case 1: return 101;
    case 2: return 102;
    case 3: return 103;
    case 4: return 104;
    case 5: return 105;
    case 6: return 106;
    case 7: return 107;
    default: return 0;
    }
}

int switch_sparse(int x) {
    switch (x) {
    case 0:   return 1;
    case 10:  return 2;
    case 100: return 3;
    case 1000: return 4;
    default: return 0;
    }
}

int switch_chars(char c) {
    switch (c) {
    case 'a': return 1;
    case 'b': return 2;
    case 'c': return 3;
    case 'd': return 4;
    case 'e': return 5;
    default: return 0;
    }
}

/* Loops */
int sum_loop(int n) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
        sum += i;
    }
    return sum;
}

int sum_while(int n) {
    int sum = 0;
    int i = 0;
    while (i < n) {
        sum += i;
        i++;
    }
    return sum;
}

int sum_do_while(int n) {
    if (n <= 0) return 0;
    int sum = 0;
    int i = 0;
    do {
        sum += i;
        i++;
    } while (i < n);
    return sum;
}

int countdown(int n) {
    int sum = 0;
    while (n > 0) {
        sum += n;
        n--;
    }
    return sum;
}

/* Nested loops */
int nested_loops(int m, int n) {
    int sum = 0;
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) {
            sum += i * j;
        }
    }
    return sum;
}

/* Loop with break/continue */
int find_first_nonzero(const int *arr, int n) {
    for (int i = 0; i < n; i++) {
        if (arr[i] != 0) {
            return i;
        }
    }
    return -1;
}

int count_nonzero(const int *arr, int n) {
    int count = 0;
    for (int i = 0; i < n; i++) {
        if (arr[i] == 0) continue;
        count++;
    }
    return count;
}

/* Recursion */
int factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
}

int fibonacci(int n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

/* Tail recursion (tests tail call optimization) */
static int factorial_tail_helper(int n, int acc) {
    if (n <= 1) return acc;
    return factorial_tail_helper(n - 1, n * acc);
}

int factorial_tail(int n) {
    return factorial_tail_helper(n, 1);
}

/* Boolean operations */
int and_cond(int a, int b) { return a && b; }
int or_cond(int a, int b) { return a || b; }
int not_cond(int a) { return !a; }

int complex_cond(int a, int b, int c) {
    return (a > 0 && b < 10) || (c == 0);
}

/* Null pointer checks */
int safe_deref(const int *ptr) {
    return ptr ? *ptr : 0;
}

/* SASF pattern (shift-and-add with sign flag) */
int sasf_pattern(int a, int b, int x) {
    int bit = (a > b) ? 1 : 0;
    return (x << 1) | bit;
}

int sasf_pattern2(int cond, int x) {
    return (x << 1) | (cond != 0);
}
