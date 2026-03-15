# V850 Debugging Support Plan

This document outlines the plan for implementing comprehensive debugging support for the V850 backend across LLVM, Clang, and LLDB.

## Current Status

### Implemented

| Feature | Status | Location |
|---------|--------|----------|
| DWARF register numbers | Done | `V850RegisterInfo.td` (GPR 0-31, PC 64, PSW 65, exception/debug regs 66-75) |
| Debug info support flag | Done | `V850MCAsmInfo.cpp` (SupportsDebugInformation = true) |
| DWARF CFI exception handling | Done | `V850MCAsmInfo.cpp` (ExceptionsType = DwarfCFI) |
| CFI instruction handling | Done | `V850InstrInfo.cpp` |
| Debug instructions (DBTRAP/DBRET) | Done | `V850InstrInfo.td` |
| Debug system registers | Defined | `V850RegisterInfo.td` (DBPC, DBPSW, DIR, etc.) |
| DebugLoc propagation | Done | All CodeGen files |
| CFI directive emission | Done | `V850FrameLowering.cpp` |
| Stack unwinding (eh_frame) | Done | Uses DWARF CFI directives, object file generation verified |
| Object file generation | Done | MCCodeEmitter, AsmBackend with proper ELF relocations |

### Not Implemented

| Feature | Priority | Complexity |
|---------|----------|------------|
| (all planned features implemented) | - | - |

### Recently Implemented

| Feature | Status | Location |
|---------|--------|----------|
| GDB remote stub support | Done | `lldb/source/Plugins/Process/gdb-remote/GDBRemoteRegisterFallback.cpp` |
| LLDB instruction emulation | Done | `lldb/source/Plugins/Instruction/V850/EmulateInstructionV850.cpp` |
| LLDB architecture plugin | Done | `lldb/source/Plugins/Architecture/V850/ArchitectureV850.cpp` |
| LLDB ABI plugin | Done | `lldb/source/Plugins/ABI/V850/ABISysV_v850.cpp` |
| LLDB unwind plans | Done | `CreateFunctionEntryUnwindPlan`, `CreateDefaultUnwindPlan` |
| LLDB disassembler integration | Done | Automatic via LLVM DisassemblerLLVMC |
| LLDB ELF object file support | Done | Automatic via ObjectFileELF (EM_V850=87) |
| Hardware breakpoint intrinsics | Done | `clang/include/clang/Basic/BuiltinsV850.def` |
| Debug register access intrinsics | Done | `clang/include/clang/Basic/BuiltinsV850.def` |
| Calling convention (i64/sret/byval) | Done | `V850CallingConv.td`, `V850FrameLowering.cpp` |
| Interrupt handler CSRs | Done | `V850CallingConv.td` (CSR_V850_Interrupt) |
| Object library V850 support | Done | `ELF.cpp`, `RelocationResolver.cpp`, `ELFObjectFile.h` |
| Line number information | Done | llvm-dwarfdump parses V850 debug sections |

---

## 1. DWARF/CFI Support

### 1.1 CFI Directive Emission [IMPLEMENTED]

**Status:** Fully implemented in commit 4dff53454289.

**Implementation Details:**

- Uses `CFIInstBuilder` utility class from `llvm/CodeGen/CFIInstBuilder.h`
- Tracks callee-saved stack size in `V850MachineFunctionInfo`

#### 1.1.1 Prologue CFI Emission [IMPLEMENTED]

File: `llvm/lib/Target/V850/V850FrameLowering.cpp`

After stack adjustment, emits `.cfi_def_cfa_offset` with total frame size.
When frame pointer is used, also emits `.cfi_def_cfa r29, <offset>`.

#### 1.1.2 Callee-Saved Register CFI [IMPLEMENTED]

Two paths based on CPU variant:

**PREPARE path (V850E1+):**
- Sets `UsesPrepareDispose = true` in `V850MachineFunctionInfo`
- PREPARE allocates CSR area separately from local frame
- Emits `.cfi_def_cfa_offset <callee_saved_size>` after PREPARE
- Emits `.cfi_offset <reg>, <offset>` for each saved register
- Register save order: LP, EP, r29, r28, ..., r20

**Fallback path (base V850):**
- `UsesPrepareDispose = false` (default)
- CSRs stored in main stack frame allocated by emitPrologue
- emitPrologue emits `.cfi_def_cfa_offset <total_size>`
- Emits `.cfi_offset <reg>, <offset>` for each stored register

#### 1.1.3 Epilogue CFI [IMPLEMENTED]

V850 follows the "prologue-only" CFI philosophy used by most LLVM backends.
The epilogue emits `.cfi_def_cfa_offset` after local frame deallocation to
track the CFA offset change, but does NOT emit `.cfi_restore` directives for
callee-saved registers. Stack unwinding uses the CFI state from the prologue.

**In `emitEpilogue()`:**
- After local frame deallocation (`add N, r3`), emits `.cfi_def_cfa_offset <callee_saved_size>`
- When frame pointer is used, emits `.cfi_def_cfa r3, <callee_saved_size>` after
  restoring SP from FP

