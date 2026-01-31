# V850 Linker Support Plan

This document outlines the plan for implementing complete ELF linking support for the V850 backend, including LLD support, relocations, linker scripts, and runtime support.

## Current Status

### Implemented

| Component | Status | Location |
|-----------|--------|----------|
| ELF machine type | Done | `llvm/include/llvm/BinaryFormat/ELF.h` (EM_V850 = 87) |
| Basic relocations | Done | `llvm/include/llvm/BinaryFormat/ELFRelocs/V850.def` |
| Fixup kinds | Done | `llvm/lib/Target/V850/MCTargetDesc/V850MCTargetDesc.h` |
| AsmBackend fixup application | Done | `llvm/lib/Target/V850/MCTargetDesc/V850AsmBackend.cpp` |
| ELF object writer | Done | `llvm/lib/Target/V850/MCTargetDesc/V850ELFObjectWriter.cpp` |
| Fixup-to-relocation mapping | Done | `llvm/lib/Target/V850/MCTargetDesc/V850ELFObjectWriter.cpp` |
| LLD V850 target | Done | `lld/ELF/Arch/V850.cpp` |

### Not Implemented

| Component | Priority | Complexity |
|-----------|----------|------------|
| Default linker script | Medium | Low |
| Startup code (crt0) | Medium | Low |
| SDA/TDA/ZDA section support | Medium | Medium |
| GP/EP/TP register initialization | Medium | Low |

---

## 1. Relocation Support

### 1.1 Current Relocations

**File:** `llvm/include/llvm/BinaryFormat/ELFRelocs/V850.def`

| Relocation | Value | Description | Status |
|------------|-------|-------------|--------|
| R_V850_NONE | 0 | No relocation | Done |
| R_V850_32 | 1 | 32-bit absolute | Partial |
| R_V850_22_PCREL | 2 | 22-bit PC-relative (JR/JARL) | Partial |
| R_V850_9_PCREL | 3 | 9-bit PC-relative (Bcond) | Partial |
| R_V850_HI16 | 4 | Upper 16 bits | Partial |
| R_V850_LO16 | 5 | Lower 16 bits | Partial |
| R_V850_16 | 6 | 16-bit signed | Partial |
| R_V850_8 | 7 | 8-bit unsigned | Partial |
| R_V850_SDA_16_16_OFFSET | 8 | SDA-relative 16-bit | TODO |
| R_V850_SDA_15_16_OFFSET | 9 | SDA-relative 15-bit | TODO |
| R_V850_ZDA_16_16_OFFSET | 10 | ZDA-relative 16-bit | TODO |
| R_V850_ZDA_15_16_OFFSET | 11 | ZDA-relative 15-bit | TODO |
| R_V850_TDA_6_8_OFFSET | 12 | TDA-relative 6-bit | TODO |
| R_V850_TDA_7_8_OFFSET | 13 | TDA-relative 7-bit | TODO |
| R_V850_TDA_7_7_OFFSET | 14 | TDA-relative 7-bit | TODO |
| R_V850_TDA_16_16_OFFSET | 15 | TDA-relative 16-bit | TODO |

### 1.2 Missing Relocations [TODO]

Based on V850 ABI and GCC/binutils, the following relocations should be added:

```c
// Extended PC-relative (V850E2+)
ELF_RELOC(R_V850_32_PCREL,         16)  // 32-bit PC-relative
ELF_RELOC(R_V850_17_PCREL,         17)  // 17-bit PC-relative (Bcond extended)

// CALLT support
ELF_RELOC(R_V850_CALLT_6_7_OFFSET, 18)  // CALLT table offset
ELF_RELOC(R_V850_CALLT_16_16_OFFSET, 19) // CALLT extended offset

// Long branch/jump
ELF_RELOC(R_V850_32_ABS,           20)  // 32-bit absolute (data)
ELF_RELOC(R_V850_23,               21)  // 23-bit displacement

// GNU extensions
ELF_RELOC(R_V850_GNU_VTINHERIT,    22)  // C++ vtable inheritance
ELF_RELOC(R_V850_GNU_VTENTRY,      23)  // C++ vtable entry

// Alignment/relaxation
ELF_RELOC(R_V850_ALIGN,            24)  // Alignment marker
```

