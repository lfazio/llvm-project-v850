# V850 Debugging Support Plan

This document outlines the plan for implementing comprehensive debugging support for the V850 backend across LLVM, Clang, and LLDB.

## Current Status

### Implemented

| Feature | Status | Location |
|---------|--------|----------|
| DWARF register numbers | Done | `V850RegisterInfo.td` (DwarfRegNum) |
| Debug info support flag | Done | `V850MCAsmInfo.cpp` (SupportsDebugInformation = true) |
| DWARF CFI exception handling | Done | `V850MCAsmInfo.cpp` (ExceptionsType = DwarfCFI) |
| CFI instruction handling | Done | `V850InstrInfo.cpp` |
| Debug instructions (DBTRAP/DBRET) | Done | `V850InstrInfo.td` |
| Debug system registers | Defined | `V850RegisterInfo.td` (DBPC, DBPSW, DIR, etc.) |
| DebugLoc propagation | Done | All CodeGen files |
| CFI directive emission | Done | `V850FrameLowering.cpp` |
| Stack unwinding (eh_frame) | Done | Uses DWARF CFI directives |

### Not Implemented

| Feature | Priority | Complexity |
|---------|----------|------------|
| LLDB target support | High | High |
| LLDB ABI plugin | High | Medium |
| LLDB register context | High | Medium |
| Hardware breakpoint intrinsics | Done | Low |
| Debug register access intrinsics | Done | Low |
| GDB remote stub support | Low | Medium |

---

## 1. DWARF/CFI Support

### 1.1 CFI Directive Emission [IMPLEMENTED]

**Status:** Fully implemented in commit 4dff53454289.

**Implementation Details:**

- Uses `CFIInstBuilder` utility class from `llvm/CodeGen/CFIInstBuilder.h`
- Tracks callee-saved stack size in `V850MachineFunctionInfo`

#### 1.1.1 Prologue CFI Emission

File: `llvm/lib/Target/V850/V850FrameLowering.cpp`

After stack adjustment, emits `.cfi_def_cfa_offset` with total frame size.
When frame pointer is used, also emits `.cfi_def_cfa r29, <offset>`.

#### 1.1.2 Callee-Saved Register CFI

In `spillCalleeSavedRegisters()`:
- After PREPARE instruction, emits `.cfi_def_cfa_offset <callee_saved_size>`
- Emits `.cfi_offset <reg>, <offset>` for each saved register
- Handles PREPARE's register save order: LP, EP, r29, r28, ..., r20

#### 1.1.3 Epilogue CFI

CFI restore directives are not emitted in the epilogue as stack unwinding
uses the CFI state from the prologue. This follows the pattern of most
LLVM backends.

**Test:** `llvm/test/CodeGen/V850/cfi-directives.ll`

**Example Output:**
```asm
func_with_call:
    .cfi_startproc
    prepare 2048, 0
    .cfi_def_cfa_offset 4
    .cfi_offset r31, -4
    add -4, r3
    .cfi_def_cfa_offset 8
    jarl external_func, lp
    add 4, r3
    dispose 0, 2048, [r31]
    .cfi_endproc
```

### 1.2 DWARF Register Mapping

**Current State:** Basic DWARF register numbers defined.

**Required Additions:**

| Register | DWARF # | Notes |
|----------|---------|-------|
| r0-r31 | 0-31 | Done |
| PC | 64 | Program counter |
| PSW | 65 | Processor status word |
| EIPC | 66 | Exception PC |
| EIPSW | 67 | Exception PSW |
| FEPC | 68 | Fatal error PC |
| FEPSW | 69 | Fatal error PSW |
| ECR | 70 | Exception cause |
| CTPC | 71 | CALLT saved PC |
| CTPSW | 72 | CALLT saved PSW |
| CTBP | 73 | CALLT base pointer |

**File:** `llvm/lib/Target/V850/V850RegisterInfo.td`

```tablegen
def PC : V850Reg<64, "pc">, DwarfRegNum<[64]>;
def PSW : V850SysReg<5, "psw">, DwarfRegNum<[65]>;
// ... etc
```

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

### 2.1 Architecture Plugin

**Files to Create:**

```
lldb/source/Plugins/Architecture/V850/
├── ArchitectureV850.h
├── ArchitectureV850.cpp
└── CMakeLists.txt
```

**Key Methods:**

```cpp
class ArchitectureV850 : public Architecture {
public:
  static llvm::StringRef GetPluginNameStatic() { return "v850"; }

  llvm::StringRef GetPluginName() override { return GetPluginNameStatic(); }

  void OverrideStopInfo(Thread &thread) const override;

  lldb::addr_t GetCallableLoadAddress(lldb::addr_t addr,
                                      AddressClass addr_class) const override;

  lldb::addr_t GetOpcodeLoadAddress(lldb::addr_t addr,
                                    AddressClass addr_class) const override;
};
```

### 2.2 ABI Plugin [HIGH PRIORITY]

**Files to Create:**

```
lldb/source/Plugins/ABI/V850/
├── ABISysV_v850.h
├── ABISysV_v850.cpp
└── CMakeLists.txt
```

**Reference:** `lldb/source/Plugins/ABI/ARC/ABISysV_arc.cpp`

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