**Test:** `llvm/test/CodeGen/V850/epilogue-cfi.ll`

**Example Output:**
```asm
func_with_call:
    .cfi_startproc
    prepare 2048, 0
    .cfi_def_cfa_offset 4
    .cfi_offset r31, -4
    add -4, r3
    .cfi_def_cfa_offset 8        ; CFA = SP + 8 (4 CSR + 4 local)
    jarl external_func, r31
    add 4, r3
    .cfi_def_cfa_offset 4        ; Epilogue: local frame deallocated, CFA = SP + 4
    dispose 0, 2048, [r31]       ; Restore LP and return
    .cfi_endproc
```

### 1.2 DWARF Register Mapping [IMPLEMENTED]

**Status:** Fully implemented.

All general purpose and system registers now have DWARF register numbers defined.

| Register | DWARF # | Notes |
|----------|---------|-------|
| r0-r31 | 0-31 | Done |
| PC | 64 | Program counter (pseudo register for DWARF) |
| PSW | 65 | Processor status word |
| EIPC | 66 | Exception PC |
| EIPSW | 67 | Exception PSW |
| FEPC | 68 | Fatal error PC |
| FEPSW | 69 | Fatal error PSW |
| ECR | 70 | Exception cause |
| CTPC | 71 | CALLT saved PC |
| CTPSW | 72 | CALLT saved PSW |
| CTBP | 73 | CALLT base pointer |
| DBPC | 74 | Debug saved PC |
| DBPSW | 75 | Debug saved PSW |

**File:** `llvm/lib/Target/V850/V850RegisterInfo.td`

**Implementation Notes:**
- PC is defined as a separate pseudo-register without HWEncoding (since it's not
  directly accessible on V850)
- System registers use DwarfRegNum<[]> syntax for DWARF number assignment

**Test:** `llvm/test/CodeGen/V850/dwarf-reg-numbers.ll`

### 1.3 Initial Frame State [IMPLEMENTED]

**File:** `llvm/lib/Target/V850/MCTargetDesc/V850MCTargetDesc.cpp`

The initial frame state is configured via `addInitialFrameState()` in the custom
`createV850MCAsmInfo()` function. This establishes the CFA (Canonical Frame Address)
at function entry.

**Implementation:**
```cpp
static MCAsmInfo *createV850MCAsmInfo(const MCRegisterInfo &MRI,
                                       const Triple &TT,
                                       const MCTargetOptions &Options) {
  MCAsmInfo *MAI = new V850MCAsmInfo(TT, Options);

  // Set up initial frame state: CFA = SP + 0
  // SP is R3 on V850
  unsigned SP = MRI.getDwarfRegNum(V850::SP, true);
  MCCFIInstruction Inst = MCCFIInstruction::cfiDefCfa(nullptr, SP, 0);
  MAI->addInitialFrameState(Inst);

  return MAI;
}
```

**Effect:**
- At function entry, CFA = SP + 0
- Encoded in CIE as `DW_CFA_def_cfa r3, 0` (bytes: 0x0c 0x03 0x00)
- Debuggers use this as the starting point for stack unwinding

**Test:** `llvm/test/CodeGen/V850/initial-frame-state.ll`

---

## 2. LLDB Support

### 2.1 Architecture Plugin [IMPLEMENTED]

**Status:** Fully implemented.

**Files Created:**

```
lldb/source/Plugins/Architecture/V850/
├── ArchitectureV850.h      - Architecture class declaration
├── ArchitectureV850.cpp    - Architecture implementation
└── CMakeLists.txt          - Build configuration
```

**Modified:**
- `lldb/source/Plugins/Architecture/CMakeLists.txt` - Added V850 subdirectory

**Key Features:**

```cpp
class ArchitectureV850 : public Architecture {
public:
  static llvm::StringRef GetPluginNameStatic() { return "v850"; }

  llvm::StringRef GetPluginName() override { return GetPluginNameStatic(); }

  void OverrideStopInfo(Thread &thread) const override {}

  lldb::addr_t GetBreakableLoadAddress(lldb::addr_t addr,
                                       Target &target) const override;

  lldb::addr_t GetCallableLoadAddress(lldb::addr_t load_addr,
                                      AddressClass addr_class) const override;

  lldb::addr_t GetOpcodeLoadAddress(lldb::addr_t load_addr,
                                    AddressClass addr_class) const override;
};
```

**Implementation Notes:**
- V850 has no delay slots, so `GetBreakableLoadAddress()` returns the address as-is
- V850 has no ISA mode bits (unlike ARM Thumb or MIPS16), so address manipulation is trivial
- All methods have simple implementations since V850 addresses are straightforward

### 2.2 ABI Plugin [IMPLEMENTED]

**Status:** Fully implemented with return value and argument extraction support.

**Files Created:**

