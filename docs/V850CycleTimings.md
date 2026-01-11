# V850 Instruction Cycle Timings

This document consolidates instruction execution cycle timings across all V850 CPU variants.
This information is essential for implementing LLVM scheduling models.

## Pipeline Characteristics by CPU Variant

| CPU Variant | Pipeline Stages | Dual Issue | Branch Prediction | Notes |
|-------------|-----------------|------------|-------------------|-------|
| V850        | 5 (IF-ID-EX-MEM-WB) | No | No | Basic RISC pipeline |
| V850ES      | 5 (IF-ID-EX-MEM-WB) | No | No | Same as V850 |
| V850E1      | 5 (IF-ID-EX-MEM-WB) | No | No | Same as V850ES |
| V850E2      | 7 (IF-DP-ID-EX-AT-DF-WB) | Yes (L/R pipe) | No | Dual-issue superscalar |
| V850E2M     | 7 (IF-DP-ID-EX-AT-DF-WB) | Yes (L/R pipe) | No | Same as V850E2 |
| RH850G3M    | 7 | Yes | Yes | Branch prediction added |
| RH850G3MH   | 7+ | Yes | Yes | Advanced out-of-order features |
| RH850G4MH   | 7+ | Yes | Yes | Same as G3MH + MPU load/store instructions |
| RH850G4MH2  | 7+ | Yes | Yes | Same as G4MH + virtualization support |

## Execution Clock Terminology

| Symbol | Meaning |
|--------|---------|
| issue (i) | Cycles before next instruction can start after this one begins |
| repeat (r) | Cycles when same instruction executes consecutively |
| latency (l) | Cycles before result is available to dependent instruction |

Format: issue-repeat-latency (e.g., "1-1-2" means issue=1, repeat=1, latency=2)

## Load Instructions

| Instruction | V850 | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|------|-----------|--------|---------|----------|-----------|-----------|------------|
| LD.B disp16[reg1],reg2 | 1-1-2 | 1-1-2* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* |
| LD.H disp16[reg1],reg2 | 1-1-2 | 1-1-2* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* |
| LD.W disp16[reg1],reg2 | 1-1-2 | 1-1-2* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* |
| LD.BU disp16[reg1],reg2 | N/A | 1-1-2* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* |
| LD.HU disp16[reg1],reg2 | N/A | 1-1-2* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* |
| LD.DW disp23[reg1],reg3 | N/A | N/A | N/A | N/A | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* |
| SLD.B disp7[ep],reg2 | 1-1-2 | 1-1-1* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* |
| SLD.H disp8[ep],reg2 | 1-1-2 | 1-1-1* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* |
| SLD.W disp8[ep],reg2 | 1-1-2 | 1-1-1* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* |
| SLD.BU disp4[ep],reg2 | N/A | 1-1-1* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* |
| SLD.HU disp5[ep],reg2 | N/A | 1-1-1* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* |

\* Depends on memory wait states; values shown assume no wait states.

## Store Instructions

| Instruction | V850 | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|------|-----------|--------|---------|----------|-----------|-----------|------------|
| ST.B reg2,disp16[reg1] | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| ST.H reg2,disp16[reg1] | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| ST.W reg2,disp16[reg1] | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| ST.DW reg3,disp23[reg1] | N/A | N/A | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SST.B reg2,disp7[ep] | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SST.H reg2,disp8[ep] | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SST.W reg2,disp8[ep] | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |

## Arithmetic/Move Instructions

| Instruction | V850 | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|------|-----------|--------|---------|----------|-----------|-----------|------------|
| ADD reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| ADD imm5,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| ADDI imm16,reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SUB reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SUBR reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| CMP reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| CMP imm5,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| MOV reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| MOV imm5,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| MOV imm32,reg1 | N/A | 2-2-2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| MOVEA imm16,reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| MOVHI imm16,reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SETF cccc,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SASF cccc,reg2 | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| CMOV cccc,reg1,reg2,reg3 | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| CMOV cccc,imm5,reg2,reg3 | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| ADF cccc,reg1,reg2,reg3 | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SBF cccc,reg1,reg2,reg3 | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |

## Saturated Arithmetic Instructions

| Instruction | V850 | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|------|-----------|--------|---------|----------|-----------|-----------|------------|
| SATADD reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SATADD imm5,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SATADD reg1,reg2,reg3 | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SATSUB reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SATSUB reg1,reg2,reg3 | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SATSUBI imm16,reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SATSUBR reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |

## Logical Instructions

| Instruction | V850 | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|------|-----------|--------|---------|----------|-----------|-----------|------------|
| AND reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| ANDI imm16,reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| OR reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| ORI imm16,reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| XOR reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| XORI imm16,reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| NOT reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| TST reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |

## Shift Instructions

| Instruction | V850 | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|------|-----------|--------|---------|----------|-----------|-----------|------------|
| SHR imm5,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SHR reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SHR reg1,reg2,reg3 | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SAR imm5,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SAR reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SAR reg1,reg2,reg3 | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SHL imm5,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SHL reg1,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SHL reg1,reg2,reg3 | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| ROTL imm5,reg2,reg3 | N/A | N/A | N/A | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 |
| ROTL reg1,reg2,reg3 | N/A | N/A | N/A | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 |

## Data Manipulation Instructions

| Instruction | V850 | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|------|-----------|--------|---------|----------|-----------|-----------|------------|
| BSH reg2,reg3 | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| BSW reg2,reg3 | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| HSH reg2,reg3 | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| HSW reg2,reg3 | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SXB reg1 | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SXH reg1 | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| ZXB reg1 | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| ZXH reg1 | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| BINS reg1,pos,width,reg2 | N/A | N/A | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |

## Bit Search Instructions

| Instruction | V850 | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|------|-----------|--------|---------|----------|-----------|-----------|------------|
| SCH0L reg2,reg3 | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SCH0R reg2,reg3 | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SCH1L reg2,reg3 | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| SCH1R reg2,reg3 | N/A | N/A | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |

## Multiply Instructions

| Instruction | V850 | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|------|-----------|--------|---------|----------|-----------|-----------|------------|
| MULH reg1,reg2 | 1-1-2 | 1-1-2 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 |
| MULH imm5,reg2 | 1-1-2 | 1-1-2 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 |
| MULHI imm16,reg1,reg2 | 1-1-2 | 1-1-2 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 |
| MUL reg1,reg2,reg3 | N/A | 1-4-5 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 |
| MUL imm9,reg2,reg3 | N/A | 1-4-5 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 |
| MULU reg1,reg2,reg3 | N/A | 1-4-5 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 |
| MULU imm9,reg2,reg3 | N/A | 1-4-5 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 | 1-1-3 |
| MAC reg1,reg2,reg3,reg4 | N/A | N/A | 1-1-3 | 1-1-3 | 1-1-3 | 2-2-4 | 2-2-4 | 2-2-4 |
| MACU reg1,reg2,reg3,reg4 | N/A | N/A | 1-1-3 | 1-1-3 | 1-1-3 | 2-2-4 | 2-2-4 | 2-2-4 |

## Divide Instructions

| Instruction | V850 | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|------|-----------|--------|---------|----------|-----------|-----------|------------|
| DIVH reg1,reg2 | 36-36-36 | 35-35-35 | 35-35-35 | 36-36-36 | 19-19-19 | 1-19-19 | 1-19-19 | 1-19-19 |
| DIV reg1,reg2,reg3 | N/A | 35-35-35 | 35-35-35 | 36-36-36 | 19-19-19 | 1-19-19 | 1-19-19 | 1-19-19 |
| DIVH reg1,reg2,reg3 | N/A | 35-35-35 | 35-35-35 | 36-36-36 | 19-19-19 | 1-19-19 | 1-19-19 | 1-19-19 |
| DIVU reg1,reg2,reg3 | N/A | 34-34-34 | 34-34-34 | 35-35-35 | 19-19-19 | 1-19-19 | 1-19-19 | 1-19-19 |
| DIVHU reg1,reg2,reg3 | N/A | 34-34-34 | 34-34-34 | 35-35-35 | 19-19-19 | 1-19-19 | 1-19-19 | 1-19-19 |
| DIVQ reg1,reg2,reg3 | N/A | N/A | N/A | N+5* | N+3* | N+3* | N+3* | N+3* |
| DIVQU reg1,reg2,reg3 | N/A | N/A | N/A | N+4* | N+3* | N+3* | N+3* | N+3* |

