/*
 * Application Benchmark: State Machine
 *
 * Common embedded pattern for protocol handling, UI, and control systems.
 */

#include <stdint.h>
#include <stddef.h>

/* State definitions */
typedef enum {
    STATE_IDLE = 0,
    STATE_INIT,
    STATE_RUNNING,
    STATE_PAUSED,
    STATE_ERROR,
    STATE_SHUTDOWN,
    STATE_COUNT
} State;

/* Event definitions */
typedef enum {
    EVENT_NONE = 0,
    EVENT_START,
    EVENT_STOP,
    EVENT_PAUSE,
    EVENT_RESUME,
    EVENT_ERROR,
    EVENT_RESET,
    EVENT_TIMEOUT,
    EVENT_COUNT
} Event;

/* State machine context */
typedef struct {
    State current_state;
    State previous_state;
    uint32_t state_enter_time;
    uint32_t error_count;
    uint32_t transition_count;
} StateMachine;

/* Global state machine instance */
static StateMachine g_sm;

/* State entry actions */
static void on_enter_idle(void) {
    /* Reset counters */
}

static void on_enter_init(void) {
    /* Initialize hardware */
}

static void on_enter_running(void) {
    /* Start processing */
}

static void on_enter_paused(void) {
    /* Suspend processing */
}

static void on_enter_error(void) {
    g_sm.error_count++;
}

static void on_enter_shutdown(void) {
    /* Cleanup */
}

/* State exit actions */
static void on_exit_running(void) {
    /* Save state */
}

/* Transition table approach */
typedef struct {
    State current;
    Event event;
    State next;
    void (*action)(void);
} Transition;

static void action_start(void) {
    /* Start action */
}

static void action_stop(void) {
    /* Stop action */
}

static void action_error_handler(void) {
    /* Handle error */
}

static const Transition transition_table[] = {
    { STATE_IDLE,    EVENT_START,   STATE_INIT,     action_start },
    { STATE_INIT,    EVENT_START,   STATE_RUNNING,  NULL },
    { STATE_INIT,    EVENT_ERROR,   STATE_ERROR,    action_error_handler },
    { STATE_RUNNING, EVENT_PAUSE,   STATE_PAUSED,   NULL },
    { STATE_RUNNING, EVENT_STOP,    STATE_SHUTDOWN, action_stop },
    { STATE_RUNNING, EVENT_ERROR,   STATE_ERROR,    action_error_handler },
    { STATE_PAUSED,  EVENT_RESUME,  STATE_RUNNING,  NULL },
    { STATE_PAUSED,  EVENT_STOP,    STATE_SHUTDOWN, action_stop },
    { STATE_ERROR,   EVENT_RESET,   STATE_IDLE,     NULL },
    { STATE_SHUTDOWN,EVENT_RESET,   STATE_IDLE,     NULL },
};

#define TRANSITION_COUNT (sizeof(transition_table) / sizeof(transition_table[0]))

/* Table-driven state machine */
State process_event_table(State current, Event event) {
    for (unsigned i = 0; i < TRANSITION_COUNT; i++) {
        if (transition_table[i].current == current &&
            transition_table[i].event == event) {
            if (transition_table[i].action) {
                transition_table[i].action();
            }
            return transition_table[i].next;
        }
    }
    return current;  /* No transition */
}

/* Switch-based state machine (alternative implementation) */
State process_event_switch(State current, Event event) {
    switch (current) {
    case STATE_IDLE:
        switch (event) {
        case EVENT_START:
            return STATE_INIT;
        default:
            return current;
        }

    case STATE_INIT:
        switch (event) {
        case EVENT_START:
            return STATE_RUNNING;
        case EVENT_ERROR:
            return STATE_ERROR;
        case EVENT_TIMEOUT:
            return STATE_ERROR;
        default:
            return current;
        }

    case STATE_RUNNING:
        switch (event) {
        case EVENT_PAUSE:
            return STATE_PAUSED;
        case EVENT_STOP:
            return STATE_SHUTDOWN;
        case EVENT_ERROR:
            return STATE_ERROR;
        default:
            return current;
        }

    case STATE_PAUSED:
        switch (event) {
        case EVENT_RESUME:
            return STATE_RUNNING;
        case EVENT_STOP:
            return STATE_SHUTDOWN;
        default:
            return current;
        }

    case STATE_ERROR:
        switch (event) {
        case EVENT_RESET:
            return STATE_IDLE;
        default:
            return current;
        }

    case STATE_SHUTDOWN:
        switch (event) {
        case EVENT_RESET:
            return STATE_IDLE;
        default:
            return current;
        }

    default:
        return STATE_ERROR;
    }
}