```
lldb/source/Plugins/ABI/V850/
├── ABISysV_v850.h      - ABI class declaration
├── ABISysV_v850.cpp    - ABI implementation with register info
└── CMakeLists.txt      - Build configuration
```

**Modified:**
- `lldb/source/Plugins/ABI/CMakeLists.txt` - Added V850 to target list

**Reference:** Based on `lldb/source/Plugins/ABI/MSP430/ABISysV_msp430.cpp` and `lldb/source/Plugins/ABI/RISCV/ABISysV_riscv.cpp`

**Implementation Status:**

| Method | Status | Notes |
|--------|--------|-------|
| `CreateInstance()` | ✓ Done | Checks `llvm::Triple::v850` |
| `GetRegisterInfoArray()` | ✓ Done | 34 registers (r0-r31, PC, PSW) |
| `CreateFunctionEntryUnwindPlan()` | ✓ Done | CFA=SP, PC in LP, RA=LP |
| `CreateDefaultUnwindPlan()` | ✓ Done | CFA=FP+8, PC at CFA-4, FP at CFA-8 |
| `PrepareTrivialCall()` | ✓ Done | Sets up r6-r9, LP, SP, PC |
| `GetReturnValueObjectImpl()` | ✓ Done | Reads r10 (32-bit) or r10:r11 (64-bit) |
| `GetArgumentValues()` | ✓ Done | Reads r6-r9 for first 4 arguments |
| `SetReturnValueObject()` | ✓ Done | Writes r10/r11 for return values |
| `RegisterIsVolatile()` | ✓ Done | r1-r19 volatile, r20-r31 callee-saved |
| `CallFrameAddressIsValid()` | ✓ Done | Validates 4-byte aligned, non-zero |
| `CodeAddressIsValid()` | ✓ Done | Validates 2-byte aligned (16/32-bit insns) |

**Key Components:**

#### 2.2.1 Register Definitions

```cpp
namespace dwarf {
enum regnums {
  r0, r1, r2, r3, r4, r5, r6, r7, r8, r9,
  r10, r11, r12, r13, r14, r15, r16, r17, r18, r19,
  r20, r21, r22, r23, r24, r25, r26, r27, r28, r29,
  r30, r31,
  // Special registers
  sp = r3,   // Stack pointer
  gp = r4,   // Global pointer
  tp = r5,   // Thread pointer
  ep = r30,  // Element pointer
  lp = r31,  // Link pointer (return address)
  // System registers
  pc = 64,
  psw = 65
};
}

static const RegisterInfo g_register_infos[] = {
  // name, alt, size, offset, encoding, format, kinds, ...
  DEFINE_GENERIC_REGISTER_STUB(r0, "zero", LLDB_INVALID_REGNUM),
  // ... r1-r5
  DEFINE_GENERIC_REGISTER_STUB(r6, nullptr, LLDB_REGNUM_GENERIC_ARG1),
  DEFINE_GENERIC_REGISTER_STUB(r7, nullptr, LLDB_REGNUM_GENERIC_ARG2),
  DEFINE_GENERIC_REGISTER_STUB(r8, nullptr, LLDB_REGNUM_GENERIC_ARG3),
  DEFINE_GENERIC_REGISTER_STUB(r9, nullptr, LLDB_REGNUM_GENERIC_ARG4),
  // ... r10-r28
  DEFINE_GENERIC_REGISTER_STUB(r29, "fp", LLDB_REGNUM_GENERIC_FP),
  DEFINE_REGISTER_STUB(r30, "ep"),
  DEFINE_GENERIC_REGISTER_STUB(r31, "lp", LLDB_REGNUM_GENERIC_RA),
  DEFINE_GENERIC_REGISTER_STUB(pc, nullptr, LLDB_REGNUM_GENERIC_PC),
  DEFINE_GENERIC_REGISTER_STUB(psw, nullptr, LLDB_REGNUM_GENERIC_FLAGS),
};
```

#### 2.2.2 Calling Convention

```cpp
bool ABISysV_v850::PrepareTrivialCall(Thread &thread,
                                      lldb::addr_t sp,
                                      lldb::addr_t func_addr,
                                      lldb::addr_t return_addr,
                                      llvm::ArrayRef<lldb::addr_t> args) const {
  // V850 calling convention:
  // - Arguments in r6-r9, then stack
  // - Return value in r10 (r10:r11 for 64-bit)
  // - Return address in r31 (lp)

  RegisterContext *reg_ctx = thread.GetRegisterContext().get();

  // Set up argument registers
  for (size_t i = 0; i < args.size() && i < 4; i++) {
    reg_ctx->WriteRegisterFromUnsigned(r6 + i, args[i]);
  }

  // Stack arguments (if any)
  // ...

  // Set return address
  reg_ctx->WriteRegisterFromUnsigned(dwarf::lp, return_addr);

  // Set PC to function address
  reg_ctx->WriteRegisterFromUnsigned(dwarf::pc, func_addr);

  // Set SP
  reg_ctx->WriteRegisterFromUnsigned(dwarf::sp, sp);

  return true;
}

bool ABISysV_v850::GetArgumentValues(Thread &thread,
                                     ValueList &values) const {
  // Extract arguments from r6-r9 and stack
}

Status ABISysV_v850::SetReturnValueObject(StackFrame *frame,
                                          ValueObjectSP &new_value) {
  // Set return value in r10 (or r10:r11 for 64-bit)
}
```