\* N = (valid bits of dividend) - (valid bits of divisor), range 0-16.

## Branch Instructions

| Instruction | V850 | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|------|-----------|--------|---------|----------|-----------|-----------|------------|
| Bcond disp9 (taken) | 3-3-3 | 2-2-2 | 4-4-4 | 4-4-4 | 1-4** | 2-6*** | 2-6*** | 2-6*** |
| Bcond disp9 (not taken) | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-4** | 2-6*** | 2-6*** | 2-6*** |
| Bcond disp17 (taken) | N/A | N/A | N/A | N/A | 1-4** | 2-6*** | 2-6*** | 2-6*** |
| JMP [reg1] | 3-3-3 | 3-3-3 | 5-5-5 | 4-4-4 | 4-4-4 | 2-6*** | 2-6*** | 2-6*** |
| JMP disp32[reg1] | N/A | N/A | 5-5-5 | 5-5-5 | 5-5-5 | 2-7*** | 2-7*** | 2-7*** |
| JR disp22 | 3-3-3 | 2-2-2 | 4-4-4 | 4-4-4 | 1-4** | 2-3*** | 2-3*** | 2-3*** |
| JR disp32 | N/A | N/A | 4-4-4 | 4-4-4 | 1-4** | 2-3*** | 2-3*** | 2-3*** |
| JARL disp22,reg2 | 3-3-3 | 2-2-2 | 4-4-4 | 4-4-4 | 4-4-4 | 2-3*** | 2-3*** | 2-3*** |
| JARL disp32,reg1 | N/A | N/A | 4-4-4 | 4-4-4 | 4-4-4 | 2-3*** | 2-3*** | 2-3*** |
| JARL [reg1],reg3 | N/A | N/A | N/A | N/A | 4-4-4 | 2-6*** | 2-6*** | 2-6*** |
| LOOP reg1,disp16 | N/A | N/A | N/A | N/A | 1-4** | 2-6*** | 2-6*** | 2-6*** |

\*\* RH850G3M: 1 if prediction matched, 4 if not matched
\*\*\* RH850G3MH/G4MH: Varies based on prediction and alignment

## Bit Manipulation Instructions

| Instruction | V850 | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|------|-----------|--------|---------|----------|-----------|-----------|------------|
| SET1 bit#3,disp16[reg1] | 4-4-4 | 3-3-3* | 4-4-4* | 4-4-4* | 4-4-4* | 1-1-4* | 1-1-4* | 1-1-4* |
| CLR1 bit#3,disp16[reg1] | 4-4-4 | 3-3-3* | 4-4-4* | 4-4-4* | 4-4-4* | 1-1-4* | 1-1-4* | 1-1-4* |
| NOT1 bit#3,disp16[reg1] | 4-4-4 | 3-3-3* | 4-4-4* | 4-4-4* | 4-4-4* | 1-1-4* | 1-1-4* | 1-1-4* |
| TST1 bit#3,disp16[reg1] | 3-3-3 | 3-3-3* | 4-4-4* | 4-4-4* | 4-4-4* | 1-1-4* | 1-1-4* | 1-1-4* |
| SET1 reg2,[reg1] | N/A | 3-3-3* | 4-4-4* | 4-4-4* | 4-4-4* | 1-1-4* | 1-1-4* | 1-1-4* |
| CLR1 reg2,[reg1] | N/A | 3-3-3* | 4-4-4* | 4-4-4* | 4-4-4* | 1-1-4* | 1-1-4* | 1-1-4* |
| NOT1 reg2,[reg1] | N/A | 3-3-3* | 4-4-4* | 4-4-4* | 4-4-4* | 1-1-4* | 1-1-4* | 1-1-4* |
| TST1 reg2,[reg1] | N/A | 3-3-3* | 4-4-4* | 4-4-4* | 4-4-4* | 1-1-4* | 1-1-4* | 1-1-4* |

