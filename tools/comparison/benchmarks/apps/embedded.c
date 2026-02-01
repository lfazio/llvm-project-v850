/*
 * Application Benchmark: Embedded System Patterns
 *
 * Common patterns in automotive/industrial embedded systems.
 */

#include <stdint.h>
#include <stddef.h>

/* ========== Ring Buffer (FIFO) ========== */

#define RING_SIZE 64

typedef struct {
    uint8_t buffer[RING_SIZE];
    volatile uint16_t head;
    volatile uint16_t tail;
} RingBuffer;

void ring_init(RingBuffer *rb) {
    rb->head = 0;
    rb->tail = 0;
}

int ring_is_empty(const RingBuffer *rb) {
    return rb->head == rb->tail;
}

int ring_is_full(const RingBuffer *rb) {
    return ((rb->head + 1) % RING_SIZE) == rb->tail;
}

int ring_put(RingBuffer *rb, uint8_t data) {
    uint16_t next = (rb->head + 1) % RING_SIZE;
    if (next == rb->tail) {
        return -1;  /* Full */
    }
    rb->buffer[rb->head] = data;
    rb->head = next;
    return 0;
}

int ring_get(RingBuffer *rb, uint8_t *data) {
    if (rb->head == rb->tail) {
        return -1;  /* Empty */
    }
    *data = rb->buffer[rb->tail];
    rb->tail = (rb->tail + 1) % RING_SIZE;
    return 0;
}

uint16_t ring_count(const RingBuffer *rb) {
    return (rb->head - rb->tail + RING_SIZE) % RING_SIZE;
}

/* ========== CAN Message Processing ========== */

typedef struct {
    uint32_t id;
    uint8_t dlc;
    uint8_t data[8];
    uint32_t timestamp;
} CanMessage;

/* CAN signal extraction (bit-level access) */
uint32_t can_extract_signal(const uint8_t *data, uint8_t start_bit,
                            uint8_t length, int is_big_endian) {
    uint32_t value = 0;

    if (is_big_endian) {
        /* Motorola byte order */
        int byte_pos = start_bit / 8;
        int bit_pos = start_bit % 8;
        for (int i = 0; i < (int)length; i++) {
            int src_bit = bit_pos - (i % 8);
            if (src_bit < 0) {
                byte_pos++;
                src_bit += 8;
            }
            if ((data[byte_pos] >> src_bit) & 1) {
                value |= (1u << (length - 1 - i));
            }
        }
    } else {
        /* Intel byte order */
        int byte_pos = start_bit / 8;
        int bit_pos = start_bit % 8;
        for (int i = 0; i < (int)length; i++) {
            if ((data[byte_pos] >> bit_pos) & 1) {
                value |= (1u << i);
            }
            bit_pos++;
            if (bit_pos >= 8) {
                bit_pos = 0;
                byte_pos++;
            }
        }
    }
    return value;
}

/* Pack signal into CAN data */
void can_pack_signal(uint8_t *data, uint32_t value, uint8_t start_bit,
                     uint8_t length, int is_big_endian) {
    if (is_big_endian) {
        int byte_pos = start_bit / 8;
        int bit_pos = start_bit % 8;
        for (int i = 0; i < (int)length; i++) {
            int src_bit = bit_pos - (i % 8);
            if (src_bit < 0) {
                byte_pos++;
                src_bit += 8;
            }
            if ((value >> (length - 1 - i)) & 1) {
                data[byte_pos] |= (1u << src_bit);
            } else {
                data[byte_pos] &= ~(1u << src_bit);
            }
        }
    } else {
        int byte_pos = start_bit / 8;
        int bit_pos = start_bit % 8;
        for (int i = 0; i < (int)length; i++) {
            if ((value >> i) & 1) {
                data[byte_pos] |= (1u << bit_pos);
            } else {
                data[byte_pos] &= ~(1u << bit_pos);
            }
            bit_pos++;
            if (bit_pos >= 8) {
                bit_pos = 0;
                byte_pos++;
            }
        }
    }
}