#### 2.2.3 Unwind Plan [IMPLEMENTED]

**Function Entry Unwind Plan:** Used at the first instruction of a function.
- CFA = SP (stack pointer at function entry)
- PC is obtained from LP (r31) - V850's link register
- LP contains the return address directly
- SetReturnAddressRegister(dwarf_lp) identifies RA register

**Default Unwind Plan:** Fallback when no CFI/debug info available.
Assumes frame pointer (r29) is being used with standard PREPARE layout:

```
High Address
+----------------+ <- CFA (Caller's SP)
|  Saved LP      |  (CFA - 4)
+----------------+
|  Saved FP(r29) |  (CFA - 8) <- FP points here
+----------------+
|  Other CSRs    |
+----------------+
|  Local Vars    |
+----------------+ <- SP
Low Address
```

- CFA = FP + 8 (LP and FP saved first by PREPARE)
- PC (return address) at CFA - 4
- Old FP at CFA - 8
- Uses generic register kinds for portability

**Files:** `lldb/source/Plugins/ABI/V850/ABISysV_v850.cpp`

### 2.3 Process Plugin (Optional)

For bare-metal/JTAG debugging:

```
lldb/source/Plugins/Process/V850/
├── ProcessV850.h
├── ProcessV850.cpp
└── CMakeLists.txt
```

### 2.4 ObjectFile Support [WORKING]

**Status:** ELF support works automatically via existing ObjectFileELF.

- `EM_V850 = 87` is handled in LLDB's ELF parser
- Architecture detected via LLVM triple (`llvm::Triple::v850`)
- No V850-specific code needed in ObjectFileELF

### 2.5 Disassembler Integration [WORKING]

**Status:** V850 disassembler works automatically via LLVM's DisassemblerLLVMC.

- Uses LLVM's V850 backend disassembler
- No explicit V850 code needed in LLDB
- Works via LLVM triple support

---

## 3. Hardware Debug Support

### 3.1 Debug Instructions

**Already Implemented:**

| Instruction | Description | File |
|-------------|-------------|------|
| DBTRAP | Debug trap (software breakpoint) | `V850InstrInfo.td:1471` |
| DBRET | Return from debug trap | `V850InstrInfo.td:1481` |

### 3.2 Debug System Registers

**Defined in `V850RegisterInfo.td`:**

| Register | regID | Description |
|----------|-------|-------------|
| DBPC | 18 | Debug saved PC |
| DBPSW | 19 | Debug saved PSW |
| DIR | 21 | Debug interface register |
| BPC | 22 | Breakpoint control |
| BPAV | 24 | Breakpoint address value |
| BPAM | 25 | Breakpoint address mask |
| BPDV | 26 | Breakpoint data value |
| BPDM | 27 | Breakpoint data mask |
| DBIC | 15 | Debug exception cause (V850E2M+) |
| DBWR | 30 | Debug working register (V850E2M+) |

### 3.3 Debug Intrinsics [IMPLEMENTED]

**Status:** Fully implemented in commit series.

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def` - Builtin definitions
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp` - CodeGen support
- `llvm/include/llvm/IR/IntrinsicsV850.td` - LLVM intrinsic definition
- `llvm/lib/Target/V850/V850InstrInfo.td` - Instruction pattern

**Implemented Builtins:**

| Builtin | Description |
|---------|-------------|
| `__builtin_v850_dbtrap()` | Software breakpoint (DBTRAP instruction) |
| `__builtin_v850_read_dbpc()` | Read debug saved PC |
| `__builtin_v850_write_dbpc(val)` | Write debug saved PC |
| `__builtin_v850_read_dbpsw()` | Read debug saved PSW |
| `__builtin_v850_write_dbpsw(val)` | Write debug saved PSW |
| `__builtin_v850_read_dir()` | Read debug interface register |
| `__builtin_v850_read_bpc()` | Read breakpoint control |
| `__builtin_v850_write_bpc(val)` | Write breakpoint control |
| `__builtin_v850_read_bpav()` | Read breakpoint address value |
| `__builtin_v850_write_bpav(val)` | Write breakpoint address value |
| `__builtin_v850_read_bpam()` | Read breakpoint address mask |
| `__builtin_v850_write_bpam(val)` | Write breakpoint address mask |
| `__builtin_v850_read_bpdv()` | Read breakpoint data value |
| `__builtin_v850_write_bpdv(val)` | Write breakpoint data value |
| `__builtin_v850_read_bpdm()` | Read breakpoint data mask |
| `__builtin_v850_write_bpdm(val)` | Write breakpoint data mask |

