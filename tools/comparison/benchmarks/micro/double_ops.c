/*
 * Micro-benchmark: Double-Precision Floating-Point Operations
 *
 * Tests double-precision (f64) FPU instruction selection and code generation
 * for V850E2M+ with FPU.  Covers all V850 double-precision instruction classes:
 *
 *   ADDF.D   SUBF.D   MULF.D   DIVF.D
 *   ABSF.D   NEGF.D   SQRTF.D  RECIPF.D  RSQRTF.D
 *   MADDF.D  MSUBF.D  NMADDF.D NMSUBF.D
 *   CMPF.D + TRFSR + SETF/CMOV/BZ
 *   CVTF.WD  CVTF.DW  CVTF.SD  CVTF.DS
 *   TRNCF.DW CEILF.DW FLOORF.DW ROUNDF.DW
 *   TRNCF.DUW CEILF.DUW FLOORF.DUW ROUNDF.DUW
 *
 * Compile with: -mcpu=v850e2m (requires FPU + DPR register-pair support)
 *
 * CURRENT STATUS (LLVM as of initial DPR register-pair implementation):
 *
 * All double-precision operations currently fall back to soft-float library
 * calls (__adddf3, __muldf3, etc.) in LLVM because the ISel patterns that
 * connect the double FPU instructions (ADDF.D, MULF.D, ...) to LLVM IR nodes
 * (fadd f64, fmul f64, ...) have not been added to V850InstrInfo.td yet.
 * The instructions are encoded and the assembler/disassembler work correctly
 * (MC layer), but V850ISelLowering.cpp does not mark f64 operations as Legal.
 *
 * This makes the benchmark immediately useful for comparison:
 *   CCRH  → native ADDF.D, MULF.D, CMPF.D, CVTF.WD, ... (hardware FPU)
 *   LLVM  → __adddf3, __muldf3, __eqdf2, __floatsidf, ... (soft-float)
 *
 * The diff in instruction count and cycle estimates directly quantifies the
 * gap that a follow-on ISel patch must close.
 *
 * REMAINING LIMITATIONS EVEN AFTER ISel PATTERNS ARE ADDED:
 *
 * 1. [LIMITATION:I64_TO_DOUBLE] long long -> double (CVTF.LD) and
 *    double -> long long (TRNCF.DL / CEILF.DL / ...) will likely still use
 *    soft-float because V850 ISel for i64 operations is not fully lowered.
 *    Functions: i64_to_double(), double_to_i64(), pid_step_d() inner mul.
 *
 * 2. [LIMITATION:UINT_TO_DOUBLE] Unsigned int32 <-> double (CVTF.UWD,
 *    TRNCF.DUW) — LLVM's UINT_TO_FP expansion for f64 may reuse the float
 *    path rather than emitting the dedicated unsigned-conversion instructions.
 *    CCRH emits native CVTF.UWD / TRNCF.DUW directly.
 *    Functions: u32_to_double(), double_to_u32().
 *
 * 3. [LIMITATION:RECIPF] RECIPF.D and RSQRTF.D are only generated with
 *    -ffast-math.  Without it LLVM emits fdiv 1.0, a which is IEEE-correct
 *    but slower.  CCRH may still use RECIPF.D with -Ospeed.
 *    Functions: drecip(), drsqrt().
 *
 * Functions that should produce identical machine code once ISel is in place
 * are good candidates for regression tracking after the ISel patch lands.
 */

/*===----------------------------------------------------------------------===*/
/* Basic Arithmetic (ADDF.D, SUBF.D, MULF.D, DIVF.D, ABSF.D, NEGF.D)       */
/*===----------------------------------------------------------------------===*/

double dadd(double a, double b) { return a + b; }
double dsub(double a, double b) { return a - b; }
double dmul(double a, double b) { return a * b; }
double ddiv(double a, double b) { return a / b; }
double dneg(double a) { return -a; }
double dabs(double a) { return __builtin_fabs(a); }

/*===----------------------------------------------------------------------===*/
/* Square Root / Reciprocal (SQRTF.D, RECIPF.D, RSQRTF.D)                   */
/*===----------------------------------------------------------------------===*/

double dsqrt(double a) { return __builtin_sqrt(a); }