/* Process engine status message (example) */
typedef struct {
    uint16_t rpm;           /* 0-16000 rpm */
    int8_t coolant_temp;    /* -40 to 215 C */
    uint8_t throttle_pos;   /* 0-100% */
    uint16_t vehicle_speed; /* 0-655 km/h (0.01 resolution) */
    uint8_t engine_load;    /* 0-100% */
} EngineStatus;

void decode_engine_status(EngineStatus *status, const CanMessage *msg) {
    if (msg->id != 0x100 || msg->dlc < 8) {
        return;
    }
    /* Extract signals (example layout) */
    status->rpm = (uint16_t)can_extract_signal(msg->data, 0, 16, 0);
    status->coolant_temp = (int8_t)(can_extract_signal(msg->data, 16, 8, 0) - 40);
    status->throttle_pos = (uint8_t)can_extract_signal(msg->data, 24, 8, 0);
    status->vehicle_speed = (uint16_t)can_extract_signal(msg->data, 32, 16, 0);
    status->engine_load = (uint8_t)can_extract_signal(msg->data, 48, 8, 0);
}

/* ========== Timer/Counter Management ========== */

#define MAX_TIMERS 8

typedef struct {
    uint32_t period;
    uint32_t remaining;
    void (*callback)(void);
    uint8_t active;
    uint8_t periodic;
} SoftTimer;

static SoftTimer g_timers[MAX_TIMERS];

void timer_init_all(void) {
    for (int i = 0; i < MAX_TIMERS; i++) {
        g_timers[i].active = 0;
    }
}

int timer_start(int id, uint32_t period, void (*callback)(void), int periodic) {
    if (id < 0 || id >= MAX_TIMERS) {
        return -1;
    }
    g_timers[id].period = period;
    g_timers[id].remaining = period;
    g_timers[id].callback = callback;
    g_timers[id].active = 1;
    g_timers[id].periodic = periodic ? 1 : 0;
    return 0;
}

void timer_stop(int id) {
    if (id >= 0 && id < MAX_TIMERS) {
        g_timers[id].active = 0;
    }
}

void timer_tick(uint32_t elapsed) {
    for (int i = 0; i < MAX_TIMERS; i++) {
        if (g_timers[i].active) {
            if (g_timers[i].remaining <= elapsed) {
                if (g_timers[i].callback) {
                    g_timers[i].callback();
                }
                if (g_timers[i].periodic) {
                    g_timers[i].remaining = g_timers[i].period;
                } else {
                    g_timers[i].active = 0;
                }
            } else {
                g_timers[i].remaining -= elapsed;
            }
        }
    }
}

/* ========== PID Controller ========== */

typedef struct {
    int32_t kp;         /* Proportional gain (Q16) */
    int32_t ki;         /* Integral gain (Q16) */
    int32_t kd;         /* Derivative gain (Q16) */
    int32_t integral;   /* Accumulated error */
    int32_t prev_error; /* Previous error for derivative */
    int32_t out_min;    /* Output minimum */
    int32_t out_max;    /* Output maximum */
    int32_t integral_max; /* Anti-windup limit */
} PidController;

void pid_init(PidController *pid, int32_t kp, int32_t ki, int32_t kd) {
    pid->kp = kp;
    pid->ki = ki;
    pid->kd = kd;
    pid->integral = 0;
    pid->prev_error = 0;
    pid->out_min = -32768;
    pid->out_max = 32767;
    pid->integral_max = 32768 << 16;
}

int32_t pid_update(PidController *pid, int32_t setpoint, int32_t measured) {
    int32_t error = setpoint - measured;

    /* Proportional term */
    int32_t p_term = (pid->kp * error) >> 16;

    /* Integral term with anti-windup */
    pid->integral += error;
    if (pid->integral > pid->integral_max) {
        pid->integral = pid->integral_max;
    } else if (pid->integral < -pid->integral_max) {
        pid->integral = -pid->integral_max;
    }
    int32_t i_term = (pid->ki * pid->integral) >> 16;

    /* Derivative term */
    int32_t d_term = (pid->kd * (error - pid->prev_error)) >> 16;
    pid->prev_error = error;

    /* Sum and clamp output */
    int32_t output = p_term + i_term + d_term;
    if (output > pid->out_max) {
        output = pid->out_max;
    } else if (output < pid->out_min) {
        output = pid->out_min;
    }

    return output;
}