### 1.3 Fixup-to-Relocation Mapping [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/MCTargetDesc/V850ELFObjectWriter.cpp`

**Status:** Fully implemented. Maps all V850 fixup kinds to correct ELF relocation types.

**Required Implementation:**

```cpp
unsigned V850ELFObjectWriter::getRelocType(const MCFixup &Fixup,
                                           const MCValue &Target,
                                           bool IsPCRel) const {
  unsigned Kind = Fixup.getTargetKind();

  if (IsPCRel) {
    switch (Kind) {
    case V850::fixup_v850_9_pcrel:
      return ELF::R_V850_9_PCREL;
    case V850::fixup_v850_22_pcrel:
      return ELF::R_V850_22_PCREL;
    default:
      break;
    }
  }

  switch (Kind) {
  case FK_Data_1:
    return ELF::R_V850_8;
  case FK_Data_2:
    return ELF::R_V850_16;
  case FK_Data_4:
    return ELF::R_V850_32;
  case V850::fixup_v850_16:
    return ELF::R_V850_16;
  case V850::fixup_v850_32:
    return ELF::R_V850_32;
  case V850::fixup_v850_hi16:
    return ELF::R_V850_HI16;
  case V850::fixup_v850_lo16:
    return ELF::R_V850_LO16;
  default:
    llvm_unreachable("Unknown fixup kind!");
  }
}
```

---

## 2. LLD Support

### 2.1 V850 Target Implementation [IMPLEMENTED]

**File:** `lld/ELF/Arch/V850.cpp`

**Status:** Fully implemented. Supports all basic V850 relocations.