/* [LIMITATION:RECIPF] Requires -ffast-math for native RECIPF.D / RSQRTF.D. */
/* Without fast-math, LLVM emits fdiv 1.0, a and fdiv 1.0, sqrt(a). */
double drecip(double a) { return 1.0 / a; }
double drsqrt(double a) { return 1.0 / __builtin_sqrt(a); }

/*===----------------------------------------------------------------------===*/
/* Fused Multiply-Add (MADDF.D, MSUBF.D, NMADDF.D, NMSUBF.D)               */
/*===----------------------------------------------------------------------===*/

/* a * b + c  ->  MADDF.D  */
double dfmadd(double a, double b, double c) { return __builtin_fma(a, b, c); }

/* a * b - c  ->  MSUBF.D  */
double dfmsub(double a, double b, double c) { return __builtin_fma(a, b, -c); }

/* -(a * b) + c  ->  NMADDF.D  (= c - a*b) */
double dfnmadd(double a, double b, double c) { return __builtin_fma(-a, b, c); }

/* -(a * b) - c  ->  NMSUBF.D  (= -(a*b + c)) */
double dfnmsub(double a, double b, double c) {
    return -__builtin_fma(a, b, c);
}

/* Without __builtin_fma: compiler may or may not contract to FMA. */
double dfmadd_contract(double a, double b, double c) { return a * b + c; }
double dfmsub_contract(double a, double b, double c) { return a * b - c; }

/*===----------------------------------------------------------------------===*/
/* Comparison (CMPF.D + TRFSR + SETF/BZ)                                    */
/*===----------------------------------------------------------------------===*/

int dcmp_eq(double a, double b) { return a == b; }
int dcmp_ne(double a, double b) { return a != b; }
int dcmp_lt(double a, double b) { return a < b; }
int dcmp_le(double a, double b) { return a <= b; }
int dcmp_gt(double a, double b) { return a > b; }
int dcmp_ge(double a, double b) { return a >= b; }

/* IEEE ordered / unordered checks */
int dcmp_ordered(double a, double b)   { return a == a && b == b; }
int dcmp_unordered(double a, double b) { return a != a || b != b; }

/*===----------------------------------------------------------------------===*/
/* Conditional Select / Min / Max (CMPF.D + TRFSR + CMOV or BZ)             */
/*===----------------------------------------------------------------------===*/

/* Ternary on integer condition — integer CMOV selects the pointer/value */
double dselect(double a, double b, int cond) { return cond ? a : b; }

/* FP-comparison-driven select: CMPF.D + TRFSR + conditional branch */
double dmin(double a, double b) { return a < b ? a : b; }
double dmax(double a, double b) { return a > b ? a : b; }
double dclamp(double val, double lo, double hi) {
    if (val < lo) return lo;
    if (val > hi) return hi;
    return val;
}
double dabs_val(double a) { return a >= 0.0 ? a : -a; }

/*===----------------------------------------------------------------------===*/
/* Type Conversion: int32 <-> double (CVTF.WD, TRNCF.DW, CEILF.DW, ...)    */
/*===----------------------------------------------------------------------===*/

/* int32 -> double: CVTF.WD */
double i32_to_double(int a)          { return (double)a; }

/* double -> int32 (truncation toward zero): TRNCF.DW */
int double_to_i32(double a)          { return (int)a; }

/* Explicit rounding modes — V850 has dedicated instructions for each: */
/* CEILF.DW, FLOORF.DW, ROUNDF.DW, TRNCF.DW */
int double_ceil_i32(double a)        { return (int)__builtin_ceil(a); }
int double_floor_i32(double a)       { return (int)__builtin_floor(a); }
int double_round_i32(double a)       { return (int)__builtin_round(a); }
int double_trunc_i32(double a)       { return (int)__builtin_trunc(a); }

/* Unsigned int32 -> double: CVTF.UWD */
/* [LIMITATION:UINT_TO_DOUBLE] LLVM may emit soft-float for this */
double u32_to_double(unsigned a)     { return (double)a; }
unsigned double_to_u32(double a)     { return (unsigned)a; }

/* [LIMITATION:I64_TO_DOUBLE] int64 conversions use soft-float in LLVM */
double i64_to_double(long long a)    { return (double)a; }
long long double_to_i64(double a)    { return (long long)a; }

/*===----------------------------------------------------------------------===*/
/* Type Conversion: float <-> double (CVTF.SD, CVTF.DS)                     */
/*===----------------------------------------------------------------------===*/

/* float -> double: CVTF.SD */
double float_to_double(float a)      { return (double)a; }