/* ========== Debounce Filter ========== */

typedef struct {
    uint8_t state;          /* Current debounced state */
    uint8_t raw_state;      /* Last raw reading */
    uint8_t counter;        /* Consecutive same readings */
    uint8_t threshold;      /* Required consecutive readings */
} Debounce;

void debounce_init(Debounce *db, uint8_t threshold) {
    db->state = 0;
    db->raw_state = 0;
    db->counter = 0;
    db->threshold = threshold;
}

uint8_t debounce_update(Debounce *db, uint8_t input) {
    if (input == db->raw_state) {
        if (db->counter < db->threshold) {
            db->counter++;
        }
        if (db->counter >= db->threshold) {
            db->state = input;
        }
    } else {
        db->raw_state = input;
        db->counter = 0;
    }
    return db->state;
}

/* ========== Moving Average Filter ========== */

#define MAVG_SIZE 16

typedef struct {
    int16_t samples[MAVG_SIZE];
    uint8_t index;
    int32_t sum;
} MovingAverage;

void mavg_init(MovingAverage *ma) {
    for (int i = 0; i < MAVG_SIZE; i++) {
        ma->samples[i] = 0;
    }
    ma->index = 0;
    ma->sum = 0;
}

int16_t mavg_update(MovingAverage *ma, int16_t input) {
    ma->sum -= ma->samples[ma->index];
    ma->samples[ma->index] = input;
    ma->sum += input;
    ma->index = (ma->index + 1) % MAVG_SIZE;
    return (int16_t)(ma->sum / MAVG_SIZE);
}

/* ========== Lookup Table with Interpolation ========== */

typedef struct {
    const int16_t *x_values;
    const int16_t *y_values;
    uint8_t size;
} LookupTable;

int16_t lookup_interpolate(const LookupTable *lut, int16_t x) {
    /* Handle out of range */
    if (x <= lut->x_values[0]) {
        return lut->y_values[0];
    }
    if (x >= lut->x_values[lut->size - 1]) {
        return lut->y_values[lut->size - 1];
    }

    /* Find segment */
    uint8_t i;
    for (i = 0; i < lut->size - 1; i++) {
        if (x < lut->x_values[i + 1]) {
            break;
        }
    }

    /* Linear interpolation */
    int32_t x0 = lut->x_values[i];
    int32_t x1 = lut->x_values[i + 1];
    int32_t y0 = lut->y_values[i];
    int32_t y1 = lut->y_values[i + 1];

    return (int16_t)(y0 + ((y1 - y0) * (x - x0)) / (x1 - x0));
}

/* ========== Bitfield Register Access ========== */

/* Typical embedded register access patterns */
#define REG_WRITE(addr, val)    (*(volatile uint32_t *)(addr) = (val))
#define REG_READ(addr)          (*(volatile uint32_t *)(addr))
#define REG_SET_BITS(addr, mask)    REG_WRITE(addr, REG_READ(addr) | (mask))
#define REG_CLR_BITS(addr, mask)    REG_WRITE(addr, REG_READ(addr) & ~(mask))
#define REG_MODIFY(addr, mask, val) REG_WRITE(addr, (REG_READ(addr) & ~(mask)) | ((val) & (mask)))

/* Extract field from register value */
uint32_t reg_get_field(uint32_t reg_val, uint8_t start_bit, uint8_t width) {
    return (reg_val >> start_bit) & ((1u << width) - 1);
}

/* Insert field into register value */
uint32_t reg_set_field(uint32_t reg_val, uint8_t start_bit, uint8_t width, uint32_t field_val) {
    uint32_t mask = ((1u << width) - 1) << start_bit;
    return (reg_val & ~mask) | ((field_val << start_bit) & mask);
}

