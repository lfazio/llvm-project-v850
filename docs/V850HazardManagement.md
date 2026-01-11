# V850 Hazard Management Reference

This document consolidates pipeline hazard information across all V850 CPU variants.
This information is essential for implementing LLVM hazard recognizers and scheduling constraints.

## Pipeline Architecture Summary

| CPU Variant | Pipeline Stages | Dual Issue | Hazard Handling |
|-------------|-----------------|------------|-----------------|
| V850        | 5 (IF-ID-EX-MEM-WB) | No | Hardware interlock |
| V850ES      | 5 (IF-ID-EX-DF-WB) + async WB | No | Hardware interlock |
| V850E1      | 5 (IF-ID-EX-DF-WB) + async WB | No | Hardware interlock |
| V850E2      | 7 (IF-DP-ID-EX-AT-DF-WB) | Yes (L/R pipe) | Hardware interlock + dependency check |
| V850E2M     | 7 (IF-DP-ID-EX-AT-DF-WB) | Yes (L/R pipe) | Hardware interlock + SYNCP/SYNCE/SYNCI |
| RH850G3M    | 7 | Yes | Hardware interlock + SYNCP/SYNCE/SYNCI |
| RH850G3MH   | 7+ | Yes | Hardware interlock + SYNCP/SYNCE/SYNCI |
| RH850G4MH   | 7+ | Yes | Same as RH850G3MH + MPU entry load/store hazards |
| RH850G4MH2  | 7+ | Yes | Same as RH850G4MH + virtualization mode hazards |

## Data Hazards

### Load-Use Hazard (All Variants)

When a load instruction result is used by an immediately following instruction, a pipeline stall occurs.

**V850/V850ES/V850E1:**
```
LD.W [r4], r6       ; IF ID EX MEM WB
ADD  r6, r7         ;    IF IL ID  EX  MEM WB   ; IL = interlock stall
```

The hardware interlock automatically inserts 1 cycle stall (IL).
**Result latency: 2 cycles**

**Optimization:** Place 1+ instruction between load and use to avoid stall:
```
LD.W [r4], r6       ; IF ID EX MEM WB
NOP                 ;    IF ID EX  MEM WB      ; or useful instruction
ADD  r6, r7         ;       IF ID  EX  MEM WB  ; no stall
```

**V850E2/E2M/RH850:**
Load latency is 3 cycles. Hardware interlock handles the dependency.
**Result latency: 3 cycles**

**Optimization:** Place 2+ instructions between load and use.

### Multiply-Use Hazard (All Variants)

When a multiply instruction result is used by an immediately following instruction.

**V850/V850ES/V850E1:**
```
MULH r3, r6         ; IF ID EX1 EX2 WB
ADD  r6, r7         ;    IF IL  ID  EX MEM WB  ; IL = interlock stall
```

**Result latency: 2 cycles**

**V850E2/E2M/RH850:**
Multiply latency is 3 cycles.
**Result latency: 3 cycles**

### Divide Instruction Hazard (All Variants)

Division is a long-latency blocking operation.

| CPU | Signed DIV/DIVH | Unsigned DIVU/DIVHU | Notes |
|-----|-----------------|---------------------|-------|
| V850 | 36 cycles | N/A | Blocks pipeline |
| V850ES/E1 | 35 cycles | 34 cycles | Interruptible, restarts from beginning |
| V850E2 | 35 cycles | 34 cycles | Interruptible |
| V850E2M | 36 cycles | 35 cycles | Interruptible |
| RH850G3M | 19 cycles | 19 cycles | Reduced latency |
| RH850G3MH | 19 cycles (issue=1) | 19 cycles | Non-blocking issue |

**Special Note:** If an interrupt occurs during division, the instruction is restarted from the beginning after the interrupt is serviced.

### DIVQ/DIVQU Quick Division (V850E2M+)

Variable-latency division based on operand values:
- Cycles = N + 3 to N + 5 (where N = valid bits of dividend - valid bits of divisor)
- Range: 3 to 19 cycles depending on operands

### System Register Hazards

#### LDSR EIPC/FEPC Hazard (V850/V850ES/V850E1)

When LDSR writes to EIPC or FEPC and STSR immediately reads them:

```
LDSR r6, EIPC       ; IF ID EX  MEM WB
STSR EIPC, r7       ;    IF IL  IL  ID  EX MEM WB  ; 2 cycle interlock
```

**Result latency: 3 cycles**

**Optimization:** Place 2+ instructions between LDSR and STSR for EIPC/FEPC.

## Control Hazards

### Branch Penalty

| Instruction | V850 | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH |
|-------------|------|-----------|--------|---------|----------|-----------|
| Bcond (taken) | 3 | 2 | 4 | 4 | 1-4* | 2-6* |
| Bcond (not taken) | 1 | 1 | 1 | 1 | 1-4* | 2-6* |
| JMP [reg1] | 3 | 3 | 5 | 4 | 4 | 2-6* |
| JR/JARL | 3 | 2 | 4 | 4 | 1-4* | 2-3* |

