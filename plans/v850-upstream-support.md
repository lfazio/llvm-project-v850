# V850 Backend Upstream Plan

This document outlines the strategy for reworking the git history to prepare clean commits for upstreaming the V850 backend to LLVM.

## Reference Backends

The following backends provide good templates for upstream commit structure:

| Backend | RFC Discussion | Commits | Timeline |
|---------|---------------|---------|----------|
| **ARC** | [RFC: Adding ARC backend](https://discourse.llvm.org/t/rfc-adding-arc-backend/45855) | ~7 patches | Aug 2017 → LLVM 6.0 |
| **M68K** | [RFC: Backend for M68k](https://discourse.llvm.org/t/rfc-backend-for-motorola-6800-series-cpu-m68k/56850) | 9 patches | Nov 2020 → Mar 2021 |
| **LoongArch** | [RFC: Add LoongArch backend](https://discourse.llvm.org/t/rfc-add-a-new-backend-called-loongarch/59466) | 6 patches | Dec 2021 → Feb 2022 |

### Key Lessons from Reference Backends

1. **M68K**: Submit as numbered series `[1/N]` through `[N/N]`, request 2 LGTMs per patch, ping reviewers weekly
2. **LoongArch**: Small, incremental patches; extensive LIT tests; demonstrate hardware/emulator availability
3. **ARC**: Start as experimental target, focus on core C99 support first

---

## CPU Variant Hierarchy

The V850 architecture has evolved through several variants, each adding new instructions:

```
V850 (base)
  └── V850ES (minor extensions, same as V850E)
        └── V850E1 (MUL/DIV, CMOV, bit ops, SWITCH, PREPARE/DISPOSE)
              └── V850E2 (48-bit jumps, extended addressing)
                    └── V850E2M (DIVQ/DIVQU, CAXI, MAC/MACU, barriers)
                          └── V850E2M+FPU (single/double precision FPU)
                                └── RH850G3M (LDL.W/STC.W, SYNCI, SNOOZE, CLL, ROTL, BINS, LD.DW/ST.DW, LOOP, CACHE, PREF)
                                      └── RH850G3MH (additional features)
                                            └── RH850G4MH (FXU vector unit, virtualization)
```

Each variant is a **strict superset** of the previous one.

---

## Current State Analysis

- **Total V850 commits**: 95+
- **Components implemented**:
  - Target registration and triple support
  - ELF object file support
  - Register definitions with DWARF numbers
  - Core V850 instructions (base ISA)
  - V850ES/E1/E2/E2M instruction extensions
  - RH850G3M instruction extensions (SYNCI, SNOOZE, CLL, LDL.W, STC.W, ROTL, PUSHSP, POPSP, LOOP, CACHE, PREF, BINS, LD.DW, ST.DW)
  - FPU instructions (single and double precision)
  - MC layer (assembler, encoder, decoder)
  - Disassembler
  - AsmParser
  - CodeGen (SelectionDAG, ISel patterns)
  - Frame lowering (PREPARE/DISPOSE)
  - Atomic operations (CAXI, LDL.W/STC.W)
  - Clang driver integration
  - Clang builtins (including G3M: synci, snooze, cll, ldl_w, stc_w)
- **Optimizations implemented** (to be upstreamed separately):
  - Scheduling model (basic + V850E1 + V850E2M dual-issue)
  - Branch relaxation
  - Load/store optimizer
  - Tail call optimization
  - Machine outliner

---

## Proposed Commit Structure

Based on reference backends, **incremental CPU variant addition**, and **incremental optimization addition**, reorganize into **24 clean patches**:

### Phase 1: Infrastructure (Patches 1-4)

These patches establish the basic target infrastructure without any CPU-specific code.

---

#### Patch 1: [V850] Add V850 triple support

**Files:**
- `llvm/include/llvm/TargetParser/Triple.h`
- `llvm/lib/TargetParser/Triple.cpp`
- `llvm/unittests/TargetParser/TripleTest.cpp`

**Content:**
- Add `v850` architecture value (single arch, variants via features)
- Triple parsing for `v850-*-*-elf`
- Subtarget feature strings for variants (`+v850es`, `+v850e1`, etc.)

**Tests:**
- `llvm/unittests/TargetParser/TripleTest.cpp` (V850 cases)

---

#### Patch 2: [V850] Add V850 ELF definitions and relocations

**Files:**
- `llvm/include/llvm/BinaryFormat/ELF.h`
- `llvm/include/llvm/BinaryFormat/ELFRelocs/V850.def`
- `llvm/lib/Object/ELF.cpp`
- `llvm/lib/ObjectYAML/ELFYAML.cpp`

**Content:**
- ELF machine type `EM_V850` (87)
- V850 relocation types (R_V850_NONE, R_V850_9_PCREL, R_V850_22_PCREL, etc.)
- ELF flags for CPU variants (EF_V850_ARCH)

**Tests:**
- `llvm/test/Object/V850/elf-header.yaml`

---

#### Patch 3: [V850] Add V850 target stub with register definitions

**Files:**
- `llvm/lib/Target/V850/CMakeLists.txt`
- `llvm/lib/Target/V850/V850.h`
- `llvm/lib/Target/V850/V850.td`
- `llvm/lib/Target/V850/V850RegisterInfo.td`
- `llvm/lib/Target/V850/V850RegisterInfo.h`
- `llvm/lib/Target/V850/V850RegisterInfo.cpp`
- `llvm/lib/Target/V850/TargetInfo/V850TargetInfo.cpp`
- `llvm/lib/Target/V850/TargetInfo/CMakeLists.txt`
- `llvm/lib/Target/CMakeLists.txt`
- `llvm/CMakeLists.txt`

**Content:**
- Minimal target registration
- General purpose registers (r0-r31) with ABI names (zero, sp, gp, etc.)
- Base system registers (EIPC, EIPSW, FEPC, FEPSW, ECR, PSW)
- DWARF register numbers
- Register classes (GPR, GPRnoR0)
- Register allocation hints

**Tests:**
- `llvm/test/CodeGen/V850/reginfo.ll`

---

#### Patch 4: [V850] Add V850 instruction formats

**Files:**
- `llvm/lib/Target/V850/V850InstrFormats.td`

**Content:**
- All instruction format classes used by V850 family:
  - Format I (2 registers)
  - Format II (register + 5-bit immediate)
  - Format III (conditional branch)
  - Format IV (load/store 16-bit displacement)
  - Format V (jump with 22-bit displacement)
  - Format VI (3-register)
  - Format VII (load/store base+register)
  - Format VIII (bit manipulation)
  - Format IX (extended 2-register)
  - Format X (extended 1-register)
  - Format XI (extended 3-register)
  - Format XII (extended immediate)
  - Format XIII (stack operations)
  - Format XIV (48-bit, V850E2+)

**Tests:**
- None (infrastructure only, tested by subsequent patches)

---

### Phase 2: Base V850 - MC Layer (Patches 5-8)

These patches implement MC layer for base V850 ISA only.

---

#### Patch 5: [V850] Add base V850 instruction definitions

**Files:**
- `llvm/lib/Target/V850/V850InstrInfo.td` (base instructions only)
- `llvm/lib/Target/V850/V850InstrInfo.h`
- `llvm/lib/Target/V850/V850InstrInfo.cpp`

**Content:**
Base V850 instructions only (no V850E1+ instructions):
- Arithmetic: ADD, ADDI, SUB, SUBR, CMP, MOV, MOVEA, MOVHI, MULH, MULHI
- Logical: AND, ANDI, OR, ORI, XOR, XORI, NOT, TST
- Shift: SHL, SHR, SAR
- Branch: Bcond, JR, JARL
- Load/Store: LD.B, LD.H, LD.W, ST.B, ST.H, ST.W, SLD, SST
- Special: NOP, HALT, RETI, TRAP, LDSR, STSR
- Saturating: SATADD, SATSUB, SATSUBR

**Tests:**
- `llvm/test/MC/V850/base/arithmetic.s`
- `llvm/test/MC/V850/base/logical.s`
- `llvm/test/MC/V850/base/branch.s`
- `llvm/test/MC/V850/base/load-store.s`

---

#### Patch 6: [V850] Add V850 MCTargetDesc and assembly support

**Files:**
- `llvm/lib/Target/V850/MCTargetDesc/V850MCTargetDesc.h`
- `llvm/lib/Target/V850/MCTargetDesc/V850MCTargetDesc.cpp`
- `llvm/lib/Target/V850/MCTargetDesc/V850MCAsmInfo.h`
- `llvm/lib/Target/V850/MCTargetDesc/V850MCAsmInfo.cpp`
- `llvm/lib/Target/V850/MCTargetDesc/V850MCCodeEmitter.cpp`
- `llvm/lib/Target/V850/MCTargetDesc/V850AsmBackend.cpp`
- `llvm/lib/Target/V850/MCTargetDesc/V850ELFObjectWriter.cpp`
- `llvm/lib/Target/V850/MCTargetDesc/V850InstPrinter.h`
- `llvm/lib/Target/V850/MCTargetDesc/V850InstPrinter.cpp`
- `llvm/lib/Target/V850/MCTargetDesc/CMakeLists.txt`

**Content:**
- MC layer infrastructure
- Instruction encoding for base V850
- Assembly printing
- Fixup and relocation handling

**Tests:**
- `llvm/test/MC/V850/base/encoding.s`

---

#### Patch 7: [V850] Add V850 AsmParser

**Files:**
- `llvm/lib/Target/V850/AsmParser/V850AsmParser.cpp`
- `llvm/lib/Target/V850/AsmParser/CMakeLists.txt`

**Content:**
- Assembly parser
- Operand parsing (registers, immediates, memory operands)
- Directive handling
- Error diagnostics

**Tests:**
- `llvm/test/MC/V850/base/asm-parser.s`
- `llvm/test/MC/V850/base/asm-parser-errors.s`

---

#### Patch 8: [V850] Add V850 disassembler

**Files:**
- `llvm/lib/Target/V850/Disassembler/V850Disassembler.cpp`
- `llvm/lib/Target/V850/Disassembler/CMakeLists.txt`

**Content:**
- Instruction decoding for base V850
- Support for 16-bit and 32-bit instruction formats

**Tests:**
- `llvm/test/MC/Disassembler/V850/base.txt`

---

### Phase 3: Base V850 - CodeGen (Patches 9-10)

---

#### Patch 9: [V850] Add V850 CodeGen framework

**Files:**
- `llvm/lib/Target/V850/V850TargetMachine.h`
- `llvm/lib/Target/V850/V850TargetMachine.cpp`
- `llvm/lib/Target/V850/V850Subtarget.h`
- `llvm/lib/Target/V850/V850Subtarget.cpp`
- `llvm/lib/Target/V850/V850ISelLowering.h`
- `llvm/lib/Target/V850/V850ISelLowering.cpp`
- `llvm/lib/Target/V850/V850ISelDAGToDAG.h`
- `llvm/lib/Target/V850/V850ISelDAGToDAG.cpp`
- `llvm/lib/Target/V850/V850MCInstLower.h`
- `llvm/lib/Target/V850/V850MCInstLower.cpp`
- `llvm/lib/Target/V850/V850FrameLowering.h`
- `llvm/lib/Target/V850/V850FrameLowering.cpp`
- `llvm/lib/Target/V850/V850AsmPrinter.cpp`
- `llvm/lib/Target/V850/V850CallingConv.td`

**Content:**
- Target machine configuration
- Subtarget with feature flags (V850 base only)
- SelectionDAG lowering for base operations
- Basic instruction selection patterns
- Frame lowering (simple, no PREPARE/DISPOSE yet)
- Calling conventions

**Tests:**
- `llvm/test/CodeGen/V850/base/arithmetic.ll`
- `llvm/test/CodeGen/V850/base/branch.ll`
- `llvm/test/CodeGen/V850/base/load-store.ll`
- `llvm/test/CodeGen/V850/base/call.ll`
- `llvm/test/CodeGen/V850/base/frame.ll`

---

#### Patch 10: [V850] Add Clang driver for base V850

**Files:**
- `clang/lib/Basic/Targets/V850.h`
- `clang/lib/Basic/Targets/V850.cpp`
- `clang/lib/Basic/Targets.cpp`
- `clang/lib/Driver/ToolChains/V850.h`
- `clang/lib/Driver/ToolChains/V850.cpp`
- `clang/lib/Driver/Driver.cpp`

**Content:**
- V850 target info (base V850 only)
- Driver integration
- Preprocessor defines: `__v850__`
- Basic Clang builtins: `__builtin_v850_di`, `__builtin_v850_ei`, `__builtin_v850_ldsr`, `__builtin_v850_stsr`

**Tests:**
- `clang/test/Driver/v850.c`
- `clang/test/Preprocessor/v850.c`

---

### Phase 4: V850ES Extension (Patch 11)

---

#### Patch 11: [V850] Add V850ES CPU variant support

**Files:**
- `llvm/lib/Target/V850/V850.td` (add HasV850ES feature)
- `llvm/lib/Target/V850/V850InstrInfo.td` (V850ES instructions)
- `llvm/lib/Target/V850/V850Subtarget.cpp`
- `clang/lib/Basic/Targets/V850.cpp`

**Content:**
V850ES adds minor enhancements over base V850:
- `HasV850ES` subtarget feature
- CALLT instruction (call with table lookup)
- CTRET instruction (return from CALLT)
- ZXB, ZXH, SXB, SXH (sign/zero extend) instructions
- DBTRAP instruction
- Clang: `-mcpu=v850es`, `__v850es__` define

**Tests:**
- `llvm/test/MC/V850/v850es/instructions.s`
- `llvm/test/CodeGen/V850/v850es/sign-extend.ll`
- `clang/test/Driver/v850es.c`

---

### Phase 5: V850E1 Extension (Patches 12-13)

---

#### Patch 12: [V850] Add V850E1 instruction support

**Files:**
- `llvm/lib/Target/V850/V850.td` (add HasV850E1 feature)
- `llvm/lib/Target/V850/V850InstrInfo.td` (V850E1 instructions)
- `llvm/lib/Target/V850/V850RegisterInfo.td` (E1 system registers)

**Content:**
V850E1 is the major feature release adding:
- `HasV850E1` subtarget feature
- **Multiply/Divide**: MUL, MULU, DIV, DIVU, DIVH (native 32x32→64)
- **Conditional Move**: CMOV
- **Bit Operations**: SET1, CLR1, NOT1, TST1
- **Bit Search**: SCH0L, SCH0R, SCH1L, SCH1R (leading/trailing zero/one)
- **Byte Swap**: BSW, BSH, HSW
- **Stack**: PREPARE, DISPOSE (optimized prologue/epilogue)
- **Table Branch**: SWITCH
- **System Registers**: CTPC, CTPSW, CTBP, etc.

**Tests:**
- `llvm/test/MC/V850/v850e1/mul-div.s`
- `llvm/test/MC/V850/v850e1/bit-ops.s`
- `llvm/test/MC/V850/v850e1/cmov.s`
- `llvm/test/MC/V850/v850e1/prepare-dispose.s`

---

#### Patch 13: [V850] Add V850E1 CodeGen patterns and Clang support

**Files:**
- `llvm/lib/Target/V850/V850InstrInfo.td` (ISel patterns for E1)
- `llvm/lib/Target/V850/V850ISelLowering.cpp` (E1-specific lowering)
- `llvm/lib/Target/V850/V850FrameLowering.cpp` (PREPARE/DISPOSE)
- `clang/lib/Basic/Targets/V850.cpp`
- `clang/include/clang/Basic/BuiltinsV850.def`

**Content:**
- Pattern matching for native MUL/DIV
- CMOV for SELECT lowering
- `bswap` → BSW, HSW patterns
- `ctlz`/`cttz` → SCH1L/SCH1R/SCH0L/SCH0R patterns
- Frame lowering with PREPARE/DISPOSE
- Clang: `-mcpu=v850e1`, `__v850e1__` define
- Builtins: `__builtin_v850_set1`, `__builtin_v850_clr1`, `__builtin_v850_not1`, `__builtin_v850_tst1`, `__builtin_v850_bsh`, `__builtin_v850_hsw`

**Tests:**
- `llvm/test/CodeGen/V850/v850e1/mul.ll`
- `llvm/test/CodeGen/V850/v850e1/div.ll`
- `llvm/test/CodeGen/V850/v850e1/select.ll`
- `llvm/test/CodeGen/V850/v850e1/bswap.ll`
- `llvm/test/CodeGen/V850/v850e1/ctlz.ll`
- `llvm/test/CodeGen/V850/v850e1/frame-prepare-dispose.ll`
- `clang/test/CodeGen/V850/builtins-v850e1.c`

---

### Phase 6: V850E2 Extension (Patch 14)

---

#### Patch 14: [V850] Add V850E2 instruction support

**Files:**
- `llvm/lib/Target/V850/V850.td` (add HasV850E2 feature)
- `llvm/lib/Target/V850/V850InstrInfo.td` (V850E2 instructions)
- `llvm/lib/Target/V850/V850InstrFormats.td` (48-bit format updates)
- `llvm/lib/Target/V850/MCTargetDesc/V850MCCodeEmitter.cpp`
- `llvm/lib/Target/V850/Disassembler/V850Disassembler.cpp`
- `clang/lib/Basic/Targets/V850.cpp`

**Content:**
V850E2 extends addressing capabilities:
- `HasV850E2` subtarget feature
- **48-bit instructions**: JR32, JARL32 (32-bit displacement jumps)
- **Extended Load/Store**: LD.B/H/W with 23-bit displacement
- Support for 48-bit instruction encoding/decoding
- Clang: `-mcpu=v850e2`, `__v850e2__` define

**Tests:**
- `llvm/test/MC/V850/v850e2/48bit.s`
- `llvm/test/MC/Disassembler/V850/v850e2.txt`
- `llvm/test/CodeGen/V850/v850e2/large-displacement.ll`
- `clang/test/Driver/v850e2.c`

---

### Phase 7: V850E2M Extension (Patches 15-16)

---

#### Patch 15: [V850] Add V850E2M instruction support

**Files:**
- `llvm/lib/Target/V850/V850.td` (add HasV850E2M feature)
- `llvm/lib/Target/V850/V850InstrInfo.td` (V850E2M instructions)
- `llvm/lib/Target/V850/V850RegisterInfo.td` (E2M system registers)

**Content:**
V850E2M adds advanced features:
- `HasV850E2M` subtarget feature
- **Fast Divide**: DIVQ, DIVQU (fewer cycles than DIV/DIVU)
- **Atomic**: CAXI (compare-and-exchange)
- **Multiply-Accumulate**: MAC, MACU (32x32+64→64)
- **Memory Barriers**: SYNCP, SYNCM, SYNCE
- **System Registers**: EIWR, FEWR, DBWR, BSEL

**Tests:**
- `llvm/test/MC/V850/v850e2m/divq.s`
- `llvm/test/MC/V850/v850e2m/caxi.s`
- `llvm/test/MC/V850/v850e2m/mac.s`
- `llvm/test/MC/V850/v850e2m/barriers.s`

---

#### Patch 16: [V850] Add V850E2M CodeGen patterns and Clang support

**Files:**
- `llvm/lib/Target/V850/V850InstrInfo.td` (ISel patterns)
- `llvm/lib/Target/V850/V850ISelLowering.cpp` (atomic lowering)
- `clang/lib/Basic/Targets/V850.cpp`
- `clang/include/clang/Basic/BuiltinsV850.def`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp`

**Content:**
- Atomic operations via CAXI (cmpxchg, atomicrmw)
- MAC/MACU pattern matching
- Memory ordering with SYNCP/SYNCM/SYNCE
- Clang: `-mcpu=v850e2m`, `__v850e2m__` define
- Builtins: `__builtin_v850_syncp`, `__builtin_v850_syncm`, `__builtin_v850_synce`, `__builtin_v850_mac`, `__builtin_v850_macu`

**Tests:**
- `llvm/test/CodeGen/V850/v850e2m/atomic.ll`
- `llvm/test/CodeGen/V850/v850e2m/cmpxchg.ll`
- `llvm/test/CodeGen/V850/v850e2m/mac.ll`
- `clang/test/CodeGen/V850/builtins-v850e2m.c`

---

### Phase 8: FPU Support (Patches 17-18)

---

#### Patch 17: [V850] Add V850 FPU instruction support

**Files:**
- `llvm/lib/Target/V850/V850.td` (add HasFPU feature)
- `llvm/lib/Target/V850/V850RegisterInfo.td` (FPU registers)
- `llvm/lib/Target/V850/V850InstrFPU.td` (new file)
- `llvm/lib/Target/V850/V850InstrInfo.td` (include FPU)

**Content:**
FPU is optional on V850E2M+:
- `HasFPU` subtarget feature
- **FPU Registers**: Single (FR0-FR31), Double (DR0-DR30 pairs)
- **Arithmetic**: ADDF.S/D, SUBF.S/D, MULF.S/D, DIVF.S/D
- **Comparison**: CMPF.S/D with condition codes
- **Conversion**: CVTF.*, TRNCF.*, CEILF.*, FLOORF.*, ROUNDF.*
- **Move**: MOVF, ABSF, NEGF
- **Status**: TRFSR (transfer FPU status)

**Tests:**
- `llvm/test/MC/V850/fpu/arithmetic.s`
- `llvm/test/MC/V850/fpu/compare.s`
- `llvm/test/MC/V850/fpu/convert.s`
- `llvm/test/MC/Disassembler/V850/fpu.txt`

---

#### Patch 18: [V850] Add V850 FPU CodeGen and Clang support

**Files:**
- `llvm/lib/Target/V850/V850ISelLowering.cpp` (FP lowering)
- `llvm/lib/Target/V850/V850InstrFPU.td` (ISel patterns)
- `llvm/lib/Target/V850/V850CallingConv.td` (FP calling convention)
- `clang/lib/Basic/Targets/V850.cpp`
- `clang/include/clang/Basic/BuiltinsV850.def`

**Content:**
- FP arithmetic patterns (fadd, fsub, fmul, fdiv)
- FP comparison and select
- FP ↔ integer conversions
- Soft-float fallback for non-FPU targets
- Clang: `-mfpu`, `-msoft-float` options
- Builtins for FPU system registers

**FPU Feature Logic (Clang Driver):**

The `+v850fpu` feature is derived in `getV850TargetFeatures()` (in
`clang/lib/Driver/ToolChains/V850.cpp`) using the following priority order:

1. **Enabled by default** for CPUs that support hardware FPU:
   `v850e2m`, `v850e2v3`, `v850e3`, `v850e3v5`, `g3m`, `g3mh`
   → passes `-target-feature +v850fpu` to cc1

2. **Disabled by default** for CPUs without hardware FPU:
   `v850`, `v850es`, `v850e1`, `v850e2`
   → passes `-target-feature -v850fpu` to cc1

3. **`-mv850-fpu` / `-mno-v850-fpu`** (explicit override):
   Forces FPU on or off regardless of CPU default.

4. **`-msoft-float`**: Adds `+soft-float` feature. The FPU instructions
   remain available in the ISA, but the ABI passes floating-point
   arguments via integer registers and the compiler does not use FPU
   instructions for arithmetic.

5. **`-msingle-float`** (TODO): Should add `+single-float-only` feature to
   disable double-precision FPU instructions (ADDF.D, MULF.D, etc.) while
   keeping single-precision (ADDF.S, MULF.S, etc.) available. Requires:
   - A new `HasSingleFloatOnly` subtarget feature in `V850.td`
   - ISel patterns guarded by `Requires<[HasFPU, Unless<HasSingleFloatOnly>]>`
   - `getV850TargetFeatures()` emitting `+single-float-only` for `-msingle-float`
   - f64 operations falling back to soft-float calls when `HasSingleFloatOnly` is set

**Tests:**
- `llvm/test/CodeGen/V850/fpu/arithmetic.ll`
- `llvm/test/CodeGen/V850/fpu/compare.ll`
- `llvm/test/CodeGen/V850/fpu/convert.ll`
- `llvm/test/CodeGen/V850/fpu/soft-float.ll`
- `clang/test/CodeGen/V850/fpu-builtins.c`
- `clang/test/Driver/v850-fpu.c`

### Phase 9: Optimizations (Patches 19-24)

These patches add target-specific optimizations incrementally, each building on a functional base.

---

#### Patch 19: [V850] Add basic scheduling model

**Files:**
- `llvm/lib/Target/V850/V850Schedule.td` (new)
- `llvm/lib/Target/V850/V850.td` (include scheduling)

**Content:**
Basic single-issue scheduling model for base V850:
- 5-stage pipeline model
- Instruction latencies for base V850 (load: 2 cycles, mul: 2 cycles, branch: 3 cycles)
- Resource definitions (ALU, Memory, Branch, Multiply, Divide)
- Write resources for instruction classes

**Tests:**
- `llvm/test/CodeGen/V850/sched-basic.ll`
- `llvm/test/CodeGen/V850/sched-latency.ll`

---

#### Patch 20: [V850] Add branch relaxation pass

**Files:**
- `llvm/lib/Target/V850/V850BranchRelaxation.cpp` (new)
- `llvm/lib/Target/V850/V850TargetMachine.cpp` (add pass)
- `llvm/lib/Target/V850/CMakeLists.txt`

**Content:**
Branch relaxation for out-of-range branches:
- Bcond disp9 → JR/JARL disp22 relaxation
- JR disp22 → JR32 disp32 relaxation (V850E2+)
- Basic block size calculation
- Iterative relaxation until stable

**Tests:**
- `llvm/test/CodeGen/V850/branch-relaxation.ll`
- `llvm/test/CodeGen/V850/branch-relaxation-v850e2.ll`

---

#### Patch 21: [V850] Add load/store optimizer

**Files:**
- `llvm/lib/Target/V850/V850LoadStoreOptimizer.cpp` (new)
- `llvm/lib/Target/V850/V850TargetMachine.cpp` (add pass)
- `llvm/lib/Target/V850/CMakeLists.txt`

**Content:**
Combine adjacent loads/stores:
- Merge consecutive LD.B → LD.H or LD.H+LD.H → LD.W
- Merge consecutive ST.B → ST.H or ST.H+ST.H → ST.W
- Base+offset optimization for SLD/SST short forms
- EP-relative addressing optimization

**Tests:**
- `llvm/test/CodeGen/V850/load-store-opt.ll`
- `llvm/test/CodeGen/V850/load-store-merge.ll`

---

#### Patch 22: [V850] Add tail call optimization

**Files:**
- `llvm/lib/Target/V850/V850ISelLowering.cpp` (tail call support)
- `llvm/lib/Target/V850/V850CallingConv.td` (tail call CC)
- `llvm/lib/Target/V850/V850InstrInfo.td` (tail call patterns)

**Content:**
Tail call optimization:
- Detect tail call opportunities
- JMP instruction for tail calls (no link register save)
- Caller/callee argument compatibility checks
- Stack adjustment for tail calls

**Tests:**
- `llvm/test/CodeGen/V850/tail-call.ll`
- `llvm/test/CodeGen/V850/tail-call-eligibility.ll`
- `llvm/test/CodeGen/V850/musttail.ll`

---

#### Patch 23: [V850] Add machine outliner support

**Files:**
- `llvm/lib/Target/V850/V850InstrInfo.cpp` (outliner hooks)
- `llvm/lib/Target/V850/V850InstrInfo.h`
- `llvm/lib/Target/V850/V850Subtarget.cpp` (enable outliner)

**Content:**
Machine outliner for code size reduction:
- `getOutliningCandidateInfo()` implementation
- `buildOutlinedFrame()` / `insertOutlinedCall()`
- Outline cost model for V850 (JARL cost vs savings)
- Handle callee-saved register constraints

**Tests:**
- `llvm/test/CodeGen/V850/machine-outliner.ll`
- `llvm/test/CodeGen/V850/machine-outliner-cost.ll`

---

#### Patch 24: [V850] Add V850E2M dual-issue scheduling model

**Files:**
- `llvm/lib/Target/V850/V850SchedV850E2M.td` (new)
- `llvm/lib/Target/V850/V850Schedule.td` (V850E1 model)
- `llvm/lib/Target/V850/V850.td` (model selection)

**Content:**
Advanced scheduling for V850E2/V850E2M:
- 7-stage dual-issue pipeline (Lpipe/Rpipe)
- `V850E1Model`: 5-stage, MUL: 5 cycles (1-4-5), Branch: 2 cycles
- `V850E2MModel`: IssueWidth=2, Lpipe (load/store/mul/MAC), Rpipe (ALU/shift)
- FPU instruction latencies (ADDF: 4, DIVF.S: 17, DIVF.D: 33)
- Processor model selection based on subtarget

**Tests:**
- `llvm/test/CodeGen/V850/sched-v850e1.ll`
- `llvm/test/CodeGen/V850/sched-v850e2m-dual-issue.ll`
- `llvm/test/CodeGen/V850/sched-fpu.ll`

---

## Summary: Patch Series Overview

| # | Patch Title | CPU Variant | Component |
|---|-------------|-------------|-----------|
| 1 | Add V850 triple support | All | Infrastructure |
| 2 | Add V850 ELF definitions and relocations | All | Infrastructure |
| 3 | Add V850 target stub with register definitions | Base V850 | Infrastructure |
| 4 | Add V850 instruction formats | All | Infrastructure |
| 5 | Add base V850 instruction definitions | Base V850 | MC Layer |
| 6 | Add V850 MCTargetDesc and assembly support | Base V850 | MC Layer |
| 7 | Add V850 AsmParser | Base V850 | MC Layer |
| 8 | Add V850 disassembler | Base V850 | MC Layer |
| 9 | Add V850 CodeGen framework | Base V850 | CodeGen |
| 10 | Add Clang driver for base V850 | Base V850 | Clang |
| 11 | Add V850ES CPU variant support | V850ES | Extension |
| 12 | Add V850E1 instruction support | V850E1 | Extension |
| 13 | Add V850E1 CodeGen patterns and Clang support | V850E1 | Extension |
| 14 | Add V850E2 instruction support | V850E2 | Extension |
| 15 | Add V850E2M instruction support | V850E2M | Extension |
| 16 | Add V850E2M CodeGen patterns and Clang support | V850E2M | Extension |
| 17 | Add V850 FPU instruction support | FPU | Extension |
| 18 | Add V850 FPU CodeGen and Clang support | FPU | Extension |
| 19 | Add basic scheduling model | Base V850 | Optimization |
| 20 | Add branch relaxation pass | All | Optimization |
| 21 | Add load/store optimizer | All | Optimization |
| 22 | Add tail call optimization | All | Optimization |
| 23 | Add machine outliner support | All | Optimization |
| 24 | Add V850E2M dual-issue scheduling model | V850E2M | Optimization |

---

## Code Quality Requirements

### clang-format

**CRITICAL**: All code MUST be formatted with `clang-format` before submission.

```bash
# Format all V850 files before each commit
find llvm/lib/Target/V850 -name "*.cpp" -o -name "*.h" | xargs clang-format -i
find clang/lib/Basic/Targets -name "V850*" | xargs clang-format -i
find clang/lib/CodeGen/TargetBuiltins -name "V850*" | xargs clang-format -i
find clang/lib/Driver/ToolChains -name "V850*" | xargs clang-format -i

# Verify formatting is correct
git diff --exit-code

# Or use git-clang-format for staged changes only
git clang-format --diff HEAD~1

# Format a single commit before submitting
git clang-format HEAD~1
```

### LLVM Coding Standards

- Follow [LLVM Coding Standards](https://llvm.org/docs/CodingStandards.html)
- Use `LLVM_DEBUG()` for debug output
- Document public interfaces with Doxygen comments
- No compiler warnings with `-Werror`

### Test Requirements

- Every patch must include corresponding tests
- Tests must pass with `ninja check-llvm-codegen-v850` and `ninja check-clang`
- Use FileCheck for test assertions
- Cover both positive and negative cases
- Each CPU variant patch must include tests that verify feature gating

---

## Git History Rework Process

### Step 1: Create clean branch from upstream

```bash
git fetch upstream
git checkout -b v850-upstream upstream/main
```

### Step 2: Create feature branches for each patch

```bash
# For each patch, create a branch and cherry-pick relevant commits
git checkout -b patch-01-triple v850-upstream
# ... cherry-pick and squash ...

git checkout -b patch-02-elf patch-01-triple
# ... cherry-pick and squash ...

# Continue building on previous patches
```

### Step 3: Apply clang-format to each patch

```bash
# After squashing, always run clang-format
find llvm/lib/Target/V850 clang/lib/Basic/Targets clang/lib/Driver/ToolChains \
  -name "*.cpp" -o -name "*.h" 2>/dev/null | xargs clang-format -i

# Amend the commit
git add -u
git commit --amend --no-edit
```

### Step 4: Verify each patch builds and tests pass

```bash
# Build from scratch for each patch
cmake -G Ninja -B build-test \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="V850" \
  -DCMAKE_BUILD_TYPE=Release

ninja -C build-test
ninja -C build-test check-llvm-codegen-v850
ninja -C build-test check-llvm-mc-v850
ninja -C build-test check-clang
```

### Step 5: Create final patch series

```bash
# Rebase all patches onto final branch
git checkout v850-upstream
git cherry-pick patch-01-triple
git cherry-pick patch-02-elf
# ... continue for all patches

# Generate patch files for review
git format-patch -24 --cover-letter -o patches/
```

---

## RFC Template

Post to [LLVM Discourse](https://discourse.llvm.org/) before submitting patches:

```markdown
# RFC: Add V850 backend

## Summary

This RFC proposes adding a new LLVM backend for the NEC/Renesas V850 family
of 32-bit microcontrollers, initially as an experimental target.

## Motivation

The V850 architecture is widely used in automotive and industrial applications.
Having LLVM support enables:
- Modern toolchain for V850-based embedded systems
- Clang static analysis and sanitizers
- LLVM-based optimization

## Target Architecture

- **Name**: V850 (also known as RH850 for newer variants)
- **Word size**: 32-bit
- **Endianness**: Little-endian
- **Registers**: 32 general-purpose registers
- **ISA Variants**: V850, V850ES, V850E1, V850E2, V850E2M
- **Optional FPU**: Single and double precision (V850E2M+)

## Implementation Status

The backend supports:
- Full base V850 instruction set
- V850ES/E1/E2/E2M extensions (incrementally)
- FPU instructions
- Assembly parsing and disassembly
- CodeGen with SelectionDAG
- Clang driver integration
- Target-specific builtins

## Maintenance

[Your name/organization] commits to maintaining this backend, including:
- Responding to bug reports
- Keeping up with LLVM API changes
- Supporting buildbot infrastructure

## Patch Series

The backend is submitted as 24 patches with incremental CPU variant and optimization support:

**Infrastructure (1-4):**
1. [V850] Add V850 triple support
2. [V850] Add V850 ELF definitions and relocations
3. [V850] Add V850 target stub with register definitions
4. [V850] Add V850 instruction formats

**Base V850 MC Layer (5-8):**
5. [V850] Add base V850 instruction definitions
6. [V850] Add V850 MCTargetDesc and assembly support
7. [V850] Add V850 AsmParser
8. [V850] Add V850 disassembler

**Base V850 CodeGen (9-10):**
9. [V850] Add V850 CodeGen framework
10. [V850] Add Clang driver for base V850

**CPU Variant Extensions (11-18):**
11. [V850] Add V850ES CPU variant support
12. [V850] Add V850E1 instruction support
13. [V850] Add V850E1 CodeGen patterns and Clang support
14. [V850] Add V850E2 instruction support
15. [V850] Add V850E2M instruction support
16. [V850] Add V850E2M CodeGen patterns and Clang support
17. [V850] Add V850 FPU instruction support
18. [V850] Add V850 FPU CodeGen and Clang support

**Optimizations (19-24):**
19. [V850] Add basic scheduling model
20. [V850] Add branch relaxation pass
21. [V850] Add load/store optimizer
22. [V850] Add tail call optimization
23. [V850] Add machine outliner support
24. [V850] Add V850E2M dual-issue scheduling model

## Testing

- Hardware: [describe available hardware/eval boards]
- Emulator: QEMU V850 support / other emulators
- Test suite: LLVM test-suite results

## References

- [V850 Architecture Manual links]
- [Related work/previous implementations]
```

---

## Milestones

| Milestone | Description |
|-----------|-------------|
| **M1** | Post RFC to LLVM Discourse |
| **M2** | History rework complete, patches ready for review |
| **M3** | Submit patch series to GitHub PRs |
| **M4** | Address reviewer feedback, iterate |
| **M5** | Patches approved and merged (experimental) |
| **M6** | Stabilization period (3+ months in tree) |
| **M7** | Request promotion to official target |

---

## Checklist Before Upstream

### Per-Patch Checklist

- [ ] Patch applies cleanly to upstream main
- [ ] Code passes `clang-format` check
- [ ] All tests pass (`ninja check-llvm check-clang`)
- [ ] No compiler warnings with `-Werror`
- [ ] Commit message follows LLVM conventions
- [ ] No debug code or TODOs

### Series-Wide Checklist

- [ ] RFC posted and acknowledged
- [ ] At least one committed maintainer identified
- [ ] Hardware/emulator availability documented
- [ ] Each patch is self-contained and builds independently
- [ ] CPU variant features are properly gated with predicates
- [ ] Tests verify feature gating (errors on unsupported CPUs)

---

## Related Documents

- [V850 Instruction Reference](V850InstructionReference.md)
- [V850 Builtins Plan](plan-v850-builtins.md)
- [V850 Verification Report](plan-verification.md)

---

## Appendix A: Feature Predicate Reference

| Feature | Predicate | Implies |
|---------|-----------|---------|
| Base V850 | (default) | - |
| V850ES | `HasV850ES` | - |
| V850E1 | `HasV850E1` | `HasV850ES` |
| V850E2 | `HasV850E2` | `HasV850E1` |
| V850E2M | `HasV850E2M` | `HasV850E2` |
| FPU | `HasFPU` | `HasV850E2M` |

---

## Appendix B: Commit Mapping

This section maps existing commits to upstream patches (to be filled during rework):

| Upstream Patch | Original Commits |
|----------------|------------------|
| 1: Triple | `60ba64faae80` (partial) |
| 2: ELF | `60ba64faae80` (partial) |
| 3: Target stub | `60ba64faae80`, `e8317f5e2bb3`, `0bc481b3e958`, `64b7b035cc27` |
| 4: Formats | `3eb562bbebad` (partial) |
| 5: Base instructions | `3eb562bbebad`, `7b8a74a2a660` |
| 6: MCTargetDesc | `60ba64faae80` (partial), `aad094506d43` |
| 7: AsmParser | `72b57b131033`, `4d6547a3d87b`, `5ada14acf537` |
| 8: Disassembler | `65b1fdbe4c6b` |
| 9: CodeGen | `d4c040f8c2f8`, `f804f6c101e4`, `3f0ca3ae1b78` |
| 10: Clang base | `e94c19f42fb0` (partial) |
| 11: V850ES | `8c5960167a90`, `7cf7eb08dd41` |
| 12: V850E1 MC | `4dcaf3d3c194`, `845b90863648` |
| 13: V850E1 CodeGen | `e5e40ee82c32`, `3fab249e533d`, multiple patterns |
| 14: V850E2 | `0cc13e3c310e`, `f350194e1c0c`, `c853cbcacd14` |
| 15: V850E2M MC | `429fd0c4efdb`, `c807f9cce569` |
| 16: V850E2M CodeGen | `b7b9ece8e454`, `b3aecb474898`, builtins |
| 17: FPU MC | `f107811ac75c`, `5737b346d7bc`, `62b6bd92999a`, etc. |
| 18: FPU CodeGen | `7ef511739004`, `3747b5035aef`, `168954e1600f` |
| 19: Basic scheduling | Scheduling model commits |
| 20: Branch relaxation | Branch relaxation commits |
| 21: Load/store optimizer | Load/store optimizer commits |
| 22: Tail call optimization | Tail call commits |
| 23: Machine outliner | Outliner commits |
| 24: Dual-issue scheduling | V850E2M scheduling commits |
