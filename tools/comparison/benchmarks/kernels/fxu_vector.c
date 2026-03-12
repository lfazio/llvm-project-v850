/*
 * Computational Kernel: FXU Vector Operations
 *
 * Benchmark patterns targeting the RH850G4MH FXU 128-bit SIMD unit.
 * The FXU operates on 4 x single-precision floats (v4f32) using wreg0-wreg31.
 *
 * These functions are written as simple loops over float arrays that LLVM's
 * loop vectorizer should be able to auto-vectorize to FXU instructions once
 * CodeGen support is implemented.
 *
 * Current state: FXU MC layer (assembly/disassembly) is complete.
 * CodeGen (ISel patterns, type legalization, TTI) is not yet implemented,
 * so these will initially compile to scalar code.
 *
 * Target FXU instructions are noted in comments for each function.
 *
 * Compile with:
 *   clang --target=v850 -mcpu=g4mh -O2 -S -o fxu_vector.s fxu_vector.c
 *   clang --target=v850 -mcpu=g4mh -O2 -fvectorize -S -o fxu_vector.s fxu_vector.c
 */

#include <stdint.h>

/* ========================================================================
 * 1. Basic Arithmetic (Target: ADDF.S4, SUBF.S4, MULF.S4, DIVF.S4)
 * ======================================================================== */

/* Vector add: c[i] = a[i] + b[i] → ADDF.S4 */
void vec_add(float *restrict c, const float *restrict a,
             const float *restrict b, int n) {
    for (int i = 0; i < n; i++)
        c[i] = a[i] + b[i];
}

/* Vector subtract: c[i] = a[i] - b[i] → SUBF.S4 */
void vec_sub(float *restrict c, const float *restrict a,
             const float *restrict b, int n) {
    for (int i = 0; i < n; i++)
        c[i] = a[i] - b[i];
}

/* Vector multiply: c[i] = a[i] * b[i] → MULF.S4 */
void vec_mul(float *restrict c, const float *restrict a,
             const float *restrict b, int n) {
    for (int i = 0; i < n; i++)
        c[i] = a[i] * b[i];
}

/* Vector divide: c[i] = a[i] / b[i] → DIVF.S4 */
void vec_div(float *restrict c, const float *restrict a,
             const float *restrict b, int n) {
    for (int i = 0; i < n; i++)
        c[i] = a[i] / b[i];
}

/* ========================================================================
 * 2. Unary Operations (Target: ABSF.S4, NEGF.S4, SQRTF.S4, RECIPF.S4)
 * ======================================================================== */

/* Vector absolute value: b[i] = |a[i]| → ABSF.S4 */
void vec_abs(float *restrict b, const float *restrict a, int n) {
    for (int i = 0; i < n; i++)
        b[i] = a[i] < 0.0f ? -a[i] : a[i];
}

/* Vector negate: b[i] = -a[i] → NEGF.S4 */
void vec_neg(float *restrict b, const float *restrict a, int n) {
    for (int i = 0; i < n; i++)
        b[i] = -a[i];
}

/* Vector reciprocal: b[i] = 1.0f / a[i] → RECIPF.S4 */
void vec_recip(float *restrict b, const float *restrict a, int n) {
    for (int i = 0; i < n; i++)
        b[i] = 1.0f / a[i];
}

/* ========================================================================
 * 3. Fused Multiply-Add (Target: FMAF.S4, FMSF.S4, FNMAF.S4, FNMSF.S4)
 * ======================================================================== */

/* FMA: d[i] = a[i] * b[i] + c[i] → FMAF.S4 */
void vec_fma(float *restrict d, const float *restrict a,
             const float *restrict b, const float *restrict c, int n) {
    for (int i = 0; i < n; i++)
        d[i] = a[i] * b[i] + c[i];
}

/* FMS: d[i] = a[i] * b[i] - c[i] → FMSF.S4 */
void vec_fms(float *restrict d, const float *restrict a,
             const float *restrict b, const float *restrict c, int n) {
    for (int i = 0; i < n; i++)
        d[i] = a[i] * b[i] - c[i];
}