\* RH850 has branch prediction: 1 cycle if predicted correctly, 4+ cycles if mispredicted.

### Flag Hazard (V850ES/E1)

If a conditional branch immediately follows an instruction that modifies PSW flags:

```
CMP  r1, r2         ; Modifies flags
BEQ  label          ; 3 cycles instead of 2 if condition met
```

**Extra penalty: 1 cycle** when branch depends on just-modified flags.

## Alignment Hazards

### Branch Target Alignment (V850/V850ES/V850E1)

If a 4-byte instruction is at a non-word-aligned address (A1=1, A0=0), an alignment hazard occurs requiring two fetch cycles.

```
; Address X2H (not word-aligned)
ADDI imm16, r1, r2  ; 4-byte instruction at misaligned address
                    ; Requires IF1 + IF2 instead of single IF
```

**Penalty: 1 extra cycle** for branch to misaligned 4-byte instruction.

**Avoidance:**
- Use 2-byte instructions at branch targets
- Align 4-byte branch target instructions to word boundaries (A1=0, A0=0)

## Pipeline Synchronization Instructions (V850E2M+)

### SYNCP - Pipeline Synchronization

Waits for all prior instructions to complete before continuing.

**Required after:**
- LDSR to SCCFG (before SYSCALL)
- LDSR to MPU registers (before Load/Store using new MPU settings)
- LDSR to FPU registers (before FPU operation)

### SYNCE - Exception Synchronization

Waits for pending exceptions to be processed.

**Required before:**
- Changing FPP/FPI exception mode (FPSR.PEM update)

### SYNCI - Instruction Synchronization

Discards unexecuted instructions in pipeline and re-fetches.

**Required after:**
- LDSR to PSW.UM (user mode change)
- LDSR to MCFG0.SPID
- Self-modifying code (writes to instruction memory)

## Dual-Issue Constraints (V850E2+)

### Pipeline Assignment

| Unit | Pipeline | Instructions |
|------|----------|--------------|
| MEM | Lpipe | LD.*, ST.*, SLD.*, SST.* |
| MUL | Lpipe | MUL, MULU, MULH, MULHI, MAC, MACU |
| ALU | Lpipe or Rpipe | ADD, SUB, CMP, MOV, AND, OR, XOR, etc. |
| BSFT | Rpipe | SAR, SHL, SHR, BSH, BSW, HSW, CMOV, SETF, SCH* |
| DIV | Rpipe | DIV, DIVU, DIVH, DIVHU, DIVQ, DIVQU |

### Single-Issue Only Instructions

These instructions cannot be dual-issued with any other instruction:

| Instruction | Reason |
|-------------|--------|
| MOV imm32, reg1 | 6-byte instruction |
| MAC/MACU | Uses both MUL and register file ports |
| ADF/SBF | Conditional arithmetic |
| SATADD/SATSUB (3-op) | Extended saturation |
| PREPARE/DISPOSE | Multi-cycle memory access |
| CAXI | Atomic operation |
| LDL.W/STC.W | Atomic operation |
| TRAP/SYSCALL | Exception |
| EIRET/FERET/RETI | Return from exception |

### Dual-Issue Restrictions

1. **Same pipeline:** Cannot issue two instructions to same pipeline
2. **6-byte instructions:** Cannot dual-issue with any other instruction
3. **Register dependency:** Cannot issue if result of first is source of second
4. **Memory ordering:** Load-store pairs must maintain program order

## System Register Hazard Resolution (RH850G3M/G3MH)

### Instruction Fetch Hazards

After updating these registers, execute EIRET, FERET, or SYNCI before instruction fetch:
- `PSW.UM` (User mode bit)
- `MCFG0.SPID` (System protection ID)

### Load/Store Hazards

After updating these registers, execute SYNCP before Load/Store:
- `ASID` (Address space ID)
- MPU protection area registers (selID 6-7)

### Interrupt-Related Hazards

Update these registers only with interrupts disabled (PSW.ID=1):
- `PSW.EBV` (Exception base vector)
- `EBASE` (Exception handler base)
- `INTBP` (Interrupt handler base)
- `ISPR` (Interrupt status pending)
- `PMR` (Priority mask)
- `ICSR` (Interrupt control status)
- `INTCFG` (Interrupt configuration)
- `FPIPR` (FPU interrupt priority, RH850G3M only)

### FPU Hazards

After updating FPU registers, execute SYNCP, EIRET, or FERET:
- `FPSR` (FPU status register)
- `FPEPC` (FPU exception PC)
- `FPST` (FPU status bits)
- `FPCC` (FPU condition code)
- `FPCFG` (FPU configuration)

When changing FPU exception mode (FPSR.PEM):
1. Execute SYNCP and SYNCE first
2. Update FPSR.PEM
3. Execute SYNCP, EIRET, or FERET

### Coprocessor Enable Hazards

