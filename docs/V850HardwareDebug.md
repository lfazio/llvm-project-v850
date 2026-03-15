# V850 Hardware Debug Guide

This document describes the V850 hardware debug architecture and how to use it from C code via the `<v850_debug.h>` helper header.

## Table of Contents

1. [Overview](#1-overview)
2. [Debug Architecture](#2-debug-architecture)
3. [BPC Register Layout](#3-bpc-register-layout)
4. [DIR Register — Channel Selection](#4-dir-register--channel-selection)
5. [Examples](#5-examples)
6. [Helper Header Reference](#6-helper-header-reference)
7. [Limitations](#7-limitations)

---

## 1. Overview

V850E1 and later variants include on-chip debug support with:

- **2 breakpoint channels** — each independently configurable
- **Address matching** — break when a specific address (or range) is accessed
- **Data matching** — break when a specific data value is read/written
- **Combined matching** — break on address AND data match simultaneously
- **Software breakpoints** — DBTRAP instruction triggers the debug handler

The debug system uses dedicated system registers (DBPC, DBPSW, DIR, BPC, BPAV, BPAM, BPDV, BPDM) accessible via privileged instructions (LDSR/STSR).

---

## 2. Debug Architecture

### Debug Exception Flow

When a breakpoint condition is met (or DBTRAP is executed):

1. PC is saved to **DBPC** (Debug saved Program Counter)
2. PSW is saved to **DBPSW** (Debug saved Program Status Word)
3. Execution transfers to the debug handler
4. **DBRET** instruction returns from the handler (restores PC and PSW)

### Debug Registers

| Register | regID | Access | Description |
|----------|-------|--------|-------------|
| DBPC     | 18    | R/W    | Debug saved PC |
| DBPSW    | 19    | R/W    | Debug saved PSW |
| DIR      | 21    | R/W    | Debug Interface Register (channel select) |
| BPC      | 22    | R/W    | Breakpoint Control (per-channel config) |
| BPAV     | 24    | R/W    | Breakpoint Address Value |
| BPAM     | 25    | R/W    | Breakpoint Address Mask |
| BPDV     | 26    | R/W    | Breakpoint Data Value |
| BPDM     | 27    | R/W    | Breakpoint Data Mask |

All registers are accessed via the `STSR`/`LDSR` instructions, exposed through `__builtin_v850_read_*` and `__builtin_v850_write_*` builtins.

---

## 3. BPC Register Layout

The BPC register controls breakpoint behavior for the currently selected channel.

| Bit | Name         | Description |
|-----|--------------|-------------|
| 0   | EN           | Enable breakpoint |
| 1   | ADDR_MATCH   | Break on address match |
| 2   | DATA_MATCH   | Break on data match |
| 3   | ADDR_DATA    | Break on address AND data match |
| 4   | READ         | Break on read access |
| 5   | WRITE        | Break on write access |
| 6   | FETCH        | Break on instruction fetch |
| 7   | DATA_ACCESS  | Break on data access |

**Common configurations:**

| Use Case | BPC Value |
|----------|-----------|
| Address breakpoint (any access) | `V850_BPC_EN \| V850_BPC_ADDR_MATCH` |
| Code breakpoint (fetch only) | `V850_BPC_EN \| V850_BPC_ADDR_MATCH \| V850_BPC_FETCH` |
| Data watchpoint (write only) | `V850_BPC_EN \| V850_BPC_DATA_MATCH \| V850_BPC_WRITE` |
| Address+data (read) | `V850_BPC_EN \| V850_BPC_ADDR_DATA \| V850_BPC_READ` |

---

## 4. DIR Register — Channel Selection

The DIR (Debug Interface Register) controls which breakpoint channel is active for register access.

| Bit | Name | Description |
|-----|------|-------------|
| 0   | CS   | Channel Select: 0 = channel 0, 1 = channel 1 |

When DIR.CS = 0, reads/writes to BPC, BPAV, BPAM, BPDV, BPDM affect **channel 0**.
When DIR.CS = 1, they affect **channel 1**.

Use `v850_select_bp_channel(0)` or `v850_select_bp_channel(1)` to switch.

---

## 5. Examples

### 5.1 Setting an Address Breakpoint on Channel 0

Break when the CPU accesses address `0x1000`:

```c
#include <v850_debug.h>

void setup_addr_breakpoint(void) {
    v850_select_bp_channel(0);
    v850_set_address_breakpoint(0x00001000, 0x00000000);
    /* mask=0 means exact address match */
}
```

### 5.2 Setting a Data Watchpoint on Channel 1

Break when data value `0xDEADBEEF` is written:

```c
#include <v850_debug.h>

void setup_data_watchpoint(void) {
    v850_select_bp_channel(1);
    v850_set_data_breakpoint(0xDEADBEEF, 0x00000000);
    /* Optionally restrict to writes only: */
    unsigned int bpc = v850_read_bpc();
    bpc |= V850_BPC_WRITE;
    v850_write_bpc(bpc);
}
```

### 5.3 Using Both Channels Simultaneously

Channel 0 watches an address range, channel 1 watches a data value:

```c
#include <v850_debug.h>

void setup_dual_breakpoints(void) {
    /* Channel 0: break on access to 0x2000-0x200F (16-byte range) */
    v850_select_bp_channel(0);
    v850_set_address_breakpoint(0x00002000, 0x0000000F);

    /* Channel 1: break when 0xFF is written anywhere */
    v850_select_bp_channel(1);
    v850_set_data_breakpoint(0x000000FF, 0xFFFFFF00);
    unsigned int bpc = v850_read_bpc();
    bpc |= V850_BPC_WRITE;
    v850_write_bpc(bpc);
}
```

### 5.4 Software Breakpoints with DBTRAP

Insert a software breakpoint directly in code:

```c
#include <v850_debug.h>

void my_function(int *data) {
    /* ... some processing ... */

    if (*data == 0) {
        /* Unexpected condition — break into debugger */
        v850_breakpoint();
    }

    /* ... continue processing ... */
}
```

### 5.5 Clearing Breakpoints

```c
#include <v850_debug.h>

void teardown_breakpoints(void) {
    v850_select_bp_channel(0);
    v850_clear_address_breakpoint();

    v850_select_bp_channel(1);
    v850_clear_data_breakpoint();
}
```

---

## 6. Helper Header Reference

### Header

```c
#include <v850_debug.h>
```

Requires: `-mcpu=v850e1` or later.

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `V850_BPC_EN` | `(1U << 0)` | Enable breakpoint |
| `V850_BPC_ADDR_MATCH` | `(1U << 1)` | Break on address match |
| `V850_BPC_DATA_MATCH` | `(1U << 2)` | Break on data match |
| `V850_BPC_ADDR_DATA` | `(1U << 3)` | Break on address AND data |
| `V850_BPC_READ` | `(1U << 4)` | Break on read |
| `V850_BPC_WRITE` | `(1U << 5)` | Break on write |
| `V850_BPC_FETCH` | `(1U << 6)` | Break on instruction fetch |
| `V850_BPC_DATA_ACCESS` | `(1U << 7)` | Break on data access |
| `V850_DIR_CS` | `(1U << 0)` | DIR channel select bit |

### Functions

| Function | Description |
|----------|-------------|
| `v850_breakpoint()` | Software breakpoint (DBTRAP) |
| `v850_select_bp_channel(ch)` | Select breakpoint channel 0 or 1 |
| `v850_set_address_breakpoint(addr, mask)` | Set address breakpoint on current channel |
| `v850_clear_address_breakpoint()` | Clear address breakpoint on current channel |
| `v850_set_data_breakpoint(data, mask)` | Set data watchpoint on current channel |
| `v850_clear_data_breakpoint()` | Clear data watchpoint on current channel |
| `v850_read_dbpc()` / `v850_write_dbpc(val)` | Debug saved PC |
| `v850_read_dbpsw()` / `v850_write_dbpsw(val)` | Debug saved PSW |
| `v850_read_dir()` / `v850_write_dir(val)` | Debug Interface Register |
| `v850_read_bpc()` / `v850_write_bpc(val)` | Breakpoint Control |
| `v850_read_bpav()` / `v850_write_bpav(val)` | Breakpoint Address Value |
| `v850_read_bpam()` / `v850_write_bpam(val)` | Breakpoint Address Mask |
| `v850_read_bpdv()` / `v850_write_bpdv(val)` | Breakpoint Data Value |
| `v850_read_bpdm()` / `v850_write_bpdm(val)` | Breakpoint Data Mask |

---

## 7. Limitations

1. **Only 2 breakpoint channels.** You cannot have more than 2 independent breakpoint conditions active simultaneously.

2. **Address matching granularity.** The mask determines which address bits are compared. A mask of `0x00000000` matches a single address; larger masks match wider regions but always power-of-2 aligned.

3. **Data matching is value-based.** The hardware compares the data being transferred, not the contents at a specific address. To watch a specific variable for a specific value, use the combined address+data mode (`V850_BPC_ADDR_DATA`).

4. **Privileged access required.** All debug registers are system registers accessed via `LDSR`/`STSR`, which require supervisor privilege.

5. **Channel state is global.** Switching channels with `v850_select_bp_channel()` affects all subsequent register accesses. Always select the correct channel before configuring.

6. **No data breakpoint size control.** The hardware matches 32-bit values. For 8-bit or 16-bit watches, use the data mask to ignore irrelevant bytes.

---

## References

- [V850 Debug Plan](../plans/v850-debug.md) — Implementation status and LLDB integration
- [V850 Intrinsics Reference](../plans/v850-intrinsics.md) — Complete list of V850 builtins
- NEC V850 Family User's Manual — Debug chapter
