/*===---- v850_debug.h - V850 hardware debug helpers ----------------------===
 *
 * Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
 * See https://llvm.org/LICENSE.txt for license information.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 *
 *===----------------------------------------------------------------------===
 *
 * This header provides convenience macros and inline functions for V850
 * hardware debug features: software breakpoints, address breakpoints,
 * data watchpoints, and breakpoint channel management.
 *
 * Requires V850E1 or later (-mcpu=v850e1 / -mcpu=v850e2m / -mcpu=g3m / ...).
 *
 *===----------------------------------------------------------------------===*/

#ifndef __V850_DEBUG_H
#define __V850_DEBUG_H

#if !defined(__v850__)
#error "This header is for V850 targets only"
#endif

/*
 * BPC (Breakpoint Control) register bit definitions.
 *
 * The BPC register configures breakpoint behavior for the currently
 * selected channel (selected via DIR.CS bit, see v850_select_bp_channel).
 *
 * Layout (per channel):
 *   Bit 0:  Enable breakpoint
 *   Bit 1:  Break on address match
 *   Bit 2:  Break on data match
 *   Bit 3:  Break on address AND data match
 *   Bit 4:  Break on read access
 *   Bit 5:  Break on write access
 *   Bit 6:  Break on instruction fetch
 *   Bit 7:  Break on data access
 */
#define V850_BPC_EN          (1U << 0)  /* Enable breakpoint */
#define V850_BPC_ADDR_MATCH  (1U << 1)  /* Break on address match */
#define V850_BPC_DATA_MATCH  (1U << 2)  /* Break on data match */
#define V850_BPC_ADDR_DATA   (1U << 3)  /* Break on address AND data match */
#define V850_BPC_READ        (1U << 4)  /* Break on read access */
#define V850_BPC_WRITE       (1U << 5)  /* Break on write access */
#define V850_BPC_FETCH       (1U << 6)  /* Break on instruction fetch */
#define V850_BPC_DATA_ACCESS (1U << 7)  /* Break on data access */

/*
 * DIR (Debug Interface Register) bit definitions.
 */
#define V850_DIR_CS          (1U << 0)  /* Channel select: 0=ch0, 1=ch1 */

/* ---- Software Breakpoint ------------------------------------------------ */

/**
 * Trigger a software breakpoint (DBTRAP instruction).
 *
 * Saves PC to DBPC and PSW to DBPSW, then enters the debug handler.
 * Use DBRET to return from the handler.
 */
static __inline__ void __attribute__((__always_inline__))
v850_breakpoint(void) {
  __builtin_v850_dbtrap();
}

/* ---- Breakpoint Channel Selection --------------------------------------- */

/**
 * Select breakpoint channel (0 or 1).
 *
 * V850E1+ has 2 breakpoint channels. Each channel has independent
 * BPAV/BPAM (address) and BPDV/BPDM (data) registers. The currently
 * selected channel is determined by DIR.CS (bit 0 of the DIR register).
 *
 * After selecting a channel, reads/writes to BPC, BPAV, BPAM, BPDV, BPDM
 * apply to that channel.
 */
static __inline__ void __attribute__((__always_inline__))
v850_select_bp_channel(unsigned int channel) {
  __builtin_v850_select_bp_channel(channel);
}

/* ---- Debug Register Accessors ------------------------------------------- */

/** Read/write DBPC (Debug saved Program Counter). */
static __inline__ unsigned int __attribute__((__always_inline__))
v850_read_dbpc(void) {
  return __builtin_v850_read_dbpc();
}

static __inline__ void __attribute__((__always_inline__))
v850_write_dbpc(unsigned int val) {
  __builtin_v850_write_dbpc(val);
}

/** Read/write DBPSW (Debug saved Program Status Word). */
static __inline__ unsigned int __attribute__((__always_inline__))
v850_read_dbpsw(void) {
  return __builtin_v850_read_dbpsw();
}

static __inline__ void __attribute__((__always_inline__))
v850_write_dbpsw(unsigned int val) {
  __builtin_v850_write_dbpsw(val);
}

/** Read DIR (Debug Interface Register). */
static __inline__ unsigned int __attribute__((__always_inline__))
v850_read_dir(void) {
  return __builtin_v850_read_dir();
}

/** Write DIR (Debug Interface Register). */
static __inline__ void __attribute__((__always_inline__))
v850_write_dir(unsigned int val) {
  __builtin_v850_write_dir(val);
}

/** Read/write BPC (Breakpoint Control). */
static __inline__ unsigned int __attribute__((__always_inline__))
v850_read_bpc(void) {
  return __builtin_v850_read_bpc();
}