/* NFMA: d[i] = -(a[i] * b[i]) + c[i] → FNMAF.S4 */
void vec_nfma(float *restrict d, const float *restrict a,
              const float *restrict b, const float *restrict c, int n) {
    for (int i = 0; i < n; i++)
        d[i] = -(a[i] * b[i]) + c[i];
}

/* ========================================================================
 * 4. Min/Max (Target: MAXF.S4, MINF.S4)
 * ======================================================================== */

/* Vector max: c[i] = max(a[i], b[i]) → MAXF.S4 */
void vec_max(float *restrict c, const float *restrict a,
             const float *restrict b, int n) {
    for (int i = 0; i < n; i++)
        c[i] = a[i] > b[i] ? a[i] : b[i];
}

/* Vector min: c[i] = min(a[i], b[i]) → MINF.S4 */
void vec_min(float *restrict c, const float *restrict a,
             const float *restrict b, int n) {
    for (int i = 0; i < n; i++)
        c[i] = a[i] < b[i] ? a[i] : b[i];
}

/* Vector clamp: c[i] = clamp(a[i], lo, hi) → MAXF.S4 + MINF.S4 */
void vec_clamp(float *restrict c, const float *restrict a,
               float lo, float hi, int n) {
    for (int i = 0; i < n; i++) {
        float v = a[i];
        if (v < lo) v = lo;
        if (v > hi) v = hi;
        c[i] = v;
    }
}

/* ========================================================================
 * 5. Reductions (Target: ADDRF.S4, MULRF.S4, MAXRF.S4, MINRF.S4)
 * ======================================================================== */

/* Sum reduction → ADDF.S4 + ADDRF.S4 */
float vec_sum(const float *a, int n) {
    float sum = 0.0f;
    for (int i = 0; i < n; i++)
        sum += a[i];
    return sum;
}

/* Dot product → MULF.S4 + ADDRF.S4 (or FMAF.S4 + ADDRF.S4) */
float vec_dot(const float *a, const float *b, int n) {
    float sum = 0.0f;
    for (int i = 0; i < n; i++)
        sum += a[i] * b[i];
    return sum;
}

/* Max reduction → MAXF.S4 + MAXRF.S4 */
float vec_max_reduce(const float *a, int n) {
    float m = a[0];
    for (int i = 1; i < n; i++)
        if (a[i] > m) m = a[i];
    return m;
}

/* Min reduction → MINF.S4 + MINRF.S4 */
float vec_min_reduce(const float *a, int n) {
    float m = a[0];
    for (int i = 1; i < n; i++)
        if (a[i] < m) m = a[i];
    return m;
}

/* ========================================================================
 * 6. Conversion (Target: CVTF.WS4, CVTF.SW4, CVTF.UWS4, CVTF.SUW4)
 * ======================================================================== */

/* Int-to-float conversion → CVTF.WS4 */
void vec_itof(float *restrict dst, const int32_t *restrict src, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = (float)src[i];
}

/* Float-to-int truncation → TRNCF.SW4 */
void vec_ftoi(int32_t *restrict dst, const float *restrict src, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = (int32_t)src[i];
}

/* Unsigned int-to-float → CVTF.UWS4 */
void vec_utof(float *restrict dst, const uint32_t *restrict src, int n) {
    for (int i = 0; i < n; i++)
        dst[i] = (float)src[i];
}

/* ========================================================================
 * 7. DSP / Signal Processing Patterns
 * ======================================================================== */

/* FIR filter (float) - classic vectorizable loop
 * → MULF.S4 + ADDF.S4 (or FMAF.S4) + ADDRF.S4 */
float fir_float(const float *coeffs, const float *samples, int n) {
    float acc = 0.0f;
    for (int i = 0; i < n; i++)
        acc += coeffs[i] * samples[i];
    return acc;
}

/* Block FIR filter - processes 4 samples at once
 * Good candidate for full vectorization with FXU */
void fir_block(float *restrict out, const float *restrict in,
               const float *restrict coeffs, int n_samples, int n_taps) {
    for (int s = 0; s < n_samples; s++) {
        float acc = 0.0f;
        for (int t = 0; t < n_taps; t++)
            acc += coeffs[t] * in[s + t];
        out[s] = acc;
    }
}

