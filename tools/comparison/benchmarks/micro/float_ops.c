/*
 * Micro-benchmark: Floating-Point Operations
 *
 * Tests FPU instruction selection and code generation for V850E2M+ with FPU.
 * Covers single-precision (float) and double-precision (double) arithmetic,
 * conversions, FMA, and common FP patterns.
 *
 * Compile with: -mcpu=v850e2m (requires FPU support)
 *
 * KNOWN LIMITATIONS:
 *
 * 1. [FIXED:FP_CMP] FP comparisons now work correctly. The backend generates
 *    CMPF.S + TRFSR + SETF/CMOV/BZ sequences for all FP condition codes.
 *    Note: double comparisons still go through soft-float (see #3).
 *
 * 2. [BROKEN:UINT_TO_FP] Unsigned int to float conversion (uint_to_fp) is not
 *    supported. V850 FPU only has signed CVTF.SW. Fix requires custom expansion
 *    (e.g., convert as signed + conditional adjust if negative).
 *
 * 3. [LIMITATION:DOUBLE_SOFTFLOAT] Double-precision operations use software
 *    emulation (__adddf3, __muldf3, etc.) instead of FPU instructions (ADDF.D,
 *    MULF.D). V850E2M FPU supports double-precision natively. Fix requires
 *    double-precision register pair (DR) support and ISel patterns.
 *
 * Broken patterns are commented out and marked with their tag.
 */

/*===----------------------------------------------------------------------===*/
/* Single-Precision Arithmetic (ADDF.S, SUBF.S, MULF.S, DIVF.S)             */
/*===----------------------------------------------------------------------===*/

float fadd_s(float a, float b) { return a + b; }
float fsub_s(float a, float b) { return a - b; }
float fmul_s(float a, float b) { return a * b; }
float fdiv_s(float a, float b) { return a / b; }
float fneg_s(float a) { return -a; }
float fabs_s(float a) { return __builtin_fabsf(a); }

/*===----------------------------------------------------------------------===*/
/* Double-Precision Arithmetic (ADDF.D, SUBF.D, MULF.D, DIVF.D)             */
/*===----------------------------------------------------------------------===*/

double fadd_d(double a, double b) { return a + b; }
double fsub_d(double a, double b) { return a - b; }
double fmul_d(double a, double b) { return a * b; }
double fdiv_d(double a, double b) { return a / b; }
double fneg_d(double a) { return -a; }
double fabs_d(double a) { return __builtin_fabs(a); }

/*===----------------------------------------------------------------------===*/
/* Fused Multiply-Add (MADDF.S, MSUBF.S, NMADDF.S, NMSUBF.S)               */
/*===----------------------------------------------------------------------===*/

float fmadd_s(float a, float b, float c) { return a * b + c; }
float fmsub_s(float a, float b, float c) { return a * b - c; }
float fnmadd_s(float a, float b, float c) { return -(a * b + c); }
float fnmsub_s(float a, float b, float c) { return -(a * b - c); }

/*===----------------------------------------------------------------------===*/
/* Comparison (CMPF.S + TRFSR + SETF)                                       */
/*===----------------------------------------------------------------------===*/

int fcmp_eq_s(float a, float b) { return a == b; }
int fcmp_ne_s(float a, float b) { return a != b; }
int fcmp_lt_s(float a, float b) { return a < b; }
int fcmp_le_s(float a, float b) { return a <= b; }
int fcmp_gt_s(float a, float b) { return a > b; }
int fcmp_ge_s(float a, float b) { return a >= b; }

/* [LIMITATION:DOUBLE_SOFTFLOAT] Double compare uses soft-float */
/* int fcmp_eq_d(double a, double b) { return a == b; } */

/*===----------------------------------------------------------------------===*/
/* Conditional Select on float types (CMPF.S + TRFSR + CMOV / CMP + CMOV)  */
/*===----------------------------------------------------------------------===*/

float fselect_s(float a, float b, int cond) { return cond ? a : b; }
float fmin_s(float a, float b) { return a < b ? a : b; }
float fmax_s(float a, float b) { return a > b ? a : b; }

/* [LIMITATION:DOUBLE_SOFTFLOAT] Double select uses soft-float for compare */
/* double fselect_d(double a, double b, int cond) { return cond ? a : b; } */
/* double fmin_d(double a, double b) { return a < b ? a : b; }            */
/* double fmax_d(double a, double b) { return a > b ? a : b; }            */

/*===----------------------------------------------------------------------===*/
/* Type Conversion (CVTF.*, TRNCF.*)                                         */
/*===----------------------------------------------------------------------===*/