**Test:** `clang/test/CodeGen/V850/debug-intrinsics.c`

### 3.4 Breakpoint Channel Selection [IMPLEMENTED]

**Status:** Fully implemented with dedicated builtin.

V850E1+ has 2 breakpoint channels selected via DIR.CS bit (bit 0).
Channel 0 is selected when DIR.CS = 0, channel 1 when DIR.CS = 1.

**Implemented Builtins:**

| Builtin | Description |
|---------|-------------|
| `__builtin_v850_write_dir(val)` | Write to DIR register |
| `__builtin_v850_select_bp_channel(channel)` | Select breakpoint channel (0 or 1) |

The `select_bp_channel` builtin performs an atomic read-modify-write on the
DIR register to set or clear the CS bit based on the channel argument.

**Example Usage:**

```c
// Set up a breakpoint on channel 1
void setup_breakpoint_channel1(unsigned int addr, unsigned int mask) {
  // Select breakpoint channel 1
  __builtin_v850_select_bp_channel(1);

  // Write breakpoint address and mask (applies to selected channel)
  __builtin_v850_write_bpav(addr);
  __builtin_v850_write_bpam(mask);

  // Enable the breakpoint
  unsigned int bpc = __builtin_v850_read_bpc();
  bpc |= 0x1;
  __builtin_v850_write_bpc(bpc);

  // Switch back to channel 0 if needed
  __builtin_v850_select_bp_channel(0);
}
```

**Test:** `clang/test/CodeGen/V850/debug-intrinsics.c`

---

## 4. Stack Unwinding

### 4.1 Frame Pointer Chain [IMPLEMENTED]

**Status:** Fully implemented with proper frame pointer chain support.

V850 uses r29 as frame pointer when enabled. For proper debugger stack walking,
FP points to where the old FP was saved, so `[FP] = previous frame's FP`.

```
High Address
+----------------+
|  Arguments     |
+----------------+ <- CFA (Caller's SP)
|  Saved r20     |  (CFA - 4, if saved)
+----------------+
|  Saved r21     |  (CFA - 8, if saved)
+----------------+
|  Old FP (r29)  | <- FP points here ([FP] = old FP)
+----------------+
|  Saved LP      |  (FP - 4)
+----------------+
|  Local Vars    |
+----------------+ <- SP
Low Address
```

**Key Implementation Details:**

1. **FP Setup:** `FP = SP + (StackSize - FPOffset)` where FPOffset is the offset
   from CFA to where r29 is saved.

2. **Frame Chain:** `[FP] = old FP`, enabling debuggers to walk the stack by
   following: `current_FP -> previous_FP -> grandparent_FP -> ...`

3. **CFI:** `.cfi_def_cfa r29, <FPOffset>` correctly describes CFA relative to FP.

4. **Files Modified:**
   - `V850FrameLowering.cpp`: FP setup in emitPrologue, SP restore in emitEpilogue
   - `V850RegisterInfo.cpp`: eliminateFrameIndex computes FP-relative offsets
   - `V850MachineFunctionInfo.h`: Stores FPOffset for frame calculations

**Tests:**
- `llvm/test/CodeGen/V850/frame-pointer.ll`
- `llvm/test/CodeGen/V850/frame-pointer-chain.ll`

### 4.2 PREPARE/DISPOSE Unwinding [IMPLEMENTED]

**Status:** Fully implemented with correct CFI directive emission.

The PREPARE and DISPOSE instructions save/restore multiple callee-saved registers
atomically. CFI directives are emitted to accurately describe the stack state after
PREPARE executes.

**PREPARE list12, imm5:**
- Saves registers in order: LP (r31), EP (r30), r29, r28, ..., r20
- Only registers with corresponding bits set in list12 are saved
- LP is saved first at CFA-4, next register at CFA-8, etc.
- Then subtracts imm5 × 4 from SP (used for additional stack allocation)

**DISPOSE imm5, list12:**
- Adds imm5 × 4 to SP
- Restores registers in reverse order
- No CFI needed in epilogue (per LLVM convention)

**CFI Emission (in spillCalleeSavedRegisters):**
```cpp
// After PREPARE, emit CFI:
// 1. cfi_def_cfa_offset for total callee-saved size
CFIBuilder.buildDefCFAOffset(CalleeSavedSize);

// 2. cfi_offset for each saved register in PREPARE order
static const unsigned PrepareOrder[] = {
    V850::LP, V850::EP, V850::R29, V850::R28, V850::R27, V850::R26,
    V850::R25, V850::R24, V850::R23, V850::R22, V850::R21, V850::R20};
int Offset = -4;
for (unsigned Reg : PrepareOrder) {
  if (List12 & (1 << (TRI->getEncodingValue(Reg) - 20))) {
    CFIBuilder.buildOffset(Reg, Offset);
    Offset -= 4;
  }
}
```