/* IIR biquad filter (float) - limited vectorization due to feedback */
void iir_biquad_float(float *restrict out, const float *restrict in,
                      float b0, float b1, float b2, float a1, float a2,
                      float *z1, float *z2, int n) {
    for (int i = 0; i < n; i++) {
        float x = in[i];
        float y = b0 * x + *z1;
        *z1 = b1 * x - a1 * y + *z2;
        *z2 = b2 * x - a2 * y;
        out[i] = y;
    }
}

/* ========================================================================
 * 8. Matrix Operations (4x4 — fits perfectly in 4 wreg registers)
 * ======================================================================== */

/* 4x4 matrix multiply (row-major)
 * Each row is a v4f32 → MULF.S4 + FMAF.S4 or ADDRF.S4 */
void mat4_mul(float C[16], const float A[16], const float B[16]) {
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            float sum = 0.0f;
            for (int k = 0; k < 4; k++)
                sum += A[i * 4 + k] * B[k * 4 + j];
            C[i * 4 + j] = sum;
        }
    }
}

/* 4x4 matrix-vector multiply: y = M * x
 * Each row dot product → MULF.S4 + ADDRF.S4 (or FMAF.S4 + ADDRF.S4) */
void mat4_vec_mul(float y[4], const float M[16], const float x[4]) {
    for (int i = 0; i < 4; i++) {
        float sum = 0.0f;
        for (int j = 0; j < 4; j++)
            sum += M[i * 4 + j] * x[j];
        y[i] = sum;
    }
}

/* Matrix transpose 4x4 → could use SHFLV.W4 / FLPV.S4 */
void mat4_transpose(float dst[16], const float src[16]) {
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 4; j++)
            dst[j * 4 + i] = src[i * 4 + j];
}

/* ========================================================================
 * 9. Geometry / 3D Graphics Patterns
 * ======================================================================== */

/* 3D vector normalize (using reciprocal sqrt)
 * → MULF.S4 + ADDRF.S4 + RSQRTF.S4 + MULF.S4 */
void vec3_normalize(float out[3], const float in[3]) {
    float len2 = in[0] * in[0] + in[1] * in[1] + in[2] * in[2];
    float inv_len = 1.0f;
    if (len2 > 0.0f) {
        /* Newton-Raphson approximation using rsqrt */
        float x = len2;
        /* Use integer bit hack for initial approximation */
        union { float f; uint32_t i; } conv;
        conv.f = x;
        conv.i = 0x5f3759df - (conv.i >> 1);
        inv_len = conv.f;
        inv_len = inv_len * (1.5f - 0.5f * x * inv_len * inv_len);
    }
    out[0] = in[0] * inv_len;
    out[1] = in[1] * inv_len;
    out[2] = in[2] * inv_len;
}

/* Batch 3D vector dot product (AoS layout)
 * Process 4 dot products at once using MULF.S4 + FMAF.S4 */
void batch_dot3(float *restrict dots, const float *restrict a,
                const float *restrict b, int n) {
    for (int i = 0; i < n; i++) {
        dots[i] = a[i * 3 + 0] * b[i * 3 + 0] +
                  a[i * 3 + 1] * b[i * 3 + 1] +
                  a[i * 3 + 2] * b[i * 3 + 2];
    }
}

/* Cross product batch (SoA layout — better for vectorization)
 * cx = ay*bz - az*by → MULF.S4 + FMSF.S4 */
void batch_cross3_soa(float *restrict cx, float *restrict cy, float *restrict cz,
                      const float *restrict ax, const float *restrict ay,
                      const float *restrict az,
                      const float *restrict bx, const float *restrict by,
                      const float *restrict bz, int n) {
    for (int i = 0; i < n; i++) {
        cx[i] = ay[i] * bz[i] - az[i] * by[i];
        cy[i] = az[i] * bx[i] - ax[i] * bz[i];
        cz[i] = ax[i] * by[i] - ay[i] * bx[i];
    }
}

/* ========================================================================
 * 10. Automotive / Control Patterns
 * ======================================================================== */

/* PID controller — 4 channels in parallel
 * → SUBF.S4 + MULF.S4 + ADDF.S4 + FMAF.S4 */