/* Float <-> Int (signed) */
float int_to_float(int a) { return (float)a; }
int float_to_int(float a) { return (int)a; }

/* [BROKEN:UINT_TO_FP] V850 FPU only has signed CVTF.SW, no unsigned variant */
/* float uint_to_float(unsigned a) { return (float)a; }   */
/* unsigned float_to_uint(float a) { return (unsigned)a; } */

/* Double <-> Int */
double int_to_double(int a) { return (double)a; }
int double_to_int(double a) { return (int)a; }

/* Float <-> Double */
double float_to_double(float a) { return (double)a; }
float double_to_float(double a) { return (float)a; }

/* Long long <-> Float/Double */
float i64_to_float(long long a) { return (float)a; }
long long float_to_i64(float a) { return (long long)a; }
double i64_to_double(long long a) { return (double)a; }
long long double_to_i64(double a) { return (long long)a; }

/*===----------------------------------------------------------------------===*/
/* Constant Materialization                                                   */
/*===----------------------------------------------------------------------===*/

float fconst_zero(void) { return 0.0f; }
float fconst_one(void) { return 1.0f; }
float fconst_pi(void) { return 3.14159265358979f; }
float fconst_neg_one(void) { return -1.0f; }
double dconst_zero(void) { return 0.0; }
double dconst_one(void) { return 1.0; }
double dconst_pi(void) { return 3.14159265358979323846; }

/*===----------------------------------------------------------------------===*/
/* Compound Floating-Point Operations (no comparisons)                       */
/*===----------------------------------------------------------------------===*/

/* Polynomial evaluation (Horner's method) */
float poly_eval_s(float x, float a, float b, float c) {
    return (a * x + b) * x + c;
}

/* Quadratic formula component: b^2 - 4ac */
float discriminant_s(float a, float b, float c) {
    return b * b - 4.0f * a * c;
}

/* Euclidean distance squared (avoids sqrt) */
float dist_squared_s(float x1, float y1, float x2, float y2) {
    float dx = x2 - x1;
    float dy = y2 - y1;
    return dx * dx + dy * dy;
}

/* 2D dot product */
float dot2d_s(float ax, float ay, float bx, float by) {
    return ax * bx + ay * by;
}

/* 3D dot product */
float dot3d_s(float ax, float ay, float az,
              float bx, float by, float bz) {
    return ax * bx + ay * by + az * bz;
}

/* Linear interpolation (no conditional) */
float lerp_s(float a, float b, float t) {
    return a + t * (b - a);
}

/* Clamp (CMPF.S + TRFSR + CMOV) */
float clamp_s(float val, float lo, float hi) {
    if (val < lo) return lo;
    if (val > hi) return hi;
    return val;
}

/*===----------------------------------------------------------------------===*/
/* Fixed-Point <-> Float Conversion Patterns                                 */
/*===----------------------------------------------------------------------===*/

/* Q15 fixed-point to float (no comparison needed) */
float q15_to_float(short q15) {
    return (float)q15 / 32768.0f;
}

/* Float to Q15 with saturation (CMPF.S + TRFSR + CMOV) */
short float_to_q15(float f) {
    float scaled = f * 32768.0f;
    if (scaled > 32767.0f) return 32767;
    if (scaled < -32768.0f) return -32768;
    return (short)scaled;
}

/* Q31 fixed-point to float */
float q31_to_float(int q31) {
    return (float)q31 / 2147483648.0f;
}

/*===----------------------------------------------------------------------===*/
/* Array/Loop Patterns (FPU in loops, no comparisons)                        */
/*===----------------------------------------------------------------------===*/

/* Vector addition */
void vadd_s(float *dst, const float *a, const float *b, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = a[i] + b[i];
}

/* Vector subtraction */
void vsub_s(float *dst, const float *a, const float *b, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = a[i] - b[i];
}

/* Vector multiply */
void vmul_s(float *dst, const float *a, const float *b, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = a[i] * b[i];
}

/* Vector multiply-accumulate (dot product) */
float vmac_s(const float *a, const float *b, int n) {
    float acc = 0.0f;
    for (int i = 0; i < n; i++)
        acc += a[i] * b[i];
    return acc;
}

/* Vector scale */
void vscale_s(float *dst, const float *src, float scale, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = src[i] * scale;
}

/* Vector scale and add (SAXPY: y = a*x + y) */
void vsaxpy_s(float *y, const float *x, float a, int n) {
    for (int i = 0; i < n; i++)
        y[i] = a * x[i] + y[i];
}