After updating PSW.CU0 (FPU enable), execute EIRET, FERET, SYNCI, or SYNCP before any FPU instruction.

### Cache Control Hazards

When clearing instruction cache (ICCTRL.ICHCLR):
- Read ICCTRL.ICHCLR and verify it returns 0 to confirm completion

## Hazard Summary Table

| Hazard Type | Latency/Penalty | Resolution |
|-------------|-----------------|------------|
| Load-use (V850) | 2 cycles | 1 instruction gap |
| Load-use (V850E2+) | 3 cycles | 2 instruction gap |
| Multiply-use (V850) | 2 cycles | 1 instruction gap |
| Multiply-use (V850E2+) | 3 cycles | 2 instruction gap |
| LDSR EIPC/FEPC (V850) | 3 cycles | 2 instruction gap |
| Divide (V850) | 36 cycles | Blocking |
| Divide (RH850) | 19 cycles | Blocking (G3M) / Non-blocking issue (G3MH/G4MH) |
| Branch taken (V850) | 3 cycles | - |
| Branch taken (V850ES) | 2 cycles | - |
| Branch taken (V850E2) | 4 cycles | - |
| Branch predicted (RH850) | 1 cycle | Branch prediction hit |
| Branch mispredicted (RH850) | 4-6 cycles | Branch prediction miss |
| Alignment hazard | 1 cycle | Align branch targets |
| System register update | Variable | SYNCP/SYNCE/SYNCI |

## RH850G4MH-Specific Hazards

### MPU Entry Load/Store Instructions (RH850G4MH+)

The LDM.MP and STM.MP instructions load/store multiple MPU entry registers and have specific hazard characteristics:

**LDM.MP [reg1], eh-et**
- Loads MPU entries from memory (MPLA, MPUA, MPAT registers)
- Can be interrupted and restarted from beginning
- Memory protection violations detected with updated MPU settings
- Execution latency: N+8 cycles (N = number of entries × 1.5, rounded up)

**STM.MP eh-et, [reg1]**
- Stores MPU entries to memory
- Can be interrupted and restarted from beginning
- Execution latency: N+2 cycles (N = number of entries × 1.5, rounded up)

**Required synchronization:**
- Execute SYNCP after updating MPU registers before Load/Store operations that depend on new settings
- Disable MPU or exclude entries from processing to avoid unintended violations during LDM.MP

### Virtualization Hazards (RH850G4MH2 Only)

**Mode Transition Instructions:**

When EIRET/FERET cause Guest↔Host mode transitions (PSWH.GM changes):
- Return PC loaded from HMEIPC/HMFEPC (not EIPC/FEPC)
- HMPSW restored to HMEIPSW/HMFEPSW
- GMPSW must be set appropriately before executing mode-switching EIRET/FERET
- In Guest mode, EIRET/FERET cannot cause mode transition

**HVTRAP Instruction:**
- Unconditionally transitions Guest → Host mode
- Execution: 8-8-8 cycles (issue-repeat-latency)
- Saves return state to HMEIPC, HMEIPSW, EIPSWH
- Only executable in Supervisor mode when HVCFG.HVE=1

**Guest System Register Instructions:**

**LDM.GSR [reg1]**
- Loads pre-defined guest system registers from memory
- Execution: 26-26-26 cycles (no wait states)
- Can be interrupted and restarted from beginning
- HV privilege instruction (Host mode, Supervisor only)

**STM.GSR [reg1]**
- Stores pre-defined guest system registers to memory
- Execution: 19-19-19 cycles (no wait states)
- Can be interrupted and restarted from beginning
- HV privilege instruction (Host mode, Supervisor only)

**Required synchronization:**
- Guest system registers manipulated even without coprocessor permissions
- No coprocessor unusable exception occurs

## LLVM Implementation Notes

### Hazard Recognizer

For V850, implement a ScheduleHazardRecognizer that tracks:
1. Load instructions and their destination registers
2. Multiply instructions and their destination registers
3. LDSR to EIPC/FEPC
4. Instructions modifying PSW flags before branches

### Scheduling Constraints

1. **Load-use delay:** Insert NOPs or reorder to create gap
2. **Multiply-use delay:** Insert NOPs or reorder to create gap
3. **Division:** Mark as high-latency, resource-blocking
4. **Branch alignment:** Prefer word-aligned branch targets
5. **System register updates:** Insert appropriate sync instructions

### Resource Model

For V850E2+, model the dual-issue pipeline:
- Lpipe resources: MEM, MUL
- Rpipe resources: BSFT, DIV
- Shared resources: ALU (can use either pipe)
- Issue width: 2 (when constraints allow)

### Bypass/Forwarding

The V850 family uses short paths (forwarding) for:
- Load result from MEM stage to ID stage of next instruction
- Multiply result from EX2 stage to ID stage of next instruction
- ALU result from EX stage to ID stage of next instruction

These allow back-to-back dependent operations with 1-cycle penalty instead of full stall.