/* double -> float: CVTF.DS */
float double_to_float(double a)      { return (float)a; }

/* Round-trip */
double float_roundtrip(double a)     { return (double)(float)a; }

/*===----------------------------------------------------------------------===*/
/* Constant Materialization                                                   */
/*===----------------------------------------------------------------------===*/

/* These require a constant pool load (MOVHI + MOVEA + LD.W pair) because
 * V850 has no immediate-to-FPU-register instruction.
 * CCRH places constants in .sdata; LLVM uses .rodata by default. */
double dconst_zero(void)   { return 0.0; }
double dconst_one(void)    { return 1.0; }
double dconst_neg_one(void){ return -1.0; }
double dconst_half(void)   { return 0.5; }
double dconst_two(void)    { return 2.0; }
double dconst_pi(void)     { return 3.14159265358979323846; }
double dconst_e(void)      { return 2.71828182845904523536; }

/*===----------------------------------------------------------------------===*/
/* Compound Arithmetic Patterns                                               */
/*===----------------------------------------------------------------------===*/

/* Horner's method for polynomial: ((a*x + b)*x + c)*x + d */
double poly3_d(double x, double a, double b, double c, double d) {
    return ((a * x + b) * x + c) * x + d;
}

/* Discriminant: b^2 - 4ac */
double discriminant_d(double a, double b, double c) {
    return b * b - 4.0 * a * c;
}

/* Euclidean distance squared */
double dist2_d(double x1, double y1, double x2, double y2) {
    double dx = x2 - x1;
    double dy = y2 - y1;
    return dx * dx + dy * dy;
}

/* 3D distance squared */
double dist3_d(double x1, double y1, double z1,
               double x2, double y2, double z2) {
    double dx = x2 - x1;
    double dy = y2 - y1;
    double dz = z2 - z1;
    return dx * dx + dy * dy + dz * dz;
}

/* 2D dot product */
double dot2_d(double ax, double ay, double bx, double by) {
    return ax * bx + ay * by;
}

/* 3D dot product */
double dot3_d(double ax, double ay, double az,
              double bx, double by, double bz) {
    return ax * bx + ay * by + az * bz;
}

/* 3D cross product (returns x component) */
double cross3x_d(double ay, double az, double by, double bz) {
    return ay * bz - az * by;
}

/* Linear interpolation: a + t*(b-a) */
double lerp_d(double a, double b, double t) {
    return a + t * (b - a);
}

/* Bilinear interpolation (2D) */
double bilerp_d(double v00, double v10, double v01, double v11,
                double tx, double ty) {
    double lo = v00 + tx * (v10 - v00);
    double hi = v01 + tx * (v11 - v01);
    return lo + ty * (hi - lo);
}

/* Quadratic Bezier */
double bezier2_d(double p0, double p1, double p2, double t) {
    double mt = 1.0 - t;
    return mt * mt * p0 + 2.0 * mt * t * p1 + t * t * p2;
}

/*===----------------------------------------------------------------------===*/
/* Vector / Array Operations                                                  */
/*===----------------------------------------------------------------------===*/

/* Vector addition */
void dvadd(double *dst, const double *a, const double *b, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = a[i] + b[i];
}

/* Vector subtraction */
void dvsub(double *dst, const double *a, const double *b, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = a[i] - b[i];
}

/* Vector multiply */
void dvmul(double *dst, const double *a, const double *b, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = a[i] * b[i];
}

/* Vector scale */
void dvscale(double *dst, const double *src, double s, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = src[i] * s;
}

/* DAXPY: y = a*x + y */
void daxpy(double *y, const double *x, double a, int n) {
    for (int i = 0; i < n; i++)
        y[i] = a * x[i] + y[i];
}

/* Dot product (MAC chain) */
double ddot(const double *a, const double *b, int n) {
    double acc = 0.0;
    for (int i = 0; i < n; i++)
        acc += a[i] * b[i];
    return acc;
}

/* Sum of array */
double dvsum(const double *arr, int n) {
    double sum = 0.0;
    for (int i = 0; i < n; i++)
        sum += arr[i];
    return sum;
}

/* Vector min / max (comparison in loop) */
double dvmin(const double *arr, int n) {
    double m = arr[0];
    for (int i = 1; i < n; i++)
        if (arr[i] < m) m = arr[i];
    return m;
}
double dvmax(const double *arr, int n) {
    double m = arr[0];
    for (int i = 1; i < n; i++)
        if (arr[i] > m) m = arr[i];
    return m;
}