/* Sum of array */
float vsum_s(const float *arr, int n) {
    float sum = 0.0f;
    for (int i = 0; i < n; i++)
        sum += arr[i];
    return sum;
}

/* Vector min/max (CMPF.S + TRFSR + CMOV in loop) */
float vmin_s(const float *arr, int n) {
    float min_val = arr[0];
    for (int i = 1; i < n; i++)
        if (arr[i] < min_val) min_val = arr[i];
    return min_val;
}
float vmax_s(const float *arr, int n) {
    float max_val = arr[0];
    for (int i = 1; i < n; i++)
        if (arr[i] > max_val) max_val = arr[i];
    return max_val;
}

/*===----------------------------------------------------------------------===*/
/* DSP-like Floating-Point Operations                                        */
/*===----------------------------------------------------------------------===*/

/* FIR filter (float) */
float fir_float(const float *coeffs, const float *samples, int n) {
    float acc = 0.0f;
    for (int i = 0; i < n; i++)
        acc += coeffs[i] * samples[i];
    return acc;
}

/* IIR biquad filter (float, direct form II transposed) */
typedef struct {
    float b0, b1, b2;
    float a1, a2;
    float z1, z2;
} BiquadF;

float iir_biquad_float(BiquadF *s, float input) {
    float output = s->b0 * input + s->z1;
    s->z1 = s->b1 * input - s->a1 * output + s->z2;
    s->z2 = s->b2 * input - s->a2 * output;
    return output;
}

/* Low-pass exponential moving average */
float ema_float(float prev, float curr, float alpha) {
    return prev + alpha * (curr - prev);
}

/* Second-order polynomial filter */
float poly2_filter(float x, float c0, float c1, float c2) {
    return c0 + c1 * x + c2 * x * x;
}

/*===----------------------------------------------------------------------===*/
/* Double-Precision Compound Operations                                      */
/*===----------------------------------------------------------------------===*/

/* Polynomial evaluation (double) */
double poly_eval_d(double x, double a, double b, double c) {
    return (a * x + b) * x + c;
}

/* Vector dot product (double) */
double vmac_d(const double *a, const double *b, int n) {
    double acc = 0.0;
    for (int i = 0; i < n; i++)
        acc += a[i] * b[i];
    return acc;
}

/* Linear interpolation (double) */
double lerp_d(double a, double b, double t) {
    return a + t * (b - a);
}

/* SAXPY double */
void vsaxpy_d(double *y, const double *x, double a, int n) {
    for (int i = 0; i < n; i++)
        y[i] = a * x[i] + y[i];
}

/*===----------------------------------------------------------------------===*/
/* Mixed Precision Patterns                                                  */
/*===----------------------------------------------------------------------===*/

/* Accumulate float array in double precision */
double mixed_accumulate(const float *arr, int n) {
    double sum = 0.0;
    for (int i = 0; i < n; i++)
        sum += (double)arr[i];
    return sum;
}

/* Kahan compensated summation (no comparison needed) */
float kahan_sum(const float *arr, int n) {
    float sum = 0.0f;
    float c = 0.0f;
    for (int i = 0; i < n; i++) {
        float y = arr[i] - c;
        float t = sum + y;
        c = (t - sum) - y;
        sum = t;
    }
    return sum;
}

/* Convert float array to double */
void float_arr_to_double(double *dst, const float *src, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = (double)src[i];
}

/* Convert double array to float */
void double_arr_to_float(float *dst, const double *src, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = (float)src[i];
}

/*===----------------------------------------------------------------------===*/
/* Embedded Control Patterns (no FP comparisons)                             */
/*===----------------------------------------------------------------------===*/

/* Sensor calibration: y = gain * x + offset */
float sensor_calibrate(float raw, float gain, float offset) {
    return gain * raw + offset;
}

/* Temperature conversion */
float celsius_to_fahrenheit(float c) { return c * 1.8f + 32.0f; }
float fahrenheit_to_celsius(float f) { return (f - 32.0f) / 1.8f; }

/* Voltage divider: Vout = Vin * R2 / (R1 + R2) */
float voltage_divider(float vin, float r1, float r2) {
    return vin * r2 / (r1 + r2);
}

/* Low-pass RC filter: Vout = alpha * Vin + (1-alpha) * Vout_prev */
float rc_lowpass(float vin, float vout_prev, float alpha) {
    return alpha * vin + (1.0f - alpha) * vout_prev;
}