\* Add wait states for memory access

## Special Instructions

| Instruction | V850 | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|------|-----------|--------|---------|----------|-----------|-----------|------------|
| NOP | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| DI | 1-1-1 | 1-1-1 | 2-2-2 | 2-2-2 | 3-3-3 | 3-3-3 | 3-3-3 | 3-3-3 |
| EI | 1-1-1 | 1-1-1 | 2-2-2 | 2-2-2 | 3-3-3 | 3-3-3 | 3-3-3 | 3-3-3 |
| HALT | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 |
| LDSR reg2,regID | 1-1-1* | 1-1-1 | 2-2-2 | 1-4** | 3-3-3 | 3-3-3 | 3-3-3 | 3-3-3 |
| STSR regID,reg2 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-3 | 1-1-3 | 1-1-3 |
| TRAP vector | 4-4-4 | 3-3-3 | 9-9-9 | 7-7-7 | 7-7-7 | 8-8-8 | 8-8-8 | 8-8-8 |
| FETRAP vector | N/A | N/A | N/A | 7-7-7 | 7-7-7 | 8-8-8 | 8-8-8 | 8-8-8 |
| RETI | 4-4-4 | 3-3-3 | Undef | 7-7-7 | 7-7-7 | 8-8-8 | 8-8-8 | 8-8-8 |
| EIRET | N/A | N/A | N/A | 7-7-7 | 7-7-7 | 8-8-8 | 8-8-8 | 8-8-8 |
| FERET | N/A | N/A | N/A | 7-7-7 | N/A | 8-8-8 | 8-8-8 | 8-8-8 |
| CALLT imm6 | N/A | 4-4-4 | 8-8-8 | 10-10-10 | 10-10-10 | 17-17-17 | 17-17-17 | 17-17-17 |
| CTRET | N/A | 3-3-3 | 9-9-9 | 7-7-7 | 7-7-7 | 8-8-8 | 8-8-8 | 8-8-8 |
| SYSCALL vector8 | N/A | N/A | N/A | 10-10-10 | 10-10-10 | 17-17-17 | 17-17-17 | 17-17-17 |
| SWITCH reg1 | N/A | 5-5-5 | 8-8-8 | 8-8-8 | 8-8-8 | 11-18*** | 11-18*** | 11-18*** |
| RIE | N/A | N/A | N/A | 7-7-7 | 7-7-7 | 8-8-8 | 8-8-8 | 8-8-8 |
| SYNCP | N/A | N/A | N/A | Undef* | Undef* | Undef* | Undef* | Undef* |
| SYNCE | N/A | N/A | N/A | N/A | Undef | 1-1-1 | 1-1-1 | 1-1-1 |
| SYNCI | N/A | N/A | N/A | N/A | Undef* | Undef* | Undef* | Undef* |
| SYNCM | N/A | N/A | N/A | N/A | Undef | Undef* | Undef* | Undef* |

\* V850: 3 for EIPC/FEPC, 1 for others
\*\* V850E2M: Varies by register bank
\*\*\* RH850G3MH: Range depends on execution state
Undef\*: Depends on hazard resolution and pipeline state

## PREPARE/DISPOSE Instructions

| Instruction | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|-----------|--------|---------|----------|-----------|-----------|------------|
| PREPARE list12,imm5 | n+1 | n+1 | n+2 | n+2 | N+1 to N+2 | N+1 to N+2 | N+1 to N+2 |
| PREPARE list12,imm5,sp | n+2 | n+1 | n+2 | n+2 | N+2 to N+3 | N+2 to N+3 | N+2 to N+3 |
| PREPARE list12,imm5,imm16 | n+2 | n+1 | n+2 | n+2 | N+2 to N+3 | N+2 to N+3 | N+2 to N+3 |
| PREPARE list12,imm5,imm32 | n+3 | n+1 | n+2 | n+2 | N+2 to N+3 | N+2 to N+3 | N+2 to N+3 |
| DISPOSE imm5,list12 | n+1 | n+1 | n+2 | n+2 | N+1 to N+2 | N+1 to N+2 | N+1 to N+2 |
| DISPOSE imm5,list12,[reg1] | n+3 | n+1 | n+6 | n+4 | N+3 to N+8 | N+3 to N+8 | N+3 to N+8 |