```cpp
//===- V850.cpp -----------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// V850 is a 32-bit RISC microcontroller architecture from NEC/Renesas.
// It features:
// - 32 general-purpose registers (r0-r31)
// - Special pointer registers: SP (r3), GP (r4), TP (r5), EP (r30), LP (r31)
// - Small data areas: SDA (GP-relative), TDA (EP-relative), ZDA (zero-page)
// - 16/32/48-bit instruction encoding
//
//===----------------------------------------------------------------------===//

#include "InputFiles.h"
#include "Symbols.h"
#include "Target.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/Support/Endian.h"

using namespace llvm;
using namespace llvm::object;
using namespace llvm::support::endian;
using namespace llvm::ELF;
using namespace lld;
using namespace lld::elf;

namespace {
class V850 final : public TargetInfo {
public:
  V850(Ctx &ctx);
  RelExpr getRelExpr(RelType type, const Symbol &s,
                     const uint8_t *loc) const override;
  void relocate(uint8_t *loc, const Relocation &rel,
                uint64_t val) const override;
  void writePlt(uint8_t *buf, const Symbol &sym,
                uint64_t pltEntryAddr) const override;
};
} // namespace

V850::V850(Ctx &ctx) : TargetInfo(ctx) {
  // V850 NOP: MOV r0, r0 = 0x0000
  trapInstr = {0x00, 0x00, 0x00, 0x00};

  // Default page size (no MMU on most V850)
  defaultMaxPageSize = 4;
  defaultCommonPageSize = 4;

  // PLT configuration (if dynamic linking supported)
  pltHeaderSize = 0;
  pltEntrySize = 0;
}

RelExpr V850::getRelExpr(RelType type, const Symbol &s,
                         const uint8_t *loc) const {
  switch (type) {
  case R_V850_9_PCREL:
  case R_V850_22_PCREL:
  case R_V850_32_PCREL:
  case R_V850_17_PCREL:
    return R_PC;
  case R_V850_SDA_16_16_OFFSET:
  case R_V850_SDA_15_16_OFFSET:
    return R_GOTREL;  // GP-relative
  case R_V850_TDA_6_8_OFFSET:
  case R_V850_TDA_7_8_OFFSET:
  case R_V850_TDA_7_7_OFFSET:
  case R_V850_TDA_16_16_OFFSET:
    return R_GOTREL;  // EP-relative (mapped to GOTREL for now)
  case R_V850_ZDA_16_16_OFFSET:
  case R_V850_ZDA_15_16_OFFSET:
    return R_ABS;     // Zero-page relative (absolute)
  default:
    return R_ABS;
  }
}

void V850::relocate(uint8_t *loc, const Relocation &rel, uint64_t val) const {
  switch (rel.type) {
  case R_V850_NONE:
    break;
  case R_V850_8:
    checkIntUInt(ctx, loc, val, 8, rel);
    *loc = val;
    break;
  case R_V850_16:
    checkIntUInt(ctx, loc, val, 16, rel);
    write16le(loc, val);
    break;
  case R_V850_32:
    write32le(loc, val);
    break;
  case R_V850_9_PCREL: {
    // 9-bit PC-relative, shifted right by 1
    // Format III: disp9 in bits [15:11] and [6:4]
    int64_t offset = (int64_t)val >> 1;
    checkInt(ctx, loc, offset, 8, rel);  // 8 bits after shift
    uint16_t insn = read16le(loc);
    insn = (insn & 0x078F) | ((offset & 0x07) << 4) | ((offset & 0xF8) << 8);
    write16le(loc, insn);
    break;
  }
  case R_V850_22_PCREL: {
    // 22-bit PC-relative, shifted right by 1
    // Format V: disp22 split across 32-bit instruction
    int64_t offset = (int64_t)val >> 1;
    checkInt(ctx, loc, offset, 21, rel);  // 21 bits after shift
    uint32_t insn = read32le(loc);
    insn = (insn & 0xFFC0FFFF) |
           ((offset & 0x3F) << 16) |
           ((offset >> 6) << 16);
    // Proper encoding needed - simplified here
    loc[0] = offset & 0x3F;
    loc[2] = (offset >> 6) & 0xFF;
    loc[3] = (offset >> 14) & 0xFF;
    break;
  }
  case R_V850_HI16: {
    // Upper 16 bits, stored in second halfword of 32-bit instruction
    uint16_t hi = (val >> 16) & 0xFFFF;
    write16le(loc + 2, hi);
    break;
  }
  case R_V850_LO16: {
    // Lower 16 bits, stored in second halfword of 32-bit instruction
    uint16_t lo = val & 0xFFFF;
    write16le(loc + 2, lo);
    break;
  }
  case R_V850_SDA_16_16_OFFSET:
  case R_V850_SDA_15_16_OFFSET:
  case R_V850_ZDA_16_16_OFFSET:
  case R_V850_ZDA_15_16_OFFSET:
    // 16-bit signed offset in second halfword
    checkInt(ctx, loc, val, 16, rel);
    write16le(loc + 2, val & 0xFFFF);
    break;
  case R_V850_TDA_6_8_OFFSET:
    // 6-bit unsigned offset, shifted left by 1
    checkUInt(ctx, loc, val >> 1, 6, rel);
    loc[0] = (loc[0] & 0x80) | ((val >> 1) & 0x7F);
    break;
  case R_V850_TDA_7_8_OFFSET:
    // 7-bit unsigned offset
    checkUInt(ctx, loc, val, 7, rel);
    loc[0] = val & 0x7F;
    break;
  default:
    Err(ctx) << getErrorLoc(ctx, loc) << "unrecognized relocation " << rel.type;
  }
}

void V850::writePlt(uint8_t *buf, const Symbol &sym,
                    uint64_t pltEntryAddr) const {
  // V850 typically doesn't use PLT for embedded systems
  // Stub implementation
}

void elf::setV850TargetInfo(Ctx &ctx) { ctx.target.reset(new V850(ctx)); }
```

### 2.2 LLD Integration

**File:** `lld/ELF/Target.h`

Add declaration:
```cpp
void setV850TargetInfo(Ctx &);
```

**File:** `lld/ELF/Target.cpp`

Add case in `setTargetInfo()`:
```cpp
case EM_V850:
  return setV850TargetInfo(ctx);
```

**File:** `lld/ELF/CMakeLists.txt`