#### 2.2.3 Unwind Plan

```cpp
bool ABISysV_v850::CreateFunctionEntryUnwindPlan(UnwindPlan &unwind_plan) {
  unwind_plan.Clear();
  unwind_plan.SetRegisterKind(eRegisterKindDWARF);

  // At function entry:
  // CFA = SP
  // Return address = [lp]
  UnwindPlan::RowSP row(new UnwindPlan::Row);
  row->GetCFAValue().SetIsRegisterPlusOffset(dwarf::sp, 0);
  row->SetRegisterLocationToRegister(dwarf::pc, dwarf::lp, true);
  unwind_plan.AppendRow(row);

  unwind_plan.SetSourceName("v850 at-func-entry default");
  unwind_plan.SetSourcedFromCompiler(eLazyBoolNo);

  return true;
}

bool ABISysV_v850::CreateDefaultUnwindPlan(UnwindPlan &unwind_plan) {
  unwind_plan.Clear();
  unwind_plan.SetRegisterKind(eRegisterKindDWARF);

  // Default: use frame pointer if available
  UnwindPlan::RowSP row(new UnwindPlan::Row);
  row->GetCFAValue().SetIsRegisterPlusOffset(dwarf::r29, 0);
  row->SetRegisterLocationToAtCFAPlusOffset(dwarf::pc, -4, true);
  unwind_plan.AppendRow(row);

  unwind_plan.SetSourceName("v850 default unwind plan");
  unwind_plan.SetSourcedFromCompiler(eLazyBoolNo);

  return true;
}
```

### 2.3 Process Plugin (Optional)

For bare-metal/JTAG debugging:

```
lldb/source/Plugins/Process/V850/
├── ProcessV850.h
├── ProcessV850.cpp
└── CMakeLists.txt
```

### 2.4 ObjectFile Support

ELF support for V850 should work via existing ObjectFileELF.

**Verify:** `EM_V850 = 87` is handled in LLDB's ELF parser.

### 2.5 Disassembler Integration

LLDB should use LLVM's V850 disassembler automatically.

**Verify:** V850 disassembler is linked into LLDB build.

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

### 4.3 eh_frame Generation

Ensure eh_frame sections are generated with proper FDE/CIE:

**File:** `llvm/lib/Target/V850/MCTargetDesc/V850MCAsmInfo.cpp`

```cpp
// Already set:
ExceptionsType = ExceptionHandling::DwarfCFI;
```

Verify `.eh_frame` section is emitted for all functions.

---

## 5. Source-Level Debugging

### 5.1 Line Number Information

**Status:** Handled by LLVM's debug info infrastructure.

**Verify:**
- `-g` flag generates proper `.debug_line` sections
- Line tables map correctly to V850 instructions

### 5.2 Variable Location

**Status:** Handled by LLVM's debug info infrastructure.

**Potential Issues:**
- Register allocation may affect variable locations
- PREPARE/DISPOSE may complicate stack slot tracking

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

### Phase 2: LLDB ABI Plugin (High Priority)

1. Create `lldb/source/Plugins/ABI/V850/` directory
2. Implement `ABISysV_v850` class
3. Define register info table with DWARF mapping
4. Implement `CreateFunctionEntryUnwindPlan()`
5. Implement `CreateDefaultUnwindPlan()`
6. Implement `PrepareTrivialCall()` for expression evaluation
7. Register plugin in LLDB build system

**Deliverables:**
- Basic stack traces in LLDB
- Function call evaluation

**Test:**
```bash
lldb ./test.elf
(lldb) bt
# Should show stack trace
```

### Phase 3: LLDB Architecture Plugin (Medium Priority)

1. Create `lldb/source/Plugins/Architecture/V850/` directory
2. Implement `ArchitectureV850` class
3. Handle V850-specific address manipulation
4. Register plugin

**Deliverables:**
- Proper address handling for V850 code/data

### Phase 4: Debug Intrinsics (Medium Priority)

1. Add DBTRAP intrinsic to BuiltinsV850.def
2. Add debug register read/write intrinsics
3. Add breakpoint register intrinsics
4. Implement CodeGen for all intrinsics
5. Add tests

**Deliverables:**
- User-accessible debug functionality from C code

### Phase 5: Hardware Debug Support (Low Priority)

1. Document hardware breakpoint setup procedure
2. Create helper library for breakpoint management
3. Test with actual hardware/simulator

---

## 7. Testing Strategy

### 7.1 Unit Tests

```
llvm/test/CodeGen/V850/
├── debug-info.ll          # Basic debug info generation
├── cfi-prologue.ll        # CFI directive emission
├── cfi-epilogue.ll        # CFI restoration
├── prepare-dispose-cfi.ll # PREPARE/DISPOSE CFI
└── eh-frame.ll            # Exception handling frame
```

### 7.2 Integration Tests

```
lldb/test/API/functionalities/unwind/v850/
├── TestV850Unwind.py
└── main.c
```

### 7.3 Manual Testing

1. Compile test program with `-g`
2. Load in GDB/LLDB
3. Set breakpoints, step through code
4. Verify backtrace at various points
5. Test variable inspection

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