n = number of registers in list12, N = timing range based on implementation

## Debug Instructions

| Instruction | V850ES/E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|-----------|--------|---------|----------|-----------|-----------|------------|
| DBTRAP | 3-3-3 | Undef | Undef | Undef | Undef | Undef | Undef |
| DBRET | 3-3-3 | Undef | Undef | Undef | Undef | Undef | Undef |

## Exclusive Control Instructions (RH850)

| Instruction | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|---------|----------|-----------|-----------|------------|
| CAXI [reg1],reg2,reg3 | 4-4-4* | 4-4-4* | 1-1-8* | 1-1-8* | 1-1-8* |
| LDL.W [reg1],reg3 | N/A | 1-1-3* | 1-1-3* | 1-1-3* | 1-1-3* |
| STC.W reg3,[reg1] | N/A | 1-1-1 | 1-1-6* | 1-1-6* | 1-1-6* |

\* Add wait states for memory access

## Cache Instructions (RH850)

| Instruction | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|----------|-----------|-----------|------------|
| CACHE cacheop,[reg1] | 1-1-Undef | 1-1-1* | 1-1-1* | 1-1-1* |
| PREF prefop,[reg1] | 1-1-1 | 1-1-1* | 1-1-1* | 1-1-1* |

\* Depends on instruction fetch unit state

## Floating-Point Instructions (RH850G3M/G3MH/G4MH)

### Single Precision

| Instruction | RH850G3M (Imprecise) | RH850G3M (Precise) | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|---------------------|-------------------|-----------|-----------|------------|
| ABSF.S | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| ADDF.S | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| SUBF.S | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| NEGF.S | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| MULF.S | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| DIVF.S | 14-14-17 | 20-20-20 | 8-8-11 | 8-8-11 | 8-8-11 |
| SQRTF.S | 14-14-17 | 20-20-20 | 14-14-17 | 14-14-17 | 14-14-17 |
| RECIPF.S | 10-10-13 | 16-16-16 | 8-8-11 | 8-8-11 | 8-8-11 |
| RSQRTF.S | 14-14-17 | 20-20-20 | 21-21-24 | 21-21-24 | 21-21-24 |
| FMAF.S | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| FMSF.S | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| FNMAF.S | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| FNMSF.S | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| MAXF.S | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| MINF.S | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| CMPF.S | 1-1-4 | 7-7-7 | 1-1-1 | 1-1-1 | 1-1-1 |
| CMOVF.S | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| TRFSR | 1-1-1 | 1-1-1 | 1-1-5 | 1-1-5 | 1-1-5 |

### Double Precision

| Instruction | RH850G3M (Imprecise) | RH850G3M (Precise) | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|---------------------|-------------------|-----------|-----------|------------|
| ABSF.D | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| ADDF.D | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| SUBF.D | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| NEGF.D | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| MULF.D | 2-2-5 | 8-8-8 | 4-4-7 | 4-4-7 | 4-4-7 |
| DIVF.D | 30-30-33 | 36-36-36 | 16-16-19 | 16-16-19 | 16-16-19 |
| SQRTF.D | 30-30-33 | 36-36-36 | 30-30-33 | 30-30-33 | 30-30-33 |
| RECIPF.D | 26-26-29 | 32-32-32 | 16-16-19 | 16-16-19 | 16-16-19 |
| RSQRTF.D | 36-36-39 | 42-42-42 | 45-45-48 | 45-45-48 | 45-45-48 |
| MAXF.D | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| MINF.D | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |
| CMPF.D | 1-1-4 | 7-7-7 | 1-1-1 | 1-1-1 | 1-1-1 |
| CMOVF.D | 1-1-4 | 7-7-7 | 1-1-4 | 1-1-4 | 1-1-4 |

### Conversion Instructions