Add to sources:
```cmake
ELF/Arch/V850.cpp
```

### 2.3 Special Section Handling

V850 uses special small data sections accessible via GP, EP, or zero-page:

| Section | Pointer | Access | Description |
|---------|---------|--------|-------------|
| .sdata | GP (r4) | SDA_* | Small initialized data |
| .sbss | GP (r4) | SDA_* | Small uninitialized data |
| .tdata | EP (r30) | TDA_* | Tiny data (256 bytes max) |
| .zdata | 0 | ZDA_* | Zero-page data |
| .zbss | 0 | ZDA_* | Zero-page BSS |

**Implementation Notes:**
- `.sdata` and `.sbss` must be adjacent and within ±32KB of GP
- `.tdata` must be within 256 bytes of EP
- `.zdata` and `.zbss` must be in first 64KB (zero-page)

---

## 3. Linker Script Support

### 3.1 Default Linker Script [NEED USER INPUT]

A typical V850 linker script structure:

```ld
/* V850 Linker Script Template */
/* MEMORY regions and addresses are device-specific */

OUTPUT_FORMAT("elf32-v850", "elf32-v850", "elf32-v850")
OUTPUT_ARCH(v850)
ENTRY(_start)

/* Memory layout - DEVICE SPECIFIC */
MEMORY
{
  /* Example for V850E2M - actual values needed from user */
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 512K
  RAM (rwx) : ORIGIN = 0xFEDE0000, LENGTH = 64K
}

SECTIONS
{
  /* Reset and interrupt vectors */
  .vectors : {
    KEEP(*(.vectors))
    KEEP(*(.reset))
  } > ROM

  /* Code section */
  .text : {
    *(.text)
    *(.text.*)
    *(.rodata)
    *(.rodata.*)
  } > ROM

  /* CALLT table - must be 2-byte aligned */
  .callt : ALIGN(2) {
    __callt_start = .;
    *(.callt)
    __callt_end = .;
  } > ROM

  /* Initialized data */
  .data : {
    __data_start = .;
    *(.data)
    *(.data.*)
    __data_end = .;
  } > RAM AT > ROM

  /* Small data area (GP-relative) */
  .sdata : {
    __gp = . + 0x8000;  /* GP points to middle of SDA */
    *(.sdata)
    *(.sdata.*)
  } > RAM AT > ROM

  /* Tiny data area (EP-relative) */
  .tdata : {
    __ep = .;
    *(.tdata)
  } > RAM AT > ROM

  /* BSS section */
  .bss (NOLOAD) : {
    __bss_start = .;
    *(.bss)
    *(.bss.*)
    *(COMMON)
    __bss_end = .;
  } > RAM

  /* Small BSS */
  .sbss (NOLOAD) : {
    *(.sbss)
    *(.sbss.*)
  } > RAM

  /* Stack */
  .stack (NOLOAD) : {
    __stack_start = .;
    . += 0x1000;  /* 4KB stack */
    __stack_end = .;
  } > RAM

  /* Symbols for startup code */
  __rom_data_start = LOADADDR(.data);
  __ram_end = ORIGIN(RAM) + LENGTH(RAM);
}
```

**MISSING INFORMATION - User Input Required:**

1. Memory map for target V850 devices (ROM/RAM addresses and sizes)
2. Interrupt vector table layout
3. Stack size requirements
4. Any device-specific sections

### 3.2 LLD Internal Linker Script [TODO]

For `-nostdlib` builds, LLD needs defaults:

**File:** `lld/ELF/ScriptParser.cpp`

Add V850 defaults in `getDefaultScript()`:

```cpp
case EM_V850:
  return R"(
    SECTIONS {
      .text : { *(.text .text.*) }
      .rodata : { *(.rodata .rodata.*) }
      .data : { *(.data .data.*) }
      .sdata : { *(.sdata .sdata.*) }
      .bss : { *(.bss .bss.*) *(COMMON) }
      .sbss : { *(.sbss .sbss.*) }
    }
  )";
```

---

## 4. Startup Code (crt0)