/* Element-wise FMA: dst[i] = a[i]*b[i] + c[i] */
void dvfma(double *dst, const double *a, const double *b, const double *c,
           int n) {
    for (int i = 0; i < n; i++)
        dst[i] = __builtin_fma(a[i], b[i], c[i]);
}

/*===----------------------------------------------------------------------===*/
/* Mixed-Precision Patterns                                                   */
/*===----------------------------------------------------------------------===*/

/* Accumulate float array in double precision (CVTF.SD in loop) */
double mixed_acc_f32_to_f64(const float *arr, int n) {
    double sum = 0.0;
    for (int i = 0; i < n; i++)
        sum += (double)arr[i];
    return sum;
}

/* Convert float array to double array (CVTF.SD) */
void f32_to_f64_array(double *dst, const float *src, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = (double)src[i];
}

/* Convert double array to float array (CVTF.DS) */
void f64_to_f32_array(float *dst, const double *src, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = (float)src[i];
}

/* int32 array to double array (CVTF.WD) */
void i32_to_f64_array(double *dst, const int *src, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = (double)src[i];
}

/* double array to int32 array (TRNCF.DW) */
void f64_to_i32_array(int *dst, const double *src, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = (int)src[i];
}

/*===----------------------------------------------------------------------===*/
/* DSP Kernels (double-precision)                                             */
/*===----------------------------------------------------------------------===*/

/* FIR filter: y = sum(coeffs[i] * samples[i]) */
double dfir(const double *coeffs, const double *samples, int n) {
    double acc = 0.0;
    for (int i = 0; i < n; i++)
        acc += coeffs[i] * samples[i];
    return acc;
}

/* Biquad IIR (direct form II transposed, double) */
typedef struct {
    double b0, b1, b2;
    double a1, a2;
    double z1, z2;
} BiquadD;

double diir_biquad(BiquadD *s, double input) {
    double output = s->b0 * input + s->z1;
    s->z1 = s->b1 * input - s->a1 * output + s->z2;
    s->z2 = s->b2 * input - s->a2 * output;
    return output;
}

/* Exponential moving average */
double dema(double prev, double curr, double alpha) {
    return prev + alpha * (curr - prev);
}

/* Variance of array: E[x^2] - E[x]^2 */
double dvariance(const double *arr, int n) {
    double sum = 0.0, sum2 = 0.0;
    double inv_n = 1.0 / (double)n;
    for (int i = 0; i < n; i++) {
        sum  += arr[i];
        sum2 += arr[i] * arr[i];
    }
    double mean = sum * inv_n;
    return sum2 * inv_n - mean * mean;
}

/* Complex multiply: (ar + j*ai) * (br + j*bi) -> real part only */
double complex_mul_re(double ar, double ai, double br, double bi) {
    return ar * br - ai * bi;
}
double complex_mul_im(double ar, double ai, double br, double bi) {
    return ar * bi + ai * br;
}

/*===----------------------------------------------------------------------===*/
/* Trigonometric Polynomial Approximations (double)                          */
/*===----------------------------------------------------------------------===*/

/* Polynomial cos approximation (Chebyshev, |x| < pi/2):
 * cos(x) ≈ 1 - x^2/2! + x^4/4! - x^6/6!
 * Exercises 3 FMA pairs chained together. */
double fast_cos_d(double x) {
    double x2 = x * x;
    return (((-0.0013888888888 * x2 + 0.0416666666667) * x2
              - 0.5) * x2 + 1.0);
}

/* Polynomial sin approximation (Chebyshev):
 * sin(x) ≈ x - x^3/3! + x^5/5! - x^7/7! */
double fast_sin_d(double x) {
    double x2 = x * x;
    return x * (((0.000198412698 * x2 - 0.00833333333) * x2
                  + 0.166666667) * x2 - 1.0) * (-1.0);
}

/* exp(x) approximation via Horner (|x| < 1):
 * e^x ≈ 1 + x + x^2/2 + x^3/6 + x^4/24 + x^5/120 */
double fast_exp_d(double x) {
    return 1.0 + x * (1.0 + x * (0.5 + x * (0.166666667 +
           x * (0.0416666667 + x * 0.00833333333))));
}