typedef struct {
    float kp[4], ki[4], kd[4];       /* Gains per channel */
    float integral[4];                /* Accumulated integral */
    float prev_error[4];              /* Previous error */
} PID4;

void pid4_update(PID4 *pid, float output[4],
                 const float setpoint[4], const float measured[4], float dt) {
    for (int i = 0; i < 4; i++) {
        float error = setpoint[i] - measured[i];
        pid->integral[i] += error * dt;
        float derivative = (error - pid->prev_error[i]) / dt;
        output[i] = pid->kp[i] * error +
                     pid->ki[i] * pid->integral[i] +
                     pid->kd[i] * derivative;
        pid->prev_error[i] = error;
    }
}

/* Sensor data scaling — common automotive pattern
 * raw_voltage → engineering_units: y = scale * x + offset
 * → LDV.QW + MULF.S4 + ADDF.S4 (or FMAF.S4) + STV.QW */
void sensor_scale(float *restrict eng_units, const float *restrict raw,
                  const float *restrict scale, const float *restrict offset,
                  int n) {
    for (int i = 0; i < n; i++)
        eng_units[i] = scale[i] * raw[i] + offset[i];
}

/* Weighted average of 4-channel sensor data
 * → MULF.S4 + ADDRF.S4 */
float sensor_weighted_avg(const float values[4], const float weights[4]) {
    float sum = 0.0f;
    float wsum = 0.0f;
    for (int i = 0; i < 4; i++) {
        sum += values[i] * weights[i];
        wsum += weights[i];
    }
    return sum / wsum;
}

/* ========================================================================
 * 11. Audio Processing Patterns
 * ======================================================================== */

/* Stereo to mono mixdown (interleaved → mono)
 * → LDV.DW (load pairs) + ADDF.S4 + MULF.S4 (scale by 0.5) */
void stereo_to_mono(float *restrict mono, const float *restrict stereo, int n) {
    for (int i = 0; i < n; i++)
        mono[i] = (stereo[i * 2] + stereo[i * 2 + 1]) * 0.5f;
}

/* Apply gain to audio buffer → MULF.S4 */
void audio_gain(float *restrict buf, float gain, int n) {
    for (int i = 0; i < n; i++)
        buf[i] *= gain;
}

/* Mix two audio streams: out = a * gain_a + b * gain_b
 * → MULF.S4 + FMAF.S4 */
void audio_mix(float *restrict out, const float *restrict a, float gain_a,
               const float *restrict b, float gain_b, int n) {
    for (int i = 0; i < n; i++)
        out[i] = a[i] * gain_a + b[i] * gain_b;
}

/* ========================================================================
 * 12. Fixed-size Vector Operations (unrolled, no loop — direct ISel)
 * These are the simplest patterns for initial CodeGen testing.
 * ======================================================================== */

/* Add two 4-element vectors — should map directly to ADDF.S4 */
void add4(float c[4], const float a[4], const float b[4]) {
    c[0] = a[0] + b[0];
    c[1] = a[1] + b[1];
    c[2] = a[2] + b[2];
    c[3] = a[3] + b[3];
}

/* Multiply two 4-element vectors — should map directly to MULF.S4 */
void mul4(float c[4], const float a[4], const float b[4]) {
    c[0] = a[0] * b[0];
    c[1] = a[1] * b[1];
    c[2] = a[2] * b[2];
    c[3] = a[3] * b[3];
}

/* FMA on 4-element vectors — should map to FMAF.S4 */
void fma4(float d[4], const float a[4], const float b[4], const float c[4]) {
    d[0] = a[0] * b[0] + c[0];
    d[1] = a[1] * b[1] + c[1];
    d[2] = a[2] * b[2] + c[2];
    d[3] = a[3] * b[3] + c[3];
}

/* Dot product of two 4-element vectors
 * → MULF.S4 + ADDRF.S4 (or FMAF.S4 + ADDRF.S4) */
float dot4(const float a[4], const float b[4]) {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
}

/* SAXPY: y = a*x + y — classic BLAS operation
 * → FMAF.S4 with y as accumulator */
void saxpy4(float y[4], float a, const float x[4]) {
    y[0] += a * x[0];
    y[1] += a * x[1];
    y[2] += a * x[2];
    y[3] += a * x[3];
}