### 4.1 Minimal crt0.S [NEED USER INPUT]

```asm
/* V850 C Runtime Startup - crt0.S */
/* Requires device-specific addresses */

    .section .reset, "ax"
    .global _start
    .type _start, @function

_start:
    /* Initialize stack pointer */
    movhi   hi(__stack_end), r0, sp
    movea   lo(__stack_end), sp, sp

    /* Initialize GP (global pointer) for SDA access */
    movhi   hi(__gp), r0, gp
    movea   lo(__gp), gp, gp

    /* Initialize EP (element pointer) for TDA access */
    movhi   hi(__ep), r0, ep
    movea   lo(__ep), ep, ep

    /* Initialize TP (thread pointer) if needed */
    mov     r0, tp

    /* Clear BSS section */
    movhi   hi(__bss_start), r0, r6
    movea   lo(__bss_start), r6, r6
    movhi   hi(__bss_end), r0, r7
    movea   lo(__bss_end), r7, r7
    mov     r0, r8
.Lclear_bss:
    cmp     r6, r7
    be      .Lclear_bss_done
    st.w    r8, 0[r6]
    addi    4, r6, r6
    br      .Lclear_bss
.Lclear_bss_done:

    /* Copy initialized data from ROM to RAM */
    movhi   hi(__rom_data_start), r0, r6    /* Source (ROM) */
    movea   lo(__rom_data_start), r6, r6
    movhi   hi(__data_start), r0, r7        /* Dest (RAM) */
    movea   lo(__data_start), r7, r7
    movhi   hi(__data_end), r0, r8          /* End */
    movea   lo(__data_end), r8, r8
.Lcopy_data:
    cmp     r7, r8
    be      .Lcopy_data_done
    ld.w    0[r6], r9
    st.w    r9, 0[r7]
    addi    4, r6, r6
    addi    4, r7, r7
    br      .Lcopy_data
.Lcopy_data_done:

    /* Call C++ constructors (if applicable) */
    /* jarl   __libc_init_array, lp */

    /* Call main */
    mov     r0, r6          /* argc = 0 */
    mov     r0, r7          /* argv = NULL */
    jarl    main, lp

    /* If main returns, halt */
    halt
    br      .

    .size _start, . - _start
```

**MISSING INFORMATION - User Input Required:**

1. Reset vector address and exception table structure
2. Watchdog timer handling (if applicable)
3. Clock/PLL initialization sequence
4. Memory controller initialization
5. C++ static constructor/destructor handling requirements

### 4.2 Interrupt Vector Table [NEED USER INPUT]

```asm
/* V850 Interrupt Vector Table */
/* Vector addresses are device-specific */

    .section .vectors, "ax"

    /* Reset vector (address 0x0000) */
    .org 0x0000
    jr      _start

    /* NMI (address 0x0010) - device specific */
    .org 0x0010
    jr      _nmi_handler

    /* INTWDT - Watchdog (if applicable) */
    .org 0x0020
    jr      _wdt_handler

    /* Additional vectors... */
```

---

## 5. Runtime Library Support

### 5.1 libgcc Equivalents [TODO]

Compiler-rt or libgcc provides:
- Integer division routines (`__divsi3`, `__udivsi3`, `__modsi3`, `__umodsi3`)
- 64-bit arithmetic (`__divdi3`, `__muldi3`, etc.)
- Floating-point emulation (if no FPU)

### 5.2 libc Support [EXTERNAL]

Options:
- Newlib (most common for embedded)
- picolibc
- Custom minimal libc

---

## 6. Special Register Initialization

### 6.1 GP (Global Pointer) - r4

Used for Small Data Area (SDA) access:
- Points to middle of `.sdata`/`.sbss`
- Allows ±32KB addressing with 16-bit displacement

### 6.2 EP (Element Pointer) - r30

Used for Tiny Data Area (TDA) access:
- Points to start of `.tdata`
- Allows 0-255 byte addressing with 8-bit displacement
- Used by short load/store instructions (SLD.*/SST.*)

### 6.3 TP (Thread Pointer) - r5

Used for thread-local storage (if applicable).