static __inline__ void __attribute__((__always_inline__))
v850_write_bpc(unsigned int val) {
  __builtin_v850_write_bpc(val);
}

/** Read/write BPAV (Breakpoint Address Value). */
static __inline__ unsigned int __attribute__((__always_inline__))
v850_read_bpav(void) {
  return __builtin_v850_read_bpav();
}

static __inline__ void __attribute__((__always_inline__))
v850_write_bpav(unsigned int val) {
  __builtin_v850_write_bpav(val);
}

/** Read/write BPAM (Breakpoint Address Mask). */
static __inline__ unsigned int __attribute__((__always_inline__))
v850_read_bpam(void) {
  return __builtin_v850_read_bpam();
}

static __inline__ void __attribute__((__always_inline__))
v850_write_bpam(unsigned int val) {
  __builtin_v850_write_bpam(val);
}

/** Read/write BPDV (Breakpoint Data Value). */
static __inline__ unsigned int __attribute__((__always_inline__))
v850_read_bpdv(void) {
  return __builtin_v850_read_bpdv();
}

static __inline__ void __attribute__((__always_inline__))
v850_write_bpdv(unsigned int val) {
  __builtin_v850_write_bpdv(val);
}

/** Read/write BPDM (Breakpoint Data Mask). */
static __inline__ unsigned int __attribute__((__always_inline__))
v850_read_bpdm(void) {
  return __builtin_v850_read_bpdm();
}

static __inline__ void __attribute__((__always_inline__))
v850_write_bpdm(unsigned int val) {
  __builtin_v850_write_bpdm(val);
}

/* ---- Address Breakpoint Helpers ----------------------------------------- */

/**
 * Set an address breakpoint on the currently selected channel.
 *
 * Triggers a debug exception when the CPU accesses an address matching:
 *   (access_addr & ~mask) == (addr & ~mask)
 *
 * Use mask=0x00000000 for an exact address match.
 * Use mask=0x0000000F to match a 16-byte aligned region.
 *
 * @param addr  Address to break on.
 * @param mask  Address mask (1 bits are don't-care).
 */
static __inline__ void __attribute__((__always_inline__))
v850_set_address_breakpoint(unsigned int addr, unsigned int mask) {
  __builtin_v850_write_bpav(addr);
  __builtin_v850_write_bpam(mask);
  unsigned int bpc = __builtin_v850_read_bpc();
  bpc |= V850_BPC_EN | V850_BPC_ADDR_MATCH;
  __builtin_v850_write_bpc(bpc);
}

/**
 * Clear the address breakpoint on the currently selected channel.
 *
 * Disables the breakpoint and resets address value/mask to zero.
 */
static __inline__ void __attribute__((__always_inline__))
v850_clear_address_breakpoint(void) {
  unsigned int bpc = __builtin_v850_read_bpc();
  bpc &= ~(V850_BPC_EN | V850_BPC_ADDR_MATCH);
  __builtin_v850_write_bpc(bpc);
  __builtin_v850_write_bpav(0);
  __builtin_v850_write_bpam(0);
}

/* ---- Data Watchpoint Helpers -------------------------------------------- */

/**
 * Set a data watchpoint on the currently selected channel.
 *
 * Triggers a debug exception when data matching:
 *   (data_value & ~mask) == (data & ~mask)
 *
 * is read from or written to memory.
 *
 * Use mask=0x00000000 for an exact data match.
 *
 * @param data  Data value to watch for.
 * @param mask  Data mask (1 bits are don't-care).
 */
static __inline__ void __attribute__((__always_inline__))
v850_set_data_breakpoint(unsigned int data, unsigned int mask) {
  __builtin_v850_write_bpdv(data);
  __builtin_v850_write_bpdm(mask);
  unsigned int bpc = __builtin_v850_read_bpc();
  bpc |= V850_BPC_EN | V850_BPC_DATA_MATCH;
  __builtin_v850_write_bpc(bpc);
}

/**
 * Clear the data watchpoint on the currently selected channel.
 *
 * Disables the data breakpoint and resets data value/mask to zero.
 */
static __inline__ void __attribute__((__always_inline__))
v850_clear_data_breakpoint(void) {
  unsigned int bpc = __builtin_v850_read_bpc();
  bpc &= ~(V850_BPC_EN | V850_BPC_DATA_MATCH);
  __builtin_v850_write_bpc(bpc);
  __builtin_v850_write_bpdv(0);
  __builtin_v850_write_bpdm(0);
}

#endif /* __V850_DEBUG_H */