/* PID controller with output clamping (uses FP compare + select) */
typedef struct {
    float kp, ki, kd;
    float integral, prev_error;
    float out_min, out_max;
} PIDf;

float pid_update(PIDf *pid, float error, float dt) {
    pid->integral += error * dt;
    float derivative = (error - pid->prev_error) / dt;
    pid->prev_error = error;
    float output = pid->kp * error + pid->ki * pid->integral +
                   pid->kd * derivative;
    if (output > pid->out_max) return pid->out_max;
    if (output < pid->out_min) return pid->out_min;
    return output;
}

/* PWM duty cycle with clamping */
float pwm_duty(float target, float actual, float gain, float max_duty) {
    float err = target - actual;
    float duty = err * gain;
    if (duty < 0.0f) return 0.0f;
    if (duty > max_duty) return max_duty;
    return duty;
}

/* Moving average using circular buffer */
typedef struct {
    float buffer[8];
    int index;
    float sum;
} MovAvgF;

float moving_avg_update(MovAvgF *ma, float new_val) {
    ma->sum -= ma->buffer[ma->index];
    ma->buffer[ma->index] = new_val;
    ma->sum += new_val;
    ma->index = (ma->index + 1) & 7; /* mod 8 using bitmask */
    return ma->sum * 0.125f;          /* divide by 8 */
}

/*===----------------------------------------------------------------------===*/
/* Matrix Operations (float)                                                 */
/*===----------------------------------------------------------------------===*/

/* 2x2 matrix multiply */
void mat2x2_mul_s(float *c, const float *a, const float *b) {
    c[0] = a[0] * b[0] + a[1] * b[2];
    c[1] = a[0] * b[1] + a[1] * b[3];
    c[2] = a[2] * b[0] + a[3] * b[2];
    c[3] = a[2] * b[1] + a[3] * b[3];
}

/* 3x3 matrix multiply */
void mat3x3_mul_s(float *c, const float *a, const float *b) {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            float sum = 0.0f;
            for (int k = 0; k < 3; k++)
                sum += a[i * 3 + k] * b[k * 3 + j];
            c[i * 3 + j] = sum;
        }
    }
}

/* 4x4 matrix-vector multiply */
void mat4x4_vec_mul_s(float *out, const float *m, const float *v) {
    for (int i = 0; i < 4; i++) {
        out[i] = m[i * 4 + 0] * v[0] + m[i * 4 + 1] * v[1] +
                 m[i * 4 + 2] * v[2] + m[i * 4 + 3] * v[3];
    }
}

/* Matrix transpose 4x4 */
void mat4x4_transpose_s(float *dst, const float *src) {
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 4; j++)
            dst[j * 4 + i] = src[i * 4 + j];
}

/*===----------------------------------------------------------------------===*/
/* Trigonometric Approximations (polynomial, no comparisons)                 */
/*===----------------------------------------------------------------------===*/

/* Fast sine approximation (Bhaskara I, valid for 0 <= x <= pi) */
/* sin(x) ≈ 16x(pi-x) / (5*pi^2 - 4x(pi-x)) */
float fast_sin_approx(float x) {
    float pi_f = 3.14159265f;
    float xp = x * (pi_f - x);
    return 16.0f * xp / (5.0f * pi_f * pi_f - 4.0f * xp);
}

/* Polynomial cosine approximation (minimax, valid near 0) */
/* cos(x) ≈ 1 - x^2/2 + x^4/24 */
float fast_cos_approx(float x) {
    float x2 = x * x;
    float x4 = x2 * x2;
    return 1.0f - 0.5f * x2 + 0.041666667f * x4;
}

/* Fast inverse sqrt (Newton-Raphson iteration starting from rough estimate) */
/* Given y ≈ 1/sqrt(x), refine: y = y * (1.5 - 0.5*x*y*y) */
float newton_inv_sqrt_step(float x, float y) {
    return y * (1.5f - 0.5f * x * y * y);
}

/* Exponential approximation: e^x ≈ 1 + x + x^2/2 + x^3/6 + x^4/24 */
float fast_exp_approx(float x) {
    float x2 = x * x;
    float x3 = x2 * x;
    float x4 = x2 * x2;
    return 1.0f + x + 0.5f * x2 + 0.166666667f * x3 + 0.041666667f * x4;
}

/* Natural log approximation (for x near 1): ln(1+x) ≈ x - x^2/2 + x^3/3 */
float fast_ln1p_approx(float x) {
    float x2 = x * x;
    float x3 = x2 * x;
    return x - 0.5f * x2 + 0.333333333f * x3;
}
