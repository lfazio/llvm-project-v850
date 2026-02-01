/*
 * Computational Kernel: DSP Operations
 *
 * Digital Signal Processing algorithms commonly used in embedded systems.
 */

#include <stdint.h>

/* FIR Filter - Finite Impulse Response */
int fir_filter(const int *coeffs, const int *samples, int n) {
    int acc = 0;
    for (int i = 0; i < n; i++) {
        acc += coeffs[i] * samples[i];
    }
    return acc;
}

/* FIR Filter with Q15 fixed-point arithmetic */
int16_t fir_q15(const int16_t *coeffs, const int16_t *samples, int n) {
    int32_t acc = 0;
    for (int i = 0; i < n; i++) {
        acc += (int32_t)coeffs[i] * samples[i];
    }
    /* Round and saturate to Q15 */
    acc = (acc + 0x4000) >> 15;
    if (acc > 32767) acc = 32767;
    if (acc < -32768) acc = -32768;
    return (int16_t)acc;
}

/* IIR Filter - Infinite Impulse Response (biquad) */
typedef struct {
    int32_t b0, b1, b2;  /* Feedforward coefficients */
    int32_t a1, a2;       /* Feedback coefficients */
    int32_t z1, z2;       /* Delay elements */
} BiquadState;

int32_t iir_biquad(BiquadState *state, int32_t input) {
    /* Direct Form II Transposed */
    int32_t output = (int32_t)(((int64_t)state->b0 * input + state->z1) >> 15);
    state->z1 = (int64_t)state->b1 * input - (int64_t)state->a1 * output + state->z2;
    state->z2 = (int64_t)state->b2 * input - (int64_t)state->a2 * output;
    return output;
}

/* Dot product */
int dot_product(const int *a, const int *b, int n) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
        sum += a[i] * b[i];
    }
    return sum;
}

/* Dot product with saturation */
int dot_product_sat(const int16_t *a, const int16_t *b, int n) {
    int32_t acc = 0;
    for (int i = 0; i < n; i++) {
        int32_t prod = (int32_t)a[i] * b[i];
        int32_t new_acc = acc + prod;
        /* Check for overflow */
        if ((prod > 0 && acc > 0 && new_acc < 0) ||
            (prod < 0 && acc < 0 && new_acc > 0)) {
            return (acc > 0) ? 0x7FFFFFFF : 0x80000000;
        }
        acc = new_acc;
    }
    return acc;
}

/* Convolution */
void convolve(int *output, const int *signal, int sig_len,
              const int *kernel, int ker_len) {
    for (int i = 0; i < sig_len + ker_len - 1; i++) {
        int sum = 0;
        for (int j = 0; j < ker_len; j++) {
            if (i - j >= 0 && i - j < sig_len) {
                sum += signal[i - j] * kernel[j];
            }
        }
        output[i] = sum;
    }
}

/* Moving average filter */
int moving_average(const int *samples, int n, int window) {
    int sum = 0;
    for (int i = 0; i < window && i < n; i++) {
        sum += samples[i];
    }
    return sum / window;
}

/* Peak detector */
int find_peak(const int *samples, int n) {
    int max_val = samples[0];
    int max_idx = 0;
    for (int i = 1; i < n; i++) {
        if (samples[i] > max_val) {
            max_val = samples[i];
            max_idx = i;
        }
    }
    return max_idx;
}

/* Energy calculation */
unsigned int signal_energy(const int16_t *samples, int n) {
    unsigned int energy = 0;
    for (int i = 0; i < n; i++) {
        int32_t s = samples[i];
        energy += s * s;
    }
    return energy;
}

/* RMS (Root Mean Square) approximation */
int rms_approx(const int16_t *samples, int n) {
    /* Use maximum absolute value as approximation */
    int max_abs = 0;
    for (int i = 0; i < n; i++) {
        int abs_val = samples[i] < 0 ? -samples[i] : samples[i];
        if (abs_val > max_abs) max_abs = abs_val;
    }
    /* RMS is approximately 0.707 * peak for sine wave */
    return (max_abs * 181) >> 8;  /* 181/256 ≈ 0.707 */
}

/* DC offset removal */
void remove_dc(int16_t *samples, int n) {
    /* Calculate mean */
    int32_t sum = 0;
    for (int i = 0; i < n; i++) {
        sum += samples[i];
    }
    int16_t mean = sum / n;

    /* Remove DC offset */
    for (int i = 0; i < n; i++) {
        samples[i] -= mean;
    }
}

/* Simple envelope detector */
void envelope_detect(int *output, const int *input, int n, int alpha) {
    int envelope = 0;
    for (int i = 0; i < n; i++) {
        int abs_val = input[i] < 0 ? -input[i] : input[i];
        if (abs_val > envelope) {
            envelope = abs_val;
        } else {
            envelope = envelope - ((envelope * alpha) >> 8);
        }
        output[i] = envelope;
    }
}

/* Zero crossing counter */
int count_zero_crossings(const int16_t *samples, int n) {
    int count = 0;
    int prev_sign = samples[0] >= 0;
    for (int i = 1; i < n; i++) {
        int curr_sign = samples[i] >= 0;
        if (curr_sign != prev_sign) {
            count++;
        }
        prev_sign = curr_sign;
    }
    return count;
}

/* Interpolation (linear) */
int interpolate_linear(const int *table, int size, int x, int x_scale) {
    int idx = x / x_scale;
    if (idx < 0) return table[0];
    if (idx >= size - 1) return table[size - 1];

    int frac = x - idx * x_scale;
    int y0 = table[idx];
    int y1 = table[idx + 1];
    return y0 + ((y1 - y0) * frac) / x_scale;
}

/* Decimation (downsampling by factor of 2) */
void decimate_2x(int *output, const int *input, int n) {
    for (int i = 0; i < n / 2; i++) {
        output[i] = input[i * 2];
    }
}

/* Interpolation (upsampling by factor of 2 with zero insertion) */
void upsample_2x(int *output, const int *input, int n) {
    for (int i = 0; i < n; i++) {
        output[i * 2] = input[i];
        output[i * 2 + 1] = 0;
    }
}

/* Windowing function (Hamming) */
void apply_hamming_window(int *output, const int *input, int n) {
    /* Hamming: w[n] = 0.54 - 0.46 * cos(2*pi*n/(N-1)) */
    /* Precomputed coefficients for n=0 to n-1 */
    for (int i = 0; i < n; i++) {
        /* Approximate with integer math */
        /* w = 138 - 118*cos(2*pi*i/(n-1)) scaled by 256 */
        int phase = (i * 256) / (n - 1);  /* 0 to 256 */
        /* cos approximation: 256 - (phase * (512 - phase)) / 128 */
        int cos_val = 256 - (phase * (512 - phase)) / 128;
        int w = 138 - (118 * cos_val) / 256;
        output[i] = (input[i] * w) / 256;
    }
}