**Example Output:**
```asm
test_func:
    .cfi_startproc
    prepare 2049, 0          ; Save LP (bit 11) and r20 (bit 0)
    .cfi_def_cfa_offset 8    ; 2 registers × 4 bytes = 8
    .cfi_offset r31, -4      ; LP at CFA-4
    .cfi_offset r20, -8      ; r20 at CFA-8
    add -12, r3
    .cfi_def_cfa_offset 20   ; 8 (CSR) + 12 (locals) = 20
    ...
    dispose 0, 2049, [r31]
    .cfi_endproc
```

**Tests:** `llvm/test/CodeGen/V850/prepare-dispose-unwind.ll`

### 4.3 eh_frame Generation [IMPLEMENTED]

**Status:** Fully implemented and verified.

eh_frame sections are generated with proper FDE/CIE. Object file generation
with proper ELF relocations was fixed in commit fca16493e62b.

**Configuration:**

**File:** `llvm/lib/Target/V850/MCTargetDesc/V850MCAsmInfo.cpp`

```cpp
// Already set:
ExceptionsType = ExceptionHandling::DwarfCFI;
SupportsDebugInformation = true;
```

**Key Fixes for Object File Generation:**
- MCCodeEmitter: Added expression operand handling for fixup generation
- AsmBackend: Added `maybeAddReloc()` call to generate ELF relocations
- AsmPrinter: Expanded CALL pseudo to JARL, added CALL_REG for indirect calls

**Test:** `llvm/test/CodeGen/V850/obj-relocation.ll`

Verifies:
- `.text` section is emitted
- `.eh_frame` section is emitted
- Proper relocations (R_V850_22_PCREL) are generated for function calls

---

## 5. Source-Level Debugging

### 5.1 Line Number Information [IMPLEMENTED]

**Status:** Fully implemented with LLVM Object library support.

**Implementation Details:**
- `-g` flag generates proper `.debug_line` sections
- Line tables map correctly to V850 instructions
- `llvm-dwarfdump` can properly parse V850 ELF debug sections

**Object Library Support Added:**
- `llvm/lib/Object/ELF.cpp`: Added V850 relocation type name mapping
- `llvm/lib/Object/RelocationResolver.cpp`: Added V850 relocation resolver for R_V850_32, R_V850_16, R_V850_8
- `llvm/include/llvm/Object/ELFObjectFile.h`: Added V850 architecture detection and file format name

**Tests:**
- `llvm/test/CodeGen/V850/debug-line.ll`
- `llvm/test/CodeGen/V850/debug-info.ll`

### 5.2 Variable Location [IMPLEMENTED]

**Status:** Handled by LLVM's debug info infrastructure.

**Implementation Notes:**
- Register locations use DWARF register numbers (r0-r31 = 0-31)
- Stack locations use DW_OP_fbreg with frame pointer (r29) relative offsets
- PREPARE/DISPOSE register save/restore is tracked via CFI directives

### 5.3 DWARF Expression Support

For complex variable locations (e.g., optimized code):

```cpp
// Example: Variable at [FP - 8]
DW_OP_breg29 -8
```

---

## 6. Implementation Phases

### Phase 1: CFI Emission [COMPLETE]

**Status:** Implemented in commit 4dff53454289.

**Completed Items:**
1. ✅ Add CFI directives to `V850FrameLowering::emitPrologue()`
2. ✅ Add CFI directives to `spillCalleeSavedRegisters()`
3. ✅ Handle PREPARE CFI emission with correct register order
4. ✅ Track callee-saved stack size in `V850MachineFunctionInfo`
5. ✅ Test with comprehensive test file

**Deliverables:**
- ✅ Working CFI directives for stack unwinding
- ✅ Proper `.cfi_*` directives in assembly output
- ✅ Test: `llvm/test/CodeGen/V850/cfi-directives.ll`

**Verification:**
```bash
llc -mtriple=v850-unknown-elf -mcpu=v850e2m test.ll -o -
# Shows .cfi_def_cfa_offset and .cfi_offset directives
```

### Phase 2: LLDB ABI Plugin (Basic) [COMPLETE]

**Status:** Basic implementation complete with improved unwind plans.