/* ln(1+x) for |x| < 0.5 (Taylor):
 * ln(1+x) ≈ x - x^2/2 + x^3/3 - x^4/4 + x^5/5 */
double fast_ln1p_d(double x) {
    double x2 = x * x;
    double x3 = x2 * x;
    double x4 = x2 * x2;
    double x5 = x4 * x;
    return x - 0.5 * x2 + 0.333333333 * x3 - 0.25 * x4 + 0.2 * x5;
}

/* Newton-Raphson inverse-sqrt refinement step: y' = y*(1.5 - 0.5*x*y^2) */
double newton_rsqrt_step_d(double x, double y) {
    return y * (1.5 - 0.5 * x * y * y);
}

/*===----------------------------------------------------------------------===*/
/* Embedded Control Patterns (double)                                        */
/*===----------------------------------------------------------------------===*/

/* Sensor calibration: y = gain * x + offset */
double sensor_cal_d(double raw, double gain, double offset) {
    return gain * raw + offset;
}

/* Two-point linear calibration: scale between (x0,y0) and (x1,y1) */
double linear_cal_d(double x, double x0, double y0, double x1, double y1) {
    return y0 + (x - x0) * (y1 - y0) / (x1 - x0);
}

/* Voltage divider */
double voltage_divider_d(double vin, double r1, double r2) {
    return vin * r2 / (r1 + r2);
}

/* RC low-pass filter step */
double rc_lowpass_d(double vin, double prev, double alpha) {
    return alpha * vin + (1.0 - alpha) * prev;
}

/* PID controller (double, no output clamp) */
typedef struct {
    double kp, ki, kd;
    double integral, prev_error;
} PIDd;

double pid_step_d(PIDd *pid, double error, double dt) {
    pid->integral += error * dt;
    double derivative = (error - pid->prev_error) / dt;
    pid->prev_error = error;
    return pid->kp * error + pid->ki * pid->integral + pid->kd * derivative;
}

/* PID with output clamping (FP comparisons) */
double pid_clamp_d(PIDd *pid, double error, double dt,
                   double out_min, double out_max) {
    double out = pid_step_d(pid, error, dt);
    if (out > out_max) return out_max;
    if (out < out_min) return out_min;
    return out;
}

/* Quaternion magnitude squared: w^2 + x^2 + y^2 + z^2 */
double quat_mag2(double w, double x, double y, double z) {
    return w * w + x * x + y * y + z * z;
}

/* Quaternion dot product */
double quat_dot(double w1, double x1, double y1, double z1,
                double w2, double x2, double y2, double z2) {
    return w1 * w2 + x1 * x2 + y1 * y2 + z1 * z2;
}

/*===----------------------------------------------------------------------===*/
/* Matrix Operations (double)                                                */
/*===----------------------------------------------------------------------===*/

/* 2x2 matrix multiply */
void mat2x2_mul_d(double *c, const double *a, const double *b) {
    c[0] = a[0] * b[0] + a[1] * b[2];
    c[1] = a[0] * b[1] + a[1] * b[3];
    c[2] = a[2] * b[0] + a[3] * b[2];
    c[3] = a[2] * b[1] + a[3] * b[3];
}

/* 3x3 matrix multiply */
void mat3x3_mul_d(double *c, const double *a, const double *b) {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            double s = 0.0;
            for (int k = 0; k < 3; k++)
                s += a[i * 3 + k] * b[k * 3 + j];
            c[i * 3 + j] = s;
        }
    }
}

/* 4x4 matrix-vector multiply */
void mat4x4_vec_d(double *out, const double *m, const double *v) {
    for (int i = 0; i < 4; i++) {
        out[i] = m[i * 4 + 0] * v[0] + m[i * 4 + 1] * v[1] +
                 m[i * 4 + 2] * v[2] + m[i * 4 + 3] * v[3];
    }
}

/* Matrix trace */
double mat4x4_trace_d(const double *m) {
    return m[0] + m[5] + m[10] + m[15];
}

/* 2x2 determinant */
double mat2x2_det_d(const double *m) {
    return m[0] * m[3] - m[1] * m[2];
}

/* 3x3 determinant (Sarrus) */
double mat3x3_det_d(const double *m) {
    return m[0] * (m[4] * m[8] - m[5] * m[7]) -
           m[1] * (m[3] * m[8] - m[5] * m[6]) +
           m[2] * (m[3] * m[7] - m[4] * m[6]);
}
