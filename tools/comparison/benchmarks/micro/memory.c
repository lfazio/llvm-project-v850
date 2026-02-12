/*
 * Micro-benchmark: Memory Operations
 *
 * Tests load/store patterns to compare addressing modes and optimizations.
 */

#include <stddef.h>
#include <stdint.h>

/* Basic load/store */
int load_i32(const int *ptr) { return *ptr; }
void store_i32(int *ptr, int val) { *ptr = val; }

short load_i16(const short *ptr) { return *ptr; }
void store_i16(short *ptr, short val) { *ptr = val; }

char load_i8(const char *ptr) { return *ptr; }
void store_i8(char *ptr, char val) { *ptr = val; }

/* Offset access (tests displacement encoding) */
int load_offset_4(const int *ptr) { return ptr[1]; }
int load_offset_8(const int *ptr) { return ptr[2]; }
int load_offset_16(const int *ptr) { return ptr[4]; }
int load_offset_64(const int *ptr) { return ptr[16]; }
int load_offset_256(const int *ptr) { return ptr[64]; }
int load_offset_1024(const int *ptr) { return ptr[256]; }

void store_offset_4(int *ptr, int val) { ptr[1] = val; }
void store_offset_64(int *ptr, int val) { ptr[16] = val; }

/* Negative offset */
int load_neg_offset(const int *ptr) { return ptr[-1]; }
int load_neg_offset_4(const int *ptr) { return ptr[-4]; }

/* Array access patterns */
int array_sum(const int *arr, int n) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
        sum += arr[i];
    }
    return sum;
}

void array_copy(int *dst, const int *src, int n) {
    for (int i = 0; i < n; i++) {
        dst[i] = src[i];
    }
}

void array_fill(int *arr, int val, int n) {
    for (int i = 0; i < n; i++) {
        arr[i] = val;
    }
}

void array_scale(int *arr, int scale, int n) {
    for (int i = 0; i < n; i++) {
        arr[i] *= scale;
    }
}

/* Pointer arithmetic (tests post-increment addressing) */
int sum_ptr_incr(const int *ptr, int n) {
    int sum = 0;
    while (n-- > 0) {
        sum += *ptr++;
    }
    return sum;
}

void copy_ptr_incr(int *dst, const int *src, int n) {
    while (n-- > 0) {
        *dst++ = *src++;
    }
}

/* Structure access (tests field offset encoding) */
typedef struct {
    int x;
    int y;
    int z;
} Point3D;

typedef struct {
    char a;
    short b;
    int c;
    long long d;
} MixedStruct;

typedef struct {
    int arr[8];
    int count;
} ArrayStruct;

int get_point_x(const Point3D *p) { return p->x; }
int get_point_y(const Point3D *p) { return p->y; }
int get_point_z(const Point3D *p) { return p->z; }

void set_point(Point3D *p, int x, int y, int z) {
    p->x = x;
    p->y = y;
    p->z = z;
}

int get_mixed_c(const MixedStruct *m) { return m->c; }
long long get_mixed_d(const MixedStruct *m) { return m->d; }

int get_array_elem(const ArrayStruct *s, int i) { return s->arr[i]; }
int get_array_count(const ArrayStruct *s) { return s->count; }

/* Nested structure access */
typedef struct {
    Point3D position;
    Point3D velocity;
    int id;
} Particle;

int get_particle_pos_x(const Particle *p) { return p->position.x; }
int get_particle_vel_y(const Particle *p) { return p->velocity.y; }

/* Volatile access (tests memory barriers) */
volatile int global_volatile;

int read_volatile(void) {
    return global_volatile;
}

void write_volatile(int val) {
    global_volatile = val;
}

int read_modify_write_volatile(int val) {
    int old = global_volatile;
    global_volatile = val;
    return old;
}

/* Memory copy implementations */
void memcpy_bytes(void *dst, const void *src, size_t n) {
    char *d = (char *)dst;
    const char *s = (const char *)src;
    while (n-- > 0) {
        *d++ = *s++;
    }
}

void memcpy_words(void *dst, const void *src, size_t n) {
    int *d = (int *)dst;
    const int *s = (const int *)src;
    n /= 4;
    while (n-- > 0) {
        *d++ = *s++;
    }
}

void memset_bytes(void *dst, int val, size_t n) {
    char *d = (char *)dst;
    while (n-- > 0) {
        *d++ = (char)val;
    }
}

void memset_words(void *dst, int val, size_t n) {
    int *d = (int *)dst;
    n /= 4;
    while (n-- > 0) {
        *d++ = val;
    }
}

/* Memory compare */
int memcmp_bytes(const void *s1, const void *s2, size_t n) {
    const unsigned char *p1 = (const unsigned char *)s1;
    const unsigned char *p2 = (const unsigned char *)s2;
    while (n-- > 0) {
        if (*p1 != *p2) {
            return *p1 - *p2;
        }
        p1++;
        p2++;
    }
    return 0;
}

/* Unaligned access */
int load_unaligned(const char *ptr) {
    int val;
    val = (unsigned char)ptr[0];
    val |= (unsigned char)ptr[1] << 8;
    val |= (unsigned char)ptr[2] << 16;
    val |= (unsigned char)ptr[3] << 24;
    return val;
}

void store_unaligned(char *ptr, int val) {
    ptr[0] = val & 0xFF;
    ptr[1] = (val >> 8) & 0xFF;
    ptr[2] = (val >> 16) & 0xFF;
    ptr[3] = (val >> 24) & 0xFF;
}

/* Endian conversion */
int swap_endian_32(int val) {
    return ((val & 0xFF000000) >> 24) |
           ((val & 0x00FF0000) >> 8)  |
           ((val & 0x0000FF00) << 8)  |
           ((val & 0x000000FF) << 24);
}

/* Packed access */
#ifdef __GNUC__
__attribute__((packed))
#else
#pragma pack 1
#endif
typedef struct {
    char a;
    int b;
    short c;
} PackedStruct;

int get_packed_b(const PackedStruct *p) { return p->b; }
short get_packed_c(const PackedStruct *p) { return p->c; }

/* Array of structures */
typedef struct {
    int key;
    int value;
} KeyValue;

int find_key(const KeyValue *arr, int n, int key) {
    for (int i = 0; i < n; i++) {
        if (arr[i].key == key) {
            return arr[i].value;
        }
    }
    return -1;
}

/* Global variable access (tests GP-relative addressing) */
static int global_array[16];
static int global_counter;

int get_global_elem(int i) { return global_array[i]; }
void set_global_elem(int i, int val) { global_array[i] = val; }
int get_global_counter(void) { return global_counter; }
void inc_global_counter(void) { global_counter++; }