1. ✅ Created `lldb/source/Plugins/ABI/V850/` directory
2. ✅ Implemented `ABISysV_v850` class
3. ✅ Defined register info table with DWARF mapping (r0-r31, PC, PSW)
4. ✅ Implemented `CreateFunctionEntryUnwindPlan()` - CFA=SP, PC in LP, RA=LP
5. ✅ Implemented `CreateDefaultUnwindPlan()` - FP-based: CFA=FP+8, PC at CFA-4, FP at CFA-8
6. ✅ Implemented `PrepareTrivialCall()` for expression evaluation
7. ✅ Registered plugin in LLDB build system
8. ✅ Fixed default unwind to use FP-based unwinding (V850 doesn't push RA to stack)

**Files Created:**
- `lldb/source/Plugins/ABI/V850/ABISysV_v850.h`
- `lldb/source/Plugins/ABI/V850/ABISysV_v850.cpp`
- `lldb/source/Plugins/ABI/V850/CMakeLists.txt`

**Key Features:**
- Register info for all 32 GPRs plus PC and PSW
- Correct DWARF register number mapping
- Callee-saved register identification (r20-r30, LP)
- Argument register mapping (r6-r9 → ARG1-ARG4)
- Generic register mapping (SP, FP, RA, PC, FLAGS)

**Deliverables:**
- ✅ Basic stack traces in LLDB
- ✅ Function call evaluation support

### Phase 2b: LLDB ABI Plugin (Return Values) [COMPLETE]

**Status:** Implemented. Enables `p func()` expressions in LLDB.

**Completed Tasks:**
1. ✅ Implemented `GetReturnValueObjectImpl()`:
   - Reads r10 for 32-bit scalar return values
   - Reads r10:r11 for 64-bit return values (r10=low, r11=high)
   - Handles floating-point returns (float in r10, double in r10:r11)
   - Properly handles signed/unsigned types

2. ✅ Implemented `GetArgumentValues()`:
   - Reads r6-r9 for first 4 arguments
   - Supports scalar types with proper byte-size masking

3. ✅ Implemented `SetReturnValueObject()`:
   - Writes return values to r10/r11 for expression evaluation

**V850 Calling Convention (Return Values):**
```
Return Type        | Location
-------------------|------------------
void               | (none)
8/16/32-bit scalar | r10
64-bit scalar      | r10:r11 (r10=low, r11=high)
float (if FPU)     | r10 (bit pattern)
double (if FPU)    | r10:r11 (bit pattern)
struct ≤ 8 bytes   | r10:r11
struct > 8 bytes   | Return via hidden pointer in r6
```

**Reference Implementation:** Based on `ABISysV_riscv.cpp`

### Phase 3: LLDB Architecture Plugin (Low Priority - Optional)

**Status:** Not implemented. Optional for embedded targets.

**Notes:**
- Most embedded targets (MSP430, AVR) don't have an Architecture plugin
- Only needed if V850-specific address manipulation is required
- Can be deferred indefinitely

**Tasks (if needed):**
1. Create `lldb/source/Plugins/Architecture/V850/` directory
2. Implement `ArchitectureV850` class
3. Handle V850-specific address manipulation
4. Register plugin

**Deliverables:**
- Proper address handling for V850 code/data (if non-trivial)

### Phase 4: Debug Intrinsics [COMPLETE]

**Status:** Fully implemented.

1. ✅ Added DBTRAP intrinsic to BuiltinsV850.def
2. ✅ Added debug register read/write intrinsics (DBPC, DBPSW, DIR, BPC, etc.)
3. ✅ Added breakpoint register intrinsics (BPAV, BPAM, BPDV, BPDM)
4. ✅ Implemented CodeGen for all intrinsics
5. ✅ Added tests: `clang/test/CodeGen/V850/debug-intrinsics.c`

**Deliverables:**
- ✅ User-accessible debug functionality from C code
- ✅ Software breakpoint via `__builtin_v850_dbtrap()`
- ✅ Hardware breakpoint configuration via BPC/BPAV/BPAM intrinsics

### Phase 5: Hardware Debug Support [COMPLETE]

**Status:** Implemented.

1. ✅ Document hardware breakpoint setup procedure → `docs/V850HardwareDebug.md`
2. ✅ Create helper header for breakpoint management → `clang/lib/Headers/v850_debug.h`
3. Test with actual hardware/simulator (deferred — requires hardware)

**Files Created:**
- `clang/lib/Headers/v850_debug.h` — Convenience macros/inline functions over raw builtins
- `docs/V850HardwareDebug.md` — Practical documentation with examples

**Deliverables:**
- ✅ `v850_debug.h` header with software breakpoint, channel selection, address breakpoint, data watchpoint helpers
- ✅ BPC bit constants (`V850_BPC_EN`, `V850_BPC_ADDR_MATCH`, etc.)
- ✅ Documentation with register layout, examples for all use cases

---

## 7. Testing Strategy

### 7.1 Unit Tests [IMPLEMENTED]

```
llvm/test/CodeGen/V850/
├── debug-info.ll            # ✅ Debug info section generation
├── debug-line.ll            # ✅ Line number information
├── cfi-directives.ll        # ✅ CFI directive emission
├── epilogue-cfi.ll          # ✅ Epilogue CFI tracking
├── frame-pointer.ll         # ✅ Frame pointer handling
├── frame-pointer-chain.ll   # ✅ FP chain for debugger walking
├── prepare-dispose-unwind.ll # ✅ PREPARE/DISPOSE CFI
├── obj-relocation.ll        # ✅ ELF relocation generation
└── calling-conv.ll          # ✅ Calling convention verification
```

### 7.2 Clang Tests [IMPLEMENTED]

```
clang/test/CodeGen/V850/
├── debug-intrinsics.c       # ✅ Debug register intrinsics
└── builtins-*.c             # ✅ Various builtin tests
```

### 7.3 Manual Testing

1. Compile test program with `-g`
2. Load in GDB/LLDB
3. Set breakpoints, step through code
4. Verify backtrace at various points
5. Test variable inspection

**Verification Commands:**
```bash
# Test line number info generation
llvm-dwarfdump --debug-line test.o

# Test debug info generation
llvm-dwarfdump --debug-info test.o

# Test relocation naming
llvm-readelf -r test.o
```

---

## 8. Dependencies

### External Dependencies

| Dependency | Purpose | Status |
|------------|---------|--------|
| V850 simulator | Testing without hardware | Optional |
| JTAG debugger | Hardware testing | Optional |
| GDB | Alternative debugger testing | Available |

### LLVM Dependencies

| Component | Required For | Status |
|-----------|--------------|--------|
| MCTargetDesc | DWARF/CFI emission | Done |
| AsmPrinter | Debug directive output | Done |
| Disassembler | LLDB instruction display | Done |

---

## 9. References

### V850 Debug Architecture

1. **Debug Registers (V850E1+):**
   - DIR (Debug Interface Register) - Controls debug mode
   - BPC (Breakpoint Control) - Configures breakpoint behavior
   - BPAV/BPAM - Address breakpoint value/mask
   - BPDV/BPDM - Data breakpoint value/mask

2. **Debug Exception:**
   - DBTRAP instruction triggers debug exception
   - DBRET returns from debug exception
   - DBPC/DBPSW save PC/PSW on debug exception

3. **Breakpoint Channels:**
   - V850E1+ has 2 breakpoint channels
   - Selected via DIR.CS bit
   - Each channel has independent address/data matching

### LLVM/LLDB Resources

- [LLDB Architecture Plugin](https://lldb.llvm.org/design/plugins.html)
- [LLVM Exception Handling](https://llvm.org/docs/ExceptionHandling.html)
- [DWARF Standard](https://dwarfstd.org/)

### Reference Implementations

- ARC: `lldb/source/Plugins/ABI/ARC/ABISysV_arc.cpp`
- MSP430: `lldb/source/Plugins/ABI/MSP430/ABISysV_msp430.cpp`
- RISCV: `lldb/source/Plugins/ABI/RISCV/ABISysV_riscv.cpp`

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-17 | 1.0 | Initial plan |
| 2026-01-24 | 1.1 | Phase 1 (CFI Emission) completed |
| 2026-01-24 | 1.2 | Debug intrinsics (DBTRAP, debug register access) completed |
| 2026-01-24 | 1.3 | Initial frame state implemented |
| 2026-01-25 | 1.4 | Breakpoint channel selection implemented (write_dir, select_bp_channel) |
| 2026-01-25 | 1.5 | Frame pointer chain implemented for proper debugger stack walking |
| 2026-01-25 | 1.6 | PREPARE/DISPOSE unwinding documented and tested |
| 2026-01-25 | 1.7 | Object file generation with ELF relocations and eh_frame verified |
| 2026-01-25 | 1.8 | DWARF register mapping completed (PC, PSW, exception/debug registers) |
| 2026-01-25 | 1.9 | LLDB ABI plugin implemented (ABISysV_v850) |
| 2026-01-25 | 2.0 | Status update: Verified LLDB integration (ELF, disassembler automatic); identified incomplete ABI methods (GetReturnValueObjectImpl, GetArgumentValues); added Phase 2b for return value handling |
| 2026-01-25 | 2.1 | Implemented GetReturnValueObjectImpl, GetArgumentValues, SetReturnValueObject in ABISysV_v850; ABI plugin now fully functional |
| 2026-01-27 | 2.2 | Improved LLDB unwind plans: CreateFunctionEntryUnwindPlan now sets RA register; CreateDefaultUnwindPlan fixed to use FP-based unwinding (V850 stores RA in LP register, not on stack) |
| 2026-01-26 | 2.2 | Epilogue CFI implemented: emits .cfi_def_cfa_offset after local frame deallocation (follows prologue-only philosophy) |
| 2026-01-27 | 2.3 | Line number information: Added V850 support to LLVM Object library (ELF.cpp, RelocationResolver.cpp, ELFObjectFile.h) for proper debug section parsing |
| 2026-01-26 | 2.3 | Fixed epilogue CFI for fallback path: tracks UsesPrepareDispose flag to emit correct CFA offset (CalleeSavedSize for PREPARE, 0 for fallback) |
| 2026-01-27 | 2.4 | LLDB architecture plugin implemented (ArchitectureV850.cpp) |
| 2026-01-27 | 2.5 | LLDB instruction emulation implemented (PREPARE/DISPOSE/ADD/ADDI/ST.W/LD.W/MOV) |
| 2026-01-31 | 2.6 | GDB remote stub support implemented (GDBRemoteRegisterFallback.cpp) |
| 2026-03-15 | 2.7 | Phase 5 complete: created v850_debug.h helper header and V850HardwareDebug.md documentation |