| Instruction | RH850G3M | RH850G3MH | RH850G4MH | RH850G4MH2 |
|-------------|----------|-----------|-----------|------------|
| CVTF.* | 1-1-4 (7 precise) | 1-1-4 | 1-1-4 | 1-1-4 |
| CEILF.* | 1-1-4 (7 precise) | 1-1-4 | 1-1-4 | 1-1-4 |
| FLOORF.* | 1-1-4 (7 precise) | 1-1-4 | 1-1-4 | 1-1-4 |
| TRNCF.* | 1-1-4 (7 precise) | 1-1-4 | 1-1-4 | 1-1-4 |

## RH850G4MH-Specific Instructions

### MPU Entry Load/Store Instructions (RH850G4MH+)

| Instruction | RH850G4MH | RH850G4MH2 | Notes |
|-------------|-----------|------------|-------|
| LDM.MP [reg1], eh-et | N+8 | N+8 | N = int(entries × 1.5 + 0.5), 0 ≤ N ≤ 32. Synchronizes pipeline. |
| STM.MP eh-et, [reg1] | N+2 | N+2 | N = int(entries × 1.5 + 0.5), 0 ≤ N ≤ 32. Synchronizes pipeline. |

\* Values shown assume no memory wait states. Add wait cycles for actual memory latency.
\* Both instructions can be interrupted and restart from beginning.
\* N depends on number of MPU entries (each entry = 3 registers: MPLA, MPUA, MPAT).

### Virtualization Instructions (RH850G4MH2 Only)

| Instruction | Issue | Repeat | Latency | Notes |
|-------------|-------|--------|---------|-------|
| HVTRAP vector5 | 8 | 8 | 8 | Hypervisor trap, forces Guest → Host transition |
| LDM.GSR [reg1] | 26 | 26 | 26 | Load guest system registers. Synchronizes pipeline. |
| STM.GSR [reg1] | 19 | 19 | 19 | Store guest system registers. Synchronizes pipeline. |

\* EIRET/FERET timing unchanged from RH850G3MH but handle Guest/Host mode transitions when PSWH.GM changes.
\* All values assume no memory wait states.
\* LDM.GSR/STM.GSR can be interrupted and restart from beginning.

## Notes for Scheduling Model Implementation

### Resource Classes

1. **V850/ES/E1**: Single-issue, simple resource model
   - ALU: All arithmetic, logical, shift, saturated operations
   - MUL: Multiply unit
   - DIV: Divide unit (blocking)
   - LSU: Load/Store unit
   - BR: Branch unit

2. **V850E2/E2M**: Dual-issue superscalar
   - Lpipe: Load/store, multiply, MAC
   - Rpipe: ALU, shift, data manipulation, bit search
   - Both: Can execute many arithmetic/logical ops
   - Branch: Separate branch unit

3. **RH850G3M/G3MH/G4MH**: Advanced pipeline
   - FPU: Floating-point unit (separate pipe)
   - Additional hazard considerations for branch prediction
   - Non-blocking divide issue (G3MH+)

### Key Scheduling Considerations

1. **Load-use hazards**: Result available after latency cycles
2. **Multiply pipelines**: Different on older vs newer cores
3. **Divide blocking**: Divides block subsequent divides (except G3MH+ non-blocking issue)
4. **Branch prediction**: Significant impact on RH850
5. **FPU latency**: Longer latencies, can run in parallel with integer
6. **Memory wait states**: Add to latency based on system configuration

### Parallel Issue Restrictions (V850E2+)

- Same pipe: Cannot dual-issue
- 6-byte instructions: Cannot dual-issue
- Some special instructions: Single-issue only
- MAC/MACU: Single-issue (V850E2) or 2-cycle (RH850G3MH+)

## Abbreviations and Conventions

- **i-r-l**: issue-repeat-latency timing format
- **N/A**: Instruction not available on this CPU variant
- **Undef**: Undefined or implementation-dependent timing
- **\***: Additional notes or conditions apply (see footnotes)
- **G3M**: RH850G3M
- **G3MH**: RH850G3MH
- **G4MH**: RH850G4MH and RH850G4MH2
