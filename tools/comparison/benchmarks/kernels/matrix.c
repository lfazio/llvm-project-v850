/*
 * Computational Kernel: Matrix Operations
 *
 * Matrix algorithms commonly used in embedded systems.
 */

#include <stdint.h>

/* Matrix multiplication (naive) */
void matrix_mul_naive(int *c, const int *a, const int *b, int n) {
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            int sum = 0;
            for (int k = 0; k < n; k++) {
                sum += a[i * n + k] * b[k * n + j];
            }
            c[i * n + j] = sum;
        }
    }
}

/* Matrix multiplication (transposed B for better cache) */
void matrix_mul_transposed(int *c, const int *a, const int *bt, int n) {
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            int sum = 0;
            for (int k = 0; k < n; k++) {
                sum += a[i * n + k] * bt[j * n + k];
            }
            c[i * n + j] = sum;
        }
    }
}

/* Matrix-vector multiplication */
void matrix_vector_mul(int *y, const int *a, const int *x, int rows, int cols) {
    for (int i = 0; i < rows; i++) {
        int sum = 0;
        for (int j = 0; j < cols; j++) {
            sum += a[i * cols + j] * x[j];
        }
        y[i] = sum;
    }
}

/* Matrix transpose */
void matrix_transpose(int *dst, const int *src, int rows, int cols) {
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            dst[j * rows + i] = src[i * cols + j];
        }
    }
}

/* Matrix addition */
void matrix_add(int *c, const int *a, const int *b, int rows, int cols) {
    int n = rows * cols;
    for (int i = 0; i < n; i++) {
        c[i] = a[i] + b[i];
    }
}

/* Matrix subtraction */
void matrix_sub(int *c, const int *a, const int *b, int rows, int cols) {
    int n = rows * cols;
    for (int i = 0; i < n; i++) {
        c[i] = a[i] - b[i];
    }
}

/* Matrix scale */
void matrix_scale(int *a, int scalar, int rows, int cols) {
    int n = rows * cols;
    for (int i = 0; i < n; i++) {
        a[i] *= scalar;
    }
}

/* Matrix element-wise multiply (Hadamard product) */
void matrix_hadamard(int *c, const int *a, const int *b, int rows, int cols) {
    int n = rows * cols;
    for (int i = 0; i < n; i++) {
        c[i] = a[i] * b[i];
    }
}

/* Fixed-point 3x3 matrix multiply (common in graphics) */
void matrix_mul_3x3_q15(int16_t *c, const int16_t *a, const int16_t *b) {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            int32_t sum = 0;
            for (int k = 0; k < 3; k++) {
                sum += (int32_t)a[i * 3 + k] * b[k * 3 + j];
            }
            c[i * 3 + j] = (int16_t)((sum + 0x4000) >> 15);
        }
    }
}

/* 4x4 matrix multiply (common for transformations) */
void matrix_mul_4x4(int *c, const int *a, const int *b) {
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            c[i * 4 + j] = a[i * 4 + 0] * b[0 * 4 + j] +
                          a[i * 4 + 1] * b[1 * 4 + j] +
                          a[i * 4 + 2] * b[2 * 4 + j] +
                          a[i * 4 + 3] * b[3 * 4 + j];
        }
    }
}

/* Determinant of 2x2 matrix */
int matrix_det_2x2(const int *m) {
    return m[0] * m[3] - m[1] * m[2];
}

/* Determinant of 3x3 matrix */
int matrix_det_3x3(const int *m) {
    return m[0] * (m[4] * m[8] - m[5] * m[7]) -
           m[1] * (m[3] * m[8] - m[5] * m[6]) +
           m[2] * (m[3] * m[7] - m[4] * m[6]);
}

/* Matrix trace (sum of diagonal) */
int matrix_trace(const int *m, int n) {
    int trace = 0;
    for (int i = 0; i < n; i++) {
        trace += m[i * n + i];
    }
    return trace;
}

/* Identity matrix */
void matrix_identity(int *m, int n) {
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            m[i * n + j] = (i == j) ? 1 : 0;
        }
    }
}

/* Zero matrix */
void matrix_zero(int *m, int rows, int cols) {
    int n = rows * cols;
    for (int i = 0; i < n; i++) {
        m[i] = 0;
    }
}

/* Copy matrix */
void matrix_copy(int *dst, const int *src, int rows, int cols) {
    int n = rows * cols;
    for (int i = 0; i < n; i++) {
        dst[i] = src[i];
    }
}

/* Check if matrix is symmetric */
int matrix_is_symmetric(const int *m, int n) {
    for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
            if (m[i * n + j] != m[j * n + i]) {
                return 0;
            }
        }
    }
    return 1;
}

/* Row sum */
void matrix_row_sum(int *sums, const int *m, int rows, int cols) {
    for (int i = 0; i < rows; i++) {
        int sum = 0;
        for (int j = 0; j < cols; j++) {
            sum += m[i * cols + j];
        }
        sums[i] = sum;
    }
}

/* Column sum */
void matrix_col_sum(int *sums, const int *m, int rows, int cols) {
    for (int j = 0; j < cols; j++) {
        sums[j] = 0;
    }
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            sums[j] += m[i * cols + j];
        }
    }
}

/* Find maximum element */
int matrix_max(const int *m, int rows, int cols) {
    int max = m[0];
    int n = rows * cols;
    for (int i = 1; i < n; i++) {
        if (m[i] > max) max = m[i];
    }
    return max;
}

/* Find minimum element */
int matrix_min(const int *m, int rows, int cols) {
    int min = m[0];
    int n = rows * cols;
    for (int i = 1; i < n; i++) {
        if (m[i] < min) min = m[i];
    }
    return min;
}