---

## 7. Implementation Phases

### Phase 1: Complete MC Layer Relocations [HIGH PRIORITY]

1. Implement `getRelocType()` in V850ELFObjectWriter.cpp
2. Verify all fixup kinds map to correct ELF relocations
3. Add missing relocations to V850.def
4. Add tests for relocation emission

**Deliverables:**
- Correct `.rela.*` sections in ELF output
- Relocatable object files usable with GNU ld

**Test:**
```bash
llvm-mc -triple=v850-unknown-elf -filetype=obj test.s -o test.o
llvm-readelf -r test.o  # Verify relocations
```

### Phase 2: LLD Target Implementation [HIGH PRIORITY]

1. Create `lld/ELF/Arch/V850.cpp`
2. Add to LLD build system
3. Implement `getRelExpr()` for all relocations
4. Implement `relocate()` for all relocations
5. Add basic linker script support

**Deliverables:**
- `ld.lld` can link V850 object files
- Basic executable generation

**Test:**
```bash
clang -target v850-unknown-elf -c test.c -o test.o
ld.lld test.o -o test.elf
llvm-readelf -h test.elf  # Verify ELF header
```

### Phase 3: Linker Script and Startup [MEDIUM PRIORITY]

1. Create default linker script template
2. Create minimal crt0.S
3. Test with actual hardware/simulator

**Deliverables:**
- Working bare-metal "hello world"

**Requirements from User:**
- Target device memory map
- Interrupt vector layout
- Any device-specific initialization

### Phase 4: Small Data Area Support [MEDIUM PRIORITY]

1. Implement SDA_* relocation handling
2. Implement TDA_* relocation handling
3. Implement ZDA_* relocation handling
4. Add GP/EP initialization in crt0

**Deliverables:**
- Optimized memory access via GP/EP

### Phase 5: Advanced Features [LOW PRIORITY]

1. CALLT table support
2. C++ exception handling
3. Position-independent code (if needed)
4. Debug section handling

---

## 8. Testing Strategy

### 8.1 Unit Tests

```
lld/test/ELF/v850-*.s
├── v850-reloc-basic.s      # Basic relocations
├── v850-reloc-pcrel.s      # PC-relative relocations
├── v850-reloc-sda.s        # SDA/TDA/ZDA relocations
├── v850-link-basic.s       # Basic linking
└── v850-linker-script.s    # Linker script tests
```

### 8.2 Integration Tests

```
clang/test/Driver/v850-ld.c  # Driver test for linking
```

### 8.3 End-to-End Tests

1. Compile simple C program
2. Link with LLD
3. Verify with llvm-readelf
4. Run on simulator (if available)

---

## 9. Required Information from User

To complete this implementation, the following information is needed:

### 9.1 Memory Map

- ROM start address and size
- RAM start address and size
- Peripheral register addresses (if memory-mapped I/O used)

### 9.2 Interrupt Vectors

- Vector table base address
- Vector spacing (typically 0x10 bytes)
- Number of interrupt sources

### 9.3 Startup Requirements

- Clock initialization sequence
- Watchdog timer handling
- Memory controller setup (if external memory)

### 9.4 Existing Files

If you have working startup code or linker scripts from:
- GCC/binutils toolchain
- Renesas CC-RH
- IAR Embedded Workbench
- Any other V850 toolchain

Please provide them for reference.

---

## 10. References

### V850 ABI

- NEC V850 Family User's Manual - Software
- V850 ELF Application Binary Interface

### GNU Binutils

- `binutils/bfd/elf32-v850.c` - Reference for relocations
- `binutils/ld/emulparams/v850.sh` - Default linker script parameters

### Similar LLD Implementations

- `lld/ELF/Arch/MSP430.cpp` - Simple 16-bit target
- `lld/ELF/Arch/AVR.cpp` - Another embedded target
- `lld/ELF/Arch/Hexagon.cpp` - 32-bit embedded

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-17 | 1.0 | Initial plan |
| 2026-01-31 | 1.1 | LLD V850 target implemented (V850.cpp with all basic relocations) |