/* Function pointer state machine */
typedef State (*StateHandler)(Event event);

static State handle_idle(Event event) {
    if (event == EVENT_START) return STATE_INIT;
    return STATE_IDLE;
}

static State handle_init(Event event) {
    switch (event) {
    case EVENT_START: return STATE_RUNNING;
    case EVENT_ERROR: return STATE_ERROR;
    case EVENT_TIMEOUT: return STATE_ERROR;
    default: return STATE_INIT;
    }
}

static State handle_running(Event event) {
    switch (event) {
    case EVENT_PAUSE: return STATE_PAUSED;
    case EVENT_STOP: return STATE_SHUTDOWN;
    case EVENT_ERROR: return STATE_ERROR;
    default: return STATE_RUNNING;
    }
}

static State handle_paused(Event event) {
    switch (event) {
    case EVENT_RESUME: return STATE_RUNNING;
    case EVENT_STOP: return STATE_SHUTDOWN;
    default: return STATE_PAUSED;
    }
}

static State handle_error(Event event) {
    if (event == EVENT_RESET) return STATE_IDLE;
    return STATE_ERROR;
}

static State handle_shutdown(Event event) {
    if (event == EVENT_RESET) return STATE_IDLE;
    return STATE_SHUTDOWN;
}

static const StateHandler state_handlers[STATE_COUNT] = {
    [STATE_IDLE]     = handle_idle,
    [STATE_INIT]     = handle_init,
    [STATE_RUNNING]  = handle_running,
    [STATE_PAUSED]   = handle_paused,
    [STATE_ERROR]    = handle_error,
    [STATE_SHUTDOWN] = handle_shutdown,
};

State process_event_funcptr(State current, Event event) {
    if (current < STATE_COUNT && state_handlers[current]) {
        return state_handlers[current](event);
    }
    return STATE_ERROR;
}

/* Full state machine with entry/exit actions */
void sm_init(void) {
    g_sm.current_state = STATE_IDLE;
    g_sm.previous_state = STATE_IDLE;
    g_sm.state_enter_time = 0;
    g_sm.error_count = 0;
    g_sm.transition_count = 0;
}

void sm_process(Event event, uint32_t current_time) {
    State next = process_event_switch(g_sm.current_state, event);

    if (next != g_sm.current_state) {
        /* Exit current state */
        switch (g_sm.current_state) {
        case STATE_RUNNING:
            on_exit_running();
            break;
        default:
            break;
        }

        /* Transition */
        g_sm.previous_state = g_sm.current_state;
        g_sm.current_state = next;
        g_sm.state_enter_time = current_time;
        g_sm.transition_count++;

        /* Enter new state */
        switch (next) {
        case STATE_IDLE:     on_enter_idle(); break;
        case STATE_INIT:     on_enter_init(); break;
        case STATE_RUNNING:  on_enter_running(); break;
        case STATE_PAUSED:   on_enter_paused(); break;
        case STATE_ERROR:    on_enter_error(); break;
        case STATE_SHUTDOWN: on_enter_shutdown(); break;
        default: break;
        }
    }
}

State sm_get_state(void) {
    return g_sm.current_state;
}

uint32_t sm_get_error_count(void) {
    return g_sm.error_count;
}

uint32_t sm_time_in_state(uint32_t current_time) {
    return current_time - g_sm.state_enter_time;
}

