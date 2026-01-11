# V850 Instruction Set Reference

This document provides a comprehensive reference for the V850 instruction set architecture,
covering all instructions from V850 through V850E3.

## Table of Contents

1. [Overview](#overview)
2. [Instruction Formats](#instruction-formats)
3. [PSW Flags (Quick Reference)](#psw-flags-quick-reference)
4. [Instruction Reference](#instruction-reference)
5. [RH850G3M/G3MH Instructions](#rh850g3mg3mh-instructions)
6. [Floating-Point Instructions](#floating-point-instructions)
7. [Registers](#registers)
8. [System Interface](#system-interface)
9. [Opcode Summary](#opcode-summary)
10. [References](#references)
11. [Architecture Evolution Summary](#architecture-evolution-summary)

---

## Overview

The V850 is a 32-bit RISC processor family developed by NEC/Renesas. The architecture
evolved through several generations:

| Architecture | Description |
|-------------|-------------|
| V850 | Base architecture (74 instructions) |
| V850ES | Extended ISA: CALLT, byte swap, 3-operand MUL/DIV, CMOV, etc. (80 instructions) |
| V850E1 | V850ES ISA + additional system registers (debug, breakpoint) |
| V850E2 | Added HSH, ADF/SBF, 3-operand SAR/SHL/SHR, bit search, MAC/MACU, 48-bit jumps |
| V850E2M | Adds FPU, SYSCALL, CAXI, synchronization, memory/processor protection |
| V850E3/E3V5 | Latest extensions with enhanced FPU and additional features |
| RH850G3M | V850E2M + user/supervisor modes, LDL.W/STC.W atomics, BINS, ROTL, LD.DW/ST.DW, LOOP, PUSHSP/POPSP, cache/prefetch |
| RH850G3MH | RH850G3M with performance enhancements, simplified FPU exceptions (FPINT replaces FPP/FPI) |
| RH850G4MH | RH850G3MH + MPU load/store instructions (LDM.MP/STM.MP) for efficient MPU context switching |
| RH850G4MH2 | RH850G4MH + hardware virtualization support (Guest/Host modes, HVTRAP, LDM.GSR/STM.GSR, enhanced EIRET/FERET) |

### CPU Variants

| CPU | Equivalent To | Notes |
|-----|---------------|-------|
| v850 | V850 | Base architecture |
| v850es | V850ES | Extended ISA, basic system registers |
| v850e1 | V850E1 | V850ES ISA + extended debug/breakpoint system registers |
| v850e2 | V850E2 | Extended instructions, 48-bit jumps |
| v850e2m | V850E2M | Adds FPU, protection features |
| v850e2v3 | V850E2M | Same as v850e2m |
| v850e3 | V850E3 | Latest generation |
| v850e3v5 | V850E3 | Same as v850e3 |
| rh850g3m | RH850G3M | User/supervisor modes, atomics, cache control |
| rh850g3mh | RH850G3MH | Enhanced performance G3M variant |
| rh850g4mh | RH850G4MH | RH850G3MH + MPU load/store instructions (LDM.MP/STM.MP), PID[31:24]=06H |
| rh850g4mh2 | RH850G4MH2 | RH850G4MH + virtualization support (HVTRAP, LDM.GSR/STM.GSR, EIRET/FERET enhancements), PID[31:24]=07H |

---

## Instruction Formats

| Format | Size | Description |
|--------|------|-------------|
| I | 16-bit | reg-reg: `opcode[6] reg2[5] reg1[5]` |
| II | 16-bit | imm-reg: `opcode[6] reg2[5] imm5[5]` |
| III | 16-bit | Conditional branch: `disp[4] opcode[4] disp[4] cond[4]` |
| IV-a | 16-bit | Short load/store byte: `reg2[5] opcode[4] disp7[7]` |
| IV-b | 16-bit | Short load/store halfword/word: `reg2[5] opcode[4] disp[6] sub[1]` |
| V | 32-bit | Jump: `reg2[5] opcode[6] disp22[22]` |
| VI | 32-bit | 3-operand: `reg2[5] opcode[6] reg1[5] imm16[16]` |
| VII | 32-bit | Load/store: `reg2[5] opcode[6] reg1[5] disp16[16]` |
| VIII | 32-bit | Bit manipulation: `reg2[5] opcode[6] reg1[5] disp16[13] bit[3]` |
| IX | 32-bit | Extended 1: `reg2[5] 111111[6] reg1[5] subop[16]` |
| X | 32-bit | Extended no-operand: `00000[5] 111111[6] 00000[5] subop[16]` |
| XI | 32-bit | Extended 3-operand: `reg2[5] 111111[6] reg1[5] reg3[5] subop[11]` |
| XII | 32-bit | Extended 2-operand: `reg2[5] 111111[6] 00000[5] reg3[5] subop[11]` |
| XIII | 32-bit | PREPARE/DISPOSE: `list12[12] imm5[5] subop[15]` |
| XIV | 48-bit | Extended load/store (V850E2M): `reg2[5] opcode[6] reg1[5] disp23[23]` |
| FI | 32-bit | FPU Extended 3-operand: `reg2[5] opcode[6] reg1[5] reg3[5] subop[11]` |

### Detailed Bit Layouts

#### Format I (16-bit, reg-reg)
```
15  14  13  12  11  10  9   8   7   6   5   4   3   2   1   0
┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
│     reg2      │         opcode        │        reg1       │
└───────────────┴───────────────────────┴───────────────────┘
```

#### Format II (16-bit, imm-reg)
```
15  14  13  12  11  10  9   8   7   6   5   4   3   2   1   0
┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
│     reg2      │         opcode        │       imm5        │
└───────────────┴───────────────────────┴───────────────────┘
```

#### Format III (16-bit, conditional branch)
```
15  14  13  12  11  10  9   8   7   6   5   4   3   2   1   0
┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
│    disp8:4    │   opcode  │  disp3:0  │      cond         │
└───────────────┴───────────┴───────────┴───────────────────┘
```

#### Format VI (32-bit, 3-operand with immediate)
```
First 16 bits:
15  14  13  12  11  10  9   8   7   6   5   4   3   2   1   0
┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
│     reg2      │         opcode        │        reg1       │
└───────────────┴───────────────────────┴───────────────────┘

Second 16 bits:
31  30  29  28  27  26  25  24  23  22  21  20  19  18  17  16
┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
│                      imm16                                    │
└───────────────────────────────────────────────────────────────┘
```

#### Format IX (32-bit, extended 1)
```
First 16 bits:
15  14  13  12  11  10  9   8   7   6   5   4   3   2   1   0
┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
│     reg2      │    111111     │        reg1       │
└───────────────┴───────────────┴───────────────────┘

Second 16 bits:
31  30  29  28  27  26  25  24  23  22  21  20  19  18  17  16
┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
│                    subopcode                                  │
└───────────────────────────────────────────────────────────────┘
```

---

## PSW Flags (Quick Reference)

The Program Status Word (PSW) contains processor flags used by instructions.
For complete PSW register layouts per CPU variant, see the [System Interface](#system-interface) chapter.

| Bit | Flag | Name | Description |
|-----|------|------|-------------|
| 0 | Z | Zero | Set if result is zero |
| 1 | S | Sign | Set if result is negative |
| 2 | OV | Overflow | Set if signed overflow occurred |
| 3 | CY | Carry | Set if carry/borrow occurred |
| 4 | SAT | Saturated | Set if saturation occurred (cumulative) |
| 5 | ID | Interrupt Disable | Disables EI level exceptions when set |
| 6 | EP | Exception Pending | Exception processing in progress |
| 7 | NP | NMI Pending | NMI/FE level exception processing in progress |

---

## Instruction Reference

Legend for flag effects:
- `*` = Modified according to result
- `-` = Unchanged
- `0` = Cleared to 0

### Basic Arithmetic Instructions

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| ADD | reg1, reg2 | I | V850 | * | * | * | * | - | reg2 = reg2 + reg1 |
| ADD | imm5, reg2 | II | V850 | * | * | * | * | - | reg2 = reg2 + sign_ext(imm5) |
| ADDI | imm16, reg1, reg2 | VI | V850 | * | * | * | * | - | reg2 = reg1 + sign_ext(imm16) |
| SUB | reg1, reg2 | I | V850 | * | * | * | * | - | reg2 = reg2 - reg1 |
| SUBR | reg1, reg2 | I | V850 | * | * | * | * | - | reg2 = reg1 - reg2 (reverse subtract) |
| CMP | reg1, reg2 | I | V850 | * | * | * | * | - | Compare reg2 - reg1 (flags only) |
| CMP | imm5, reg2 | II | V850 | * | * | * | * | - | Compare reg2 - sign_ext(imm5) |
| MOV | reg1, reg2 | I | V850 | - | - | - | - | - | reg2 = reg1 |
| MOV | imm5, reg2 | II | V850 | - | - | - | - | - | reg2 = sign_ext(imm5) |
| MOV | imm32, reg1 | VI | V850E1 | - | - | - | - | - | reg1 = imm32 (48-bit instruction) |
| MOVEA | imm16, reg1, reg2 | VI | V850 | - | - | - | - | - | reg2 = reg1 + sign_ext(imm16) |
| MOVHI | imm16, reg1, reg2 | VI | V850 | - | - | - | - | - | reg2 = reg1 + (imm16 << 16) |

### Multiply Instructions

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| MULH | reg1, reg2 | I | V850 | - | - | - | - | - | reg2 = (s16)reg2 * (s16)reg1 |
| MULH | imm5, reg2 | II | V850 | - | - | - | - | - | reg2 = (s16)reg2 * sign_ext(imm5) |
| MULHI | imm16, reg1, reg2 | VI | V850 | - | - | - | - | - | reg2 = (s16)reg1 * imm16 |
| MUL | reg1, reg2, reg3 | XI | V850E1 | - | - | - | - | - | (reg3,reg2) = reg2 * reg1 (signed 64-bit result) |
| MUL | imm9, reg2, reg3 | XII | V850E1 | - | - | - | - | - | (reg3,reg2) = reg2 * sign_ext(imm9) |
| MULU | reg1, reg2, reg3 | XI | V850E1 | - | - | - | - | - | (reg3,reg2) = reg2 * reg1 (unsigned 64-bit result) |
| MULU | imm9, reg2, reg3 | XII | V850E1 | - | - | - | - | - | (reg3,reg2) = reg2 * zero_ext(imm9) |
| MAC | reg1, reg2, reg3, reg4 | XI | V850E2 | - | - | - | - | - | (reg4,reg3) += reg2 * reg1 (signed MAC) |
| MACU | reg1, reg2, reg3, reg4 | XI | V850E2 | - | - | - | - | - | (reg4,reg3) += reg2 * reg1 (unsigned MAC) |

### Divide Instructions

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| DIVH | reg1, reg2 | I | V850 | - | * | * | * | - | reg2 = reg2 / (s16)reg1 |
| DIVH | reg1, reg2, reg3 | XI | V850E1 | - | * | * | * | - | reg2 = reg2/(s16)reg1, reg3 = remainder |
| DIV | reg1, reg2, reg3 | XI | V850E1 | - | * | * | * | - | reg2 = reg2/reg1, reg3 = remainder |
| DIVQ | reg1, reg2, reg3 | XI | V850E2M | - | * | * | * | - | Quick divide (variable cycles) |
| DIVU | reg1, reg2, reg3 | XI | V850E1 | - | * | * | * | - | Unsigned divide |
| DIVHU | reg1, reg2, reg3 | XI | V850E1 | - | * | * | * | - | Unsigned halfword divide |
| DIVQU | reg1, reg2, reg3 | XI | V850E2M | - | * | * | * | - | Quick unsigned divide |

### Saturated Arithmetic Instructions

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| SATADD | reg1, reg2 | I | V850 | * | * | * | * | * | Saturating add |
| SATADD | imm5, reg2 | II | V850 | * | * | * | * | * | Saturating add immediate |
| SATADD | reg1, reg2, reg3 | XI | V850E2 | * | * | * | * | * | Saturating add 3-operand |
| SATSUB | reg1, reg2 | I | V850 | * | * | * | * | * | Saturating subtract |
| SATSUB | reg1, reg2, reg3 | XI | V850E2 | * | * | * | * | * | Saturating subtract 3-operand |
| SATSUBI | imm16, reg1, reg2 | VI | V850 | * | * | * | * | * | Saturating subtract immediate |
| SATSUBR | reg1, reg2 | I | V850 | * | * | * | * | * | Saturating subtract reverse |

### Logical Instructions

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| AND | reg1, reg2 | I | V850 | - | 0 | * | * | - | reg2 = reg2 & reg1 |
| ANDI | imm16, reg1, reg2 | VI | V850 | - | 0 | * | * | - | reg2 = reg1 & zero_ext(imm16) |
| OR | reg1, reg2 | I | V850 | - | 0 | * | * | - | reg2 = reg2 \| reg1 |
| ORI | imm16, reg1, reg2 | VI | V850 | - | 0 | * | * | - | reg2 = reg1 \| zero_ext(imm16) |
| XOR | reg1, reg2 | I | V850 | - | 0 | * | * | - | reg2 = reg2 ^ reg1 |
| XORI | imm16, reg1, reg2 | VI | V850 | - | 0 | * | * | - | reg2 = reg1 ^ zero_ext(imm16) |
| NOT | reg1, reg2 | I | V850 | - | 0 | * | * | - | reg2 = ~reg1 |
| TST | reg1, reg2 | I | V850 | - | 0 | * | * | - | Test (reg2 & reg1), flags only |

### Shift Instructions

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| SHL | imm5, reg2 | II | V850 | * | 0 | * | * | - | Shift left logical |
| SHL | reg1, reg2 | IX | V850 | * | 0 | * | * | - | Shift left by register |
| SHL | reg1, reg2, reg3 | XI | V850E2 | * | 0 | * | * | - | Shift left 3-operand |
| SHR | imm5, reg2 | II | V850 | * | 0 | * | * | - | Shift right logical |
| SHR | reg1, reg2 | IX | V850 | * | 0 | * | * | - | Shift right by register |
| SHR | reg1, reg2, reg3 | XI | V850E2 | * | 0 | * | * | - | Shift right 3-operand |
| SAR | imm5, reg2 | II | V850 | * | 0 | * | * | - | Shift right arithmetic |
| SAR | reg1, reg2 | IX | V850 | * | 0 | * | * | - | Shift right arithmetic by register |
| SAR | reg1, reg2, reg3 | XI | V850E2 | * | 0 | * | * | - | Shift right arithmetic 3-operand |

### Data Manipulation Instructions

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| BSW | reg2, reg3 | XII | V850E1 | * | 0 | * | * | - | Byte swap word (0xAABBCCDD → 0xDDCCBBAA) |
| BSH | reg2, reg3 | XII | V850E1 | * | 0 | * | * | - | Byte swap halfword (0xAABBCCDD → 0xAABBDDCC) |
| HSW | reg2, reg3 | XII | V850E1 | * | 0 | * | * | - | Halfword swap word (0xAABBCCDD → 0xCCDDAABB) |
| HSH | reg2, reg3 | XII | V850E2 | * | 0 | * | * | - | Halfword swap halfword |
| SXB | reg1 | I | V850E1 | - | - | - | - | - | Sign-extend byte to word |
| SXH | reg1 | I | V850E1 | - | - | - | - | - | Sign-extend halfword to word |
| ZXB | reg1 | I | V850E1 | - | - | - | - | - | Zero-extend byte to word |
| ZXH | reg1 | I | V850E1 | - | - | - | - | - | Zero-extend halfword to word |

### Conditional Instructions

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| SETF | cccc, reg2 | IX | V850 | - | - | - | - | - | Set reg2=1 if condition true, else 0 |
| CMOV | cccc, reg1, reg2, reg3 | XI | V850E1 | - | - | - | - | - | reg3 = cond ? reg1 : reg2 |
| CMOV | cccc, imm5, reg2, reg3 | XII | V850E1 | - | - | - | - | - | reg3 = cond ? sign_ext(imm5) : reg2 |
| SASF | cccc, reg2 | IX | V850E1 | - | - | - | - | - | Shift and set flag |
| ADF | cccc, reg1, reg2, reg3 | XI | V850E2 | * | * | * | * | - | Add if condition true |
| SBF | cccc, reg1, reg2, reg3 | XI | V850E2 | * | * | * | * | - | Subtract if condition true |

### Condition Codes (cccc)

| Code | Name | Condition |
|------|------|-----------|
| 0000 | V | OV = 1 (overflow) |
| 0001 | C/L | CY = 1 (carry/lower) |
| 0010 | Z | Z = 1 (zero) |
| 0011 | NH | (CY or Z) = 1 (not higher) |
| 0100 | S/N | S = 1 (negative) |
| 0101 | T | Always true |
| 0110 | LT | (S xor OV) = 1 (less than signed) |
| 0111 | LE | ((S xor OV) or Z) = 1 (less or equal signed) |
| 1000 | NV | OV = 0 (no overflow) |
| 1001 | NC/NL | CY = 0 (no carry/not lower) |
| 1010 | NZ | Z = 0 (not zero) |
| 1011 | H | (CY or Z) = 0 (higher) |
| 1100 | NS/P | S = 0 (positive) |
| 1101 | SA | SAT = 1 (saturated) |
| 1110 | GE | (S xor OV) = 0 (greater or equal signed) |
| 1111 | GT | ((S xor OV) or Z) = 0 (greater than signed) |

### Branch Instructions

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| JMP | [reg1] | I | V850 | - | - | - | - | - | Jump to address in reg1 |
| JMP | disp32[reg1] | VI | V850E2 | - | - | - | - | - | Jump with 32-bit displacement |
| JR | disp22 | V | V850 | - | - | - | - | - | Jump relative |
| JR | disp32 | VI | V850E2 | - | - | - | - | - | Jump relative 32-bit |
| JARL | disp22, reg2 | V | V850 | - | - | - | - | - | Jump and link (reg2 = return addr) |
| JARL | disp32, reg1 | VI | V850E2 | - | - | - | - | - | Jump and link 32-bit |
| Bcond | disp9 | III | V850 | - | - | - | - | - | Branch if condition (see codes above) |
| SWITCH | reg1 | I | V850E1 | - | - | - | - | - | Table switch |


### Load Instructions

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| LD.B | disp16[reg1], reg2 | VII | V850 | - | - | - | - | - | Load byte (sign-extend to 32 bits) |
| LD.B | disp23[reg1], reg3 | XIV | V850E2M | - | - | - | - | - | Load byte with 23-bit displacement |
| LD.BU | disp16[reg1], reg2 | VII | V850E1 | - | - | - | - | - | Load byte unsigned (zero-extend) |
| LD.BU | disp23[reg1], reg3 | XIV | V850E2M | - | - | - | - | - | Load byte unsigned with 23-bit displacement |
| LD.H | disp16[reg1], reg2 | VII | V850 | - | - | - | - | - | Load halfword (sign-extend to 32 bits) |
| LD.H | disp23[reg1], reg3 | XIV | V850E2M | - | - | - | - | - | Load halfword with 23-bit displacement |
| LD.HU | disp16[reg1], reg2 | VII | V850E1 | - | - | - | - | - | Load halfword unsigned (zero-extend) |
| LD.HU | disp23[reg1], reg3 | XIV | V850E2M | - | - | - | - | - | Load halfword unsigned with 23-bit displacement |
| LD.W | disp16[reg1], reg2 | VII | V850 | - | - | - | - | - | Load word |
| LD.W | disp23[reg1], reg3 | XIV | V850E2M | - | - | - | - | - | Load word with 23-bit displacement |
| SLD.B | disp7[ep], reg2 | IV | V850 | - | - | - | - | - | Short load byte (ep-relative) |
| SLD.BU | disp4[ep], reg2 | IV | V850E1 | - | - | - | - | - | Short load byte unsigned |
| SLD.H | disp8[ep], reg2 | IV | V850 | - | - | - | - | - | Short load halfword (ep-relative) |
| SLD.HU | disp5[ep], reg2 | IV | V850E1 | - | - | - | - | - | Short load halfword unsigned |
| SLD.W | disp8[ep], reg2 | IV | V850 | - | - | - | - | - | Short load word (ep-relative) |

### Store Instructions

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| ST.B | reg2, disp16[reg1] | VII | V850 | - | - | - | - | - | Store byte |
| ST.B | reg3, disp23[reg1] | XIV | V850E2M | - | - | - | - | - | Store byte with 23-bit displacement |
| ST.H | reg2, disp16[reg1] | VII | V850 | - | - | - | - | - | Store halfword |
| ST.H | reg3, disp23[reg1] | XIV | V850E2M | - | - | - | - | - | Store halfword with 23-bit displacement |
| ST.W | reg2, disp16[reg1] | VII | V850 | - | - | - | - | - | Store word |
| ST.W | reg3, disp23[reg1] | XIV | V850E2M | - | - | - | - | - | Store word with 23-bit displacement |
| SST.B | reg2, disp7[ep] | IV | V850 | - | - | - | - | - | Short store byte (ep-relative) |
| SST.H | reg2, disp8[ep] | IV | V850 | - | - | - | - | - | Short store halfword (ep-relative) |
| SST.W | reg2, disp8[ep] | IV | V850 | - | - | - | - | - | Short store word (ep-relative) |

### Bit Manipulation Instructions

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| SET1 | bit#3, disp16[reg1] | VIII | V850 | - | - | - | * | - | Set bit in memory (atomic) |
| SET1 | reg2, [reg1] | IX | V850E1 | - | - | - | * | - | Set bit (reg2 specifies bit, atomic) |
| CLR1 | bit#3, disp16[reg1] | VIII | V850 | - | - | - | * | - | Clear bit in memory (atomic) |
| CLR1 | reg2, [reg1] | IX | V850E1 | - | - | - | * | - | Clear bit (reg2 specifies bit, atomic) |
| NOT1 | bit#3, disp16[reg1] | VIII | V850 | - | - | - | * | - | Invert bit in memory (atomic) |
| NOT1 | reg2, [reg1] | IX | V850E1 | - | - | - | * | - | Invert bit (reg2 specifies bit, atomic) |
| TST1 | bit#3, disp16[reg1] | VIII | V850 | - | - | - | * | - | Test bit in memory |
| TST1 | reg2, [reg1] | IX | V850E1 | - | - | - | * | - | Test bit (reg2 specifies bit) |

### Bit Search Instructions (V850E2+)

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| SCH0L | reg2, reg3 | IX | V850E2 | * | 0 | - | * | - | Search for leftmost 0 bit (CLO) |
| SCH0R | reg2, reg3 | IX | V850E2 | * | 0 | - | * | - | Search for rightmost 0 bit (CTO) |
| SCH1L | reg2, reg3 | IX | V850E2 | * | 0 | - | * | - | Search for leftmost 1 bit (CLZ) |
| SCH1R | reg2, reg3 | IX | V850E2 | * | 0 | - | * | - | Search for rightmost 1 bit (CTZ) |

### Special Instructions

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| NOP | - | I | V850 | - | - | - | - | - | No operation (MOV r0, r0) |
| DI | - | X | V850 | - | - | - | - | - | Disable interrupts (PSW.ID = 1) |
| EI | - | X | V850 | - | - | - | - | - | Enable interrupts (PSW.ID = 0) |
| HALT | - | X | V850 | - | - | - | - | - | Halt CPU until interrupt |
| TRAP | vector5 | X | V850 | - | - | - | - | - | Software trap (vector 0-31) |
| RETI | - | X | V850 | * | * | * | * | * | Return from interrupt (restores PSW) |
| LDSR | reg2, regID | IX | V850 | - | - | - | - | - | Load system register |
| STSR | regID, reg2 | IX | V850 | - | - | - | - | - | Store system register |
| CALLT | imm6 | II | V850E1 | - | - | - | - | - | Call via table (saves CTPC/CTPSW) |
| CTRET | - | X | V850E1 | * | * | * | * | * | Return from CALLT |
| PREPARE | list12, imm5 | XIII | V850E1 | - | - | - | - | - | Function prologue (push regs, allocate stack) |
| PREPARE | list12, imm5, sp/imm | XIII | V850E1 | - | - | - | - | - | Function prologue with frame pointer setup |
| DISPOSE | imm5, list12 | XIII | V850E1 | - | - | - | - | - | Function epilogue (deallocate stack, pop regs) |
| DISPOSE | imm5, list12, [reg1] | XIII | V850E1 | - | - | - | - | - | Function epilogue with tail call |
| DBTRAP | - | I | V850E1 | - | - | - | - | - | Debug trap |
| DBRET | - | X | V850E1 | * | * | * | * | * | Return from debug trap |

### V850E2M+ Instructions

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| CAXI | [reg1], reg2, reg3 | IX | V850E2M | * | - | * | * | - | Compare and exchange (atomic) |
| EIRET | - | X | V850E2M | * | * | * | * | * | Return from EI level exception |
| FERET | - | X | V850E2M | * | * | * | * | * | Return from FE level exception |
| FETRAP | vector4 | X | V850E2M | - | - | - | - | - | FE level trap (vector 0-15) |
| RIE | - | I | V850E2M | - | - | - | - | - | Reserved instruction exception |
| SYSCALL | vector8 | X | V850E2M | - | - | - | - | - | System call (vector 0-255) |

### Synchronization Instructions (V850E2M+)

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| SYNCE | - | I | V850E2M | - | - | - | - | - | Synchronize exceptions (wait for pending) |
| SYNCM | - | I | V850E2M | - | - | - | - | - | Synchronize memory (fence) |
| SYNCP | - | I | V850E2M | - | - | - | - | - | Synchronize pipeline (stall until complete) |
| SYNCI | - | X | RH850G3M | - | - | - | - | - | Synchronize memory for instruction fetches |

---

## RH850G3M/G3MH Instructions

The RH850G3M introduces user/supervisor operating modes, atomic load-linked/store-conditional
instructions, new data manipulation instructions, and cache control capabilities. The RH850G3MH
is a higher-performance variant with simplified FPU exception handling.

### Double-Word Load/Store Instructions (RH850G3M+)

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| LD.DW | disp23[reg1], reg3 | XIV | RH850G3M | - | - | - | - | - | Load double-word (64 bits) to reg3+1:reg3 |
| ST.DW | reg3, disp23[reg1] | XIV | RH850G3M | - | - | - | - | - | Store double-word from reg3+1:reg3 |

Note: reg3 must be an even-numbered register. The pair (reg3+1, reg3) holds the 64-bit value
with the higher 32 bits in reg3+1 and lower 32 bits in reg3.

### Atomic Instructions (RH850G3M+)

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| LDL.W | [reg1], reg3 | IX | RH850G3M | - | - | - | - | - | Load linked word (creates link) |
| STC.W | reg3, [reg1] | IX | RH850G3M | - | - | - | * | - | Store conditional word (Z=1 if success) |
| CLL | - | X | RH850G3M | - | - | - | - | - | Clear load link |

The LDL.W/STC.W pair provides lock-free synchronization for multi-core systems:
1. LDL.W loads a word and creates a "link" to the address
2. STC.W stores only if the link is still valid (no intervening write to that address)
3. Z flag indicates success (Z=1) or failure (Z=0) of the store
4. CLL explicitly clears any active link

Link is automatically cleared by:
- Another LDL.W execution
- STC.W execution (success or failure)
- Context switch (PREPARE, PUSHSP, exception)
- Write to the linked address by any CPU core

### Data Manipulation Instructions (RH850G3M+)

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| BINS | reg1, pos, width, reg2 | XI | RH850G3M | - | - | - | - | - | Bitfield insert |
| ROTL | imm5, reg2, reg3 | XI | RH850G3M | - | - | - | - | - | Rotate left by immediate |
| ROTL | reg1, reg2, reg3 | XI | RH850G3M | - | - | - | - | - | Rotate left by register |

**BINS (Bitfield Insert)**: Inserts the lower `width` bits of reg1 into reg2 starting at bit position `pos`.
Three formats exist based on msb/lsb encoding:
- BINS reg1, pos, width, reg2: reg2[pos+width-1:pos] ← reg1[width-1:0]

**ROTL (Rotate Left)**: reg3 = rotate_left(reg2, amount)
- The rotation amount is imm5 (0-31) or lower 5 bits of reg1

### Stack Manipulation Instructions (RH850G3M+)

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| PUSHSP | rh-rt | X | RH850G3M | - | - | - | - | - | Push registers rh through rt to stack |
| POPSP | rh-rt | X | RH850G3M | - | - | - | - | - | Pop registers rh through rt from stack |

PUSHSP/POPSP provide efficient multi-register push/pop for interrupt handlers:
- PUSHSP rh-rt: Push registers from rh to rt (descending addresses), sp decremented
- POPSP rh-rt: Pop registers from rh to rt (ascending addresses), sp incremented
- rh must be ≤ rt; both specify register numbers (r0-r31)

### Loop Instruction (RH850G3M+)

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| LOOP | reg1, disp16 | VII | RH850G3M | - | - | - | - | - | Decrement and branch if not zero |

Operation: reg1 = reg1 - 1; if (reg1 != 0) PC = PC + sign_ext(disp16)

The LOOP instruction provides efficient loop control, decrementing the counter register
and branching backward if the result is non-zero.

### Extended Branch Instructions (RH850G3M+)

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| Bcond | disp17 | VII | RH850G3M | - | - | - | - | - | Conditional branch with 17-bit displacement |
| JARL | [reg1], reg3 | XI | RH850G3M | - | - | - | - | - | Jump and link indirect |

The 17-bit branch extends the range from ±256 bytes (disp9) to ±64KB.
JARL [reg1], reg3 jumps to address in reg1 and stores return address in reg3.

### Cache Control Instructions (RH850G3M+)

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| CACHE | cacheop, [reg1] | IX | RH850G3M | - | - | - | - | - | Cache operation |
| PREF | prefop, [reg1] | IX | RH850G3M | - | - | - | - | - | Prefetch hint |

**CACHE operations** (cacheop encodes operation type):
- CHBII: Invalidate instruction cache line by index
- CIBII: Invalidate instruction cache line by index (same as CHBII)
- CFALI: Flush and invalidate cache line by address
- CISTI: Store instruction cache tag by index
- CILDI: Load instruction cache tag by index

**PREF** provides hints to the cache system for speculative data loading.
PREF does not cause exceptions and can be executed in any CPU mode.

Privilege requirements:
- CHBII, CIBII, CFALI: Supervisor privilege required
- CISTI, CILDI: Supervisor privilege required
- PREF: No privilege required (can execute in user mode)

### Special Instructions (RH850G3M+)

| Mnemonic | Operands | Format | Arch | CY | OV | S | Z | SAT | Description |
|----------|----------|--------|------|----|----|---|---|-----|-------------|
| SNOOZE | - | X | RH850G3M | - | - | - | - | - | Enter low-power snooze state |

SNOOZE places the CPU in a low-power state while waiting for an event.
Unlike HALT, SNOOZE is typically used for spin-wait optimization.

---

## Floating-Point Instructions

The V850E2M and later CPUs include a floating-point unit (FPU) supporting IEEE 754
single-precision (32-bit) and double-precision (64-bit) operations.

**Note:** The FPU uses general-purpose registers (r0-r31) for floating-point operations.
- Single-precision: Uses individual 32-bit registers (r0-r31)
- Double-precision: Uses register pairs ({r1,r0}, {r3,r2}, ... {r31,r30}), specified by even register

### FPU Arithmetic Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| ADDF.S | reg1, reg2, reg3 | V850E2M | Single-precision add |
| ADDF.D | reg1, reg2, reg3 | V850E2M | Double-precision add |
| SUBF.S | reg1, reg2, reg3 | V850E2M | Single-precision subtract |
| SUBF.D | reg1, reg2, reg3 | V850E2M | Double-precision subtract |
| MULF.S | reg1, reg2, reg3 | V850E2M | Single-precision multiply |
| MULF.D | reg1, reg2, reg3 | V850E2M | Double-precision multiply |
| DIVF.S | reg1, reg2, reg3 | V850E2M | Single-precision divide |
| DIVF.D | reg1, reg2, reg3 | V850E2M | Double-precision divide |
| NEGF.S | reg2, reg3 | V850E2M | Single-precision negate |
| NEGF.D | reg2, reg3 | V850E2M | Double-precision negate |
| ABSF.S | reg2, reg3 | V850E2M | Single-precision absolute value |
| ABSF.D | reg2, reg3 | V850E2M | Double-precision absolute value |
| SQRTF.S | reg2, reg3 | V850E2M | Single-precision square root |
| SQRTF.D | reg2, reg3 | V850E2M | Double-precision square root |
| RECIPF.S | reg2, reg3 | V850E2M | Single-precision reciprocal |
| RECIPF.D | reg2, reg3 | V850E2M | Double-precision reciprocal |
| RSQRTF.S | reg2, reg3 | V850E2M | Single-precision reciprocal square root |
| RSQRTF.D | reg2, reg3 | V850E2M | Double-precision reciprocal square root |
| MAXF.S | reg1, reg2, reg3 | V850E2M | Single-precision maximum |
| MAXF.D | reg1, reg2, reg3 | V850E2M | Double-precision maximum |
| MINF.S | reg1, reg2, reg3 | V850E2M | Single-precision minimum |
| MINF.D | reg1, reg2, reg3 | V850E2M | Double-precision minimum |

### FPU Multiply-Accumulate Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| MADDF.S | reg1, reg2, reg3, reg4 | V850E2M | Fused multiply-add single |
| MSUBF.S | reg1, reg2, reg3, reg4 | V850E2M | Fused multiply-subtract single |
| NMADDF.S | reg1, reg2, reg3, reg4 | V850E2M | Negated fused multiply-add single |
| NMSUBF.S | reg1, reg2, reg3, reg4 | V850E2M | Negated fused multiply-subtract single |

### FPU Comparison Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| CMPF.S | fcond, reg2, reg1, fcbit | V850E2M | Single-precision compare |
| CMPF.D | fcond, reg2, reg1, fcbit | V850E2M | Double-precision compare |

### FPU Conversion Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| CVTF.DS | reg2, reg3 | V850E2M | Convert double to single |
| CVTF.SD | reg2, reg3 | V850E2M | Convert single to double |
| CVTF.WS | reg2, reg3 | V850E2M | Convert word (int32) to single |
| CVTF.WD | reg2, reg3 | V850E2M | Convert word (int32) to double |
| CVTF.SW | reg2, reg3 | V850E2M | Convert single to word (int32) |
| CVTF.DW | reg2, reg3 | V850E2M | Convert double to word (int32) |
| CVTF.LS | reg2, reg3 | V850E2M | Convert long (int64) to single |
| CVTF.LD | reg2, reg3 | V850E2M | Convert long (int64) to double |
| CVTF.SL | reg2, reg3 | V850E2M | Convert single to long (int64) |
| CVTF.DL | reg2, reg3 | V850E2M | Convert double to long (int64) |
| CVTF.UWS | reg2, reg3 | V850E2M | Convert unsigned word to single |
| CVTF.UWD | reg2, reg3 | V850E2M | Convert unsigned word to double |
| CVTF.SUW | reg2, reg3 | V850E2M | Convert single to unsigned word |
| CVTF.DUW | reg2, reg3 | V850E2M | Convert double to unsigned word |
| CVTF.ULS | reg2, reg3 | V850E2M | Convert unsigned long to single |
| CVTF.ULD | reg2, reg3 | V850E2M | Convert unsigned long to double |
| CVTF.SUL | reg2, reg3 | V850E2M | Convert single to unsigned long |
| CVTF.DUL | reg2, reg3 | V850E2M | Convert double to unsigned long |

### FPU Rounding Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| TRNCF.SW | reg2, reg3 | V850E2M | Truncate single to word |
| TRNCF.DW | reg2, reg3 | V850E2M | Truncate double to word |
| TRNCF.SL | reg2, reg3 | V850E2M | Truncate single to long |
| TRNCF.DL | reg2, reg3 | V850E2M | Truncate double to long |
| TRNCF.SUW | reg2, reg3 | V850E2M | Truncate single to unsigned word |
| TRNCF.DUW | reg2, reg3 | V850E2M | Truncate double to unsigned word |
| TRNCF.SUL | reg2, reg3 | V850E2M | Truncate single to unsigned long |
| TRNCF.DUL | reg2, reg3 | V850E2M | Truncate double to unsigned long |
| CEILF.SW | reg2, reg3 | V850E2M | Ceiling single to word |
| CEILF.DW | reg2, reg3 | V850E2M | Ceiling double to word |
| CEILF.SL | reg2, reg3 | V850E2M | Ceiling single to long |
| CEILF.DL | reg2, reg3 | V850E2M | Ceiling double to long |
| CEILF.SUW | reg2, reg3 | V850E2M | Ceiling single to unsigned word |
| CEILF.DUW | reg2, reg3 | V850E2M | Ceiling double to unsigned word |
| CEILF.SUL | reg2, reg3 | V850E2M | Ceiling single to unsigned long |
| CEILF.DUL | reg2, reg3 | V850E2M | Ceiling double to unsigned long |
| FLOORF.SW | reg2, reg3 | V850E2M | Floor single to word |
| FLOORF.DW | reg2, reg3 | V850E2M | Floor double to word |
| FLOORF.SL | reg2, reg3 | V850E2M | Floor single to long |
| FLOORF.DL | reg2, reg3 | V850E2M | Floor double to long |
| FLOORF.SUW | reg2, reg3 | V850E2M | Floor single to unsigned word |
| FLOORF.DUW | reg2, reg3 | V850E2M | Floor double to unsigned word |
| FLOORF.SUL | reg2, reg3 | V850E2M | Floor single to unsigned long |
| FLOORF.DUL | reg2, reg3 | V850E2M | Floor double to unsigned long |

### FPU Status Transfer Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| TRFSR | fcbit | V850E2M | Transfer FPU status to PSW.Z |

---

## FXU (Extended Floating-Point) Instructions (RH850G4MH+)

The RH850G4MH and later CPUs include an extended floating-point unit (FXU) that provides
SIMD (Single Instruction Multiple Data) operations on 128-bit vector registers. The FXU
can perform 4 parallel single-precision floating-point operations.

**Note:** The FXU is a separate coprocessor from the FPU. Both can be present in the same CPU.

### FXU Overview

| Feature | Description |
|---------|-------------|
| Vector width | 128 bits (4 × 32-bit single-precision) |
| Vector registers | wreg0-wreg31 (32 vector registers) |
| Operations | 4 parallel single-precision float operations |
| IEEE 754 | Compliant data types and exceptions |
| Rounding modes | Nearest, Zero, +∞, −∞ |
| Subnormals | Flush to zero or exception |
| Status register | FXSR (independent from FPU's FPSR) |

### FXU Vector Registers (wreg0-wreg31)

The FXU has 32 dedicated 128-bit vector registers (wreg0-wreg31), each holding 4 single-precision values.

```
128-bit Vector Register Layout:
┌───────────────┬───────────────┬───────────────┬───────────────┐
│     w3        │     w2        │     w1        │     w0        │
│  bits 127:96  │  bits 95:64   │  bits 63:32   │  bits 31:0    │
│  (element 3)  │  (element 2)  │  (element 1)  │  (element 0)  │
└───────────────┴───────────────┴───────────────┴───────────────┘
```

Each element (w0, w1, w2, w3) holds a 32-bit IEEE 754 single-precision float.

### FXU Coprocessor Enable

FXU access requires PSW.CU1=1 (Coprocessor 1 Use Permission). Executing FXU instructions
with CU1=0 causes a Coprocessor Unusable Exception (cause code 0x81).

### FXU Instruction Formats

| Format | Size | Description |
|--------|------|-------------|
| M: 2OP | 32-bit | 2-operand vector: `opcode wreg2, wreg3` |
| M: 3OP | 32-bit | 3-operand vector: `opcode wreg1, wreg2, wreg3` |
| M: 4OP | 48-bit | 4-operand vector: `opcode wreg1, wreg2, wreg3, wreg4` |
| M: I12 | 48-bit | Immediate with 12-bit constant |
| M: MEM | 48-bit | Memory operations with reg1, reg2, wreg3 |

### FXU Vector Manipulation Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| MOVV.W4 | wreg2, wreg3 | RH850G4MH | Move vector register to vector register |
| FLPV.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Flip (exchange) vector elements |
| SHFLV.W4 | imm12, wreg1, wreg2, wreg3 | RH850G4MH | Vector element shuffle |

### FXU Vector Load/Store Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| LDV.W | disp16[reg1], wreg3 | RH850G4MH | Load single word to vector element |
| LDV.DW | disp16[reg1], wreg3 | RH850G4MH | Load double-word to vector elements |
| LDV.QW | disp16[reg1], wreg3 | RH850G4MH | Load quad-word (full 128-bit vector) |
| LDVZ.H4 | disp16[reg1], wreg3 | RH850G4MH | Load 4 halfwords, zero-extend to words |
| STV.W | wreg3, disp16[reg1] | RH850G4MH | Store single word from vector element |
| STV.DW | wreg3, disp16[reg1] | RH850G4MH | Store double-word from vector elements |
| STV.QW | wreg3, disp16[reg1] | RH850G4MH | Store quad-word (full 128-bit vector) |
| STVZ.H4 | wreg3, disp16[reg1] | RH850G4MH | Store 4 words truncated to halfwords |

### FXU Vector Arithmetic Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| ABSF.S4 | wreg2, wreg3 | RH850G4MH | Vector absolute value (4× single) |
| NEGF.S4 | wreg2, wreg3 | RH850G4MH | Vector negate (4× single) |
| ADDF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Vector add (4× single) |
| SUBF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Vector subtract (4× single) |
| MULF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Vector multiply (4× single) |
| DIVF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Vector divide (4× single) |
| MAXF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Vector maximum (4× single) |
| MINF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Vector minimum (4× single) |
| SQRTF.S4 | wreg2, wreg3 | RH850G4MH | Vector square root (4× single) |
| RECIPF.S4 | wreg2, wreg3 | RH850G4MH | Vector reciprocal (4× single) |
| RSQRTF.S4 | wreg2, wreg3 | RH850G4MH | Vector reciprocal sqrt (4× single) |

### FXU Vector Fused Multiply-Add Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| FMAF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Vector fused multiply-add: w3 = w2*w1 + w3 |
| FMSF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Vector fused multiply-sub: w3 = w2*w1 - w3 |
| FNMAF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Vector neg fused multiply-add: w3 = -(w2*w1) + w3 |
| FNMSF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Vector neg fused multiply-sub: w3 = -(w2*w1) - w3 |

### FXU Compound Arithmetic Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| ADDSUBF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Add odd elements, subtract even elements |
| ADDSUBNF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Add/sub with negation |
| SUBADDF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Subtract odd elements, add even elements |
| SUBADDNF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Sub/add with negation |

### FXU Exchange Arithmetic Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| ADDXF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Add with element exchange |
| SUBXF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Subtract with element exchange |
| MULXF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Multiply with element exchange |
| ADDSUBXF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Add/sub with element exchange |
| ADDSUBNXF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Add/sub neg with element exchange |
| SUBADDXF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Sub/add with element exchange |
| SUBADDNXF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Sub/add neg with element exchange |

### FXU Reduction Arithmetic Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| ADDRF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Add reduction: pairwise add and combine |
| SUBRF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Subtract reduction |
| MULRF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Multiply reduction |
| MAXRF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Maximum reduction |
| MINRF.S4 | wreg1, wreg2, wreg3 | RH850G4MH | Minimum reduction |

### FXU Conversion Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| CVTF.WS4 | wreg2, wreg3 | RH850G4MH | Convert 4× word to 4× single |
| CVTF.SW4 | wreg2, wreg3 | RH850G4MH | Convert 4× single to 4× word |
| CVTF.UWS4 | wreg2, wreg3 | RH850G4MH | Convert 4× unsigned word to 4× single |
| CVTF.SUW4 | wreg2, wreg3 | RH850G4MH | Convert 4× single to 4× unsigned word |
| CVTF.HS4 | wreg2, wreg3 | RH850G4MH | Convert 4× half to 4× single (zero-extend) |
| CVTF.SH4 | wreg2, wreg3 | RH850G4MH | Convert 4× single to 4× half (truncate) |
| TRNCF.SW4 | wreg2, wreg3 | RH850G4MH | Truncate 4× single to 4× word |
| TRNCF.SUW4 | wreg2, wreg3 | RH850G4MH | Truncate 4× single to 4× unsigned word |
| CEILF.SW4 | wreg2, wreg3 | RH850G4MH | Ceiling 4× single to 4× word |
| CEILF.SUW4 | wreg2, wreg3 | RH850G4MH | Ceiling 4× single to 4× unsigned word |
| FLOORF.SW4 | wreg2, wreg3 | RH850G4MH | Floor 4× single to 4× word |
| FLOORF.SUW4 | wreg2, wreg3 | RH850G4MH | Floor 4× single to 4× unsigned word |
| ROUNDF.SW4 | wreg2, wreg3 | RH850G4MH | Round 4× single to 4× word |
| ROUNDF.SUW4 | wreg2, wreg3 | RH850G4MH | Round 4× single to 4× unsigned word |

### FXU Comparison Instructions

| Mnemonic | Operands | Arch | Description |
|----------|----------|------|-------------|
| CMPF.S4 | fcond, wreg1, wreg2, wreg3 | RH850G4MH | Compare 4× single, result in wreg3 |
| CMOVF.W4 | wreg1, wreg2, wreg3, wreg4 | RH850G4MH | Conditional move based on wreg3 mask |
| TRFSRV.W4 | imm3, wreg3 | RH850G4MH | Transfer vector compare result to PSW.Z |

### FXU Instruction Summary

| Category | Count | Description |
|----------|-------|-------------|
| Vector Manipulation | 3 | MOVV, FLPV, SHFLV |
| Load/Store | 8 | LDV, STV variants |
| Basic Arithmetic | 11 | ABSF, NEGF, ADDF, SUBF, MULF, DIVF, MAXF, MINF, SQRTF, RECIPF, RSQRTF |
| Fused Multiply-Add | 4 | FMAF, FMSF, FNMAF, FNMSF |
| Compound | 4 | ADDSUBF, ADDSUBNF, SUBADDF, SUBADDNF |
| Exchange | 7 | ADDXF, SUBXF, MULXF, and exchange variants |
| Reduction | 5 | ADDRF, SUBRF, MULRF, MAXRF, MINRF |
| Conversion | 14 | CVTF, TRNCF, CEILF, FLOORF, ROUNDF variants |
| Comparison | 3 | CMPF, CMOVF, TRFSRV |
| **Total** | **59** | All FXU instructions |

### FXU Opcode Encoding (RH850G4MH+)

All FXU instructions use `bits[10:5] = 111111` (opcode 0x3F) as the primary opcode.
The instruction format is determined by `bits[26:23]` (category) and `bits[22:17]` (sub-opcode).

**FXU Format Encoding (bits[10:5] = 111111):**

```
Format M: 2OP (32-bit)
  15           11 10      5 4              0 31          27 26  23 22      17 16
  ┌─────────────┬─────────┬────────────────┬─────────────┬──────┬───────────┬──┐
  │    wreg2    │ 111111  │   sub-opcode   │    wreg3    │ cat  │  sub-op   │  │
  └─────────────┴─────────┴────────────────┴─────────────┴──────┴───────────┴──┘

Format M: 3OP (32-bit)
  15           11 10      5 4              0 31          27 26  23 22      17 16
  ┌─────────────┬─────────┬────────────────┬─────────────┬──────┬───────────┬──┐
  │    wreg2    │ 111111  │     wreg1      │    wreg3    │ cat  │  sub-op   │  │
  └─────────────┴─────────┴────────────────┴─────────────┴──────┴───────────┴──┘

Format M: 4OP (48-bit)
  15           11 10      5 4              0 31          27 26             16
  ┌─────────────┬─────────┬────────────────┬─────────────┬─────────────────┐
  │  sub-opcode │ 111111  │     wreg1      │    wreg3    │    sub-opcode   │
  └─────────────┴─────────┴────────────────┴─────────────┴─────────────────┘
  47           43 42      37 36           32
  ┌─────────────┬─────────┬────────────────┐
  │    wreg2    │ sub-op  │     wreg4      │
  └─────────────┴─────────┴────────────────┘

Format M: D (48-bit, memory access)
  15           11 10      5 4              0 31          27 26             16
  ┌─────────────┬─────────┬────────────────┬─────────────┬─────────────────┐
  │   sub-op    │ 11110 1 │      reg1      │    wreg3    │    sub-opcode   │
  └─────────────┴─────────┴────────────────┴─────────────┴─────────────────┘
  47                                       32
  ┌─────────────────────────────────────────┐
  │               disp16                    │
  └─────────────────────────────────────────┘
```

**Category Codes (bits[26:23]):**

| Category | Binary | Hex | Description |
|----------|--------|-----|-------------|
| 0xB | 1011 | 0xB | FXU Vector Arithmetic/Manipulation |
| 0x9 | 1001 | 0x9 | FXU Fused Multiply-Accumulate |
| 0xC | 1100 | 0xC | FXU Conditional Operations |
| 0x6 | 0110 | 0x6 | FXU Load/Store (Format M:D) |

#### FXU Vector Manipulation Opcodes

| Instruction | Format | bits[26:23] | bits[22:17] | bits[4:0] | Full Opcode (hex) |
|-------------|--------|-------------|-------------|-----------|-------------------|
| MOVV.W4 wreg2, wreg3 | M: 2OP | 1011 | 010000 | 11110 | 0x07E0_B400 |
| FLPV.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 010000 | wreg1 | varies |
| SHFLV.W4 imm12, wreg1, wreg2, wreg3 | M: imm12 | 1011 | - | - | 48-bit format |

#### FXU Load/Store Opcodes

| Instruction | Format | bits[15:11] | bits[26:17] | Notes |
|-------------|--------|-------------|-------------|-------|
| LDV.W imm4, disp16[reg1], wreg3 | M: D | 00000 | 0110_ii_1110_1 | ii = element select |
| LDV.DW imm2, disp16[reg1], wreg3 | M: D | 00000 | 0110_ii_1110_1 | ii = dword select |
| LDV.QW disp16[reg1], wreg3 | M: D | 00000 | 0110_00_1110_1 | Full 128-bit load |
| LDVZ.H4 disp16[reg1], wreg3 | M: D | 00000 | 0110_ii_1110_1 | Halfword zero-extend |
| STV.W imm4, wreg3, disp16[reg1] | M: D | 00000 | 0111_ii_1110_1 | ii = element select |
| STV.DW imm1, wreg3, disp16[reg1] | M: D | 00000 | 0111_ii_1110_1 | ii = dword select |
| STV.QW wreg3, disp16[reg1] | M: D | 00000 | 0111_00_1110_1 | Full 128-bit store |
| STVZ.H4 wreg3, disp16[reg1] | M: D | 00000 | 0111_ii_1110_1 | Halfword truncate |

#### FXU Basic Arithmetic Opcodes

| Instruction | Format | bits[26:23] | bits[22:17] | Category | Sub-op (hex) |
|-------------|--------|-------------|-------------|----------|--------------|
| ABSF.S4 wreg2, wreg3 | M: 2OP | 1011 | 010000 | 0xB | 0x10 |
| NEGF.S4 wreg2, wreg3 | M: 2OP | 1011 | 010001 | 0xB | 0x11 |
| ADDF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 010010 | 0xB | 0x12 |
| SUBF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 010011 | 0xB | 0x13 |
| MULF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 010100 | 0xB | 0x14 |
| DIVF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 011110 | 0xB | 0x1E |
| MAXF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 011100 | 0xB | 0x1C |
| MINF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 011101 | 0xB | 0x1D |
| SQRTF.S4 wreg2, wreg3 | M: 2OP | 1011 | 011000 | 0xB | 0x18 |
| RECIPF.S4 wreg2, wreg3 | M: 2OP | 1011 | 011001 | 0xB | 0x19 |
| RSQRTF.S4 wreg2, wreg3 | M: 2OP | 1011 | 011010 | 0xB | 0x1A |

#### FXU Fused Multiply-Add Opcodes

| Instruction | Format | bits[26:23] | bits[22:17] | Category | Sub-op (hex) |
|-------------|--------|-------------|-------------|----------|--------------|
| FMAF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1001 | 100000 | 0x9 | 0x20 |
| FMSF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1001 | 100001 | 0x9 | 0x21 |
| FNMAF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1001 | 100010 | 0x9 | 0x22 |
| FNMSF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1001 | 100011 | 0x9 | 0x23 |

#### FXU Compound Arithmetic Opcodes

| Instruction | Format | bits[26:23] | bits[22:17] | Category | Sub-op (hex) |
|-------------|--------|-------------|-------------|----------|--------------|
| ADDSUBF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 101000 | 0xB | 0x28 |
| ADDSUBNF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 101100 | 0xB | 0x2C |
| SUBADDF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 101001 | 0xB | 0x29 |
| SUBADDNF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 101101 | 0xB | 0x2D |

#### FXU Exchange Arithmetic Opcodes

| Instruction | Format | bits[26:23] | bits[22:17] | Category | Sub-op (hex) |
|-------------|--------|-------------|-------------|----------|--------------|
| ADDXF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 100010 | 0xB | 0x22 |
| SUBXF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 100011 | 0xB | 0x23 |
| MULXF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 100100 | 0xB | 0x24 |
| ADDSUBXF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 101010 | 0xB | 0x2A |
| ADDSUBNXF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 101110 | 0xB | 0x2E |
| SUBADDXF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 101011 | 0xB | 0x2B |
| SUBADDNXF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 101111 | 0xB | 0x2F |

#### FXU Reduction Arithmetic Opcodes

| Instruction | Format | bits[26:23] | bits[22:17] | Category | Sub-op (hex) |
|-------------|--------|-------------|-------------|----------|--------------|
| ADDRF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 110100 | 0xB | 0x34 |
| SUBRF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 110101 | 0xB | 0x35 |
| MULRF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 110110 | 0xB | 0x36 |
| MAXRF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 110111 | 0xB | 0x37 |
| MINRF.S4 wreg1, wreg2, wreg3 | M: 3OP | 1011 | 111000 | 0xB | 0x38 |

#### FXU Conversion Opcodes

| Instruction | Format | bits[26:23] | bits[22:17] | Category | Sub-op (hex) |
|-------------|--------|-------------|-------------|----------|--------------|
| CVTF.WS4 wreg2, wreg3 | M: 2OP | 1011 | 000000 | 0xB | 0x00 |
| CVTF.SW4 wreg2, wreg3 | M: 2OP | 1011 | 000001 | 0xB | 0x01 |
| CVTF.UWS4 wreg2, wreg3 | M: 2OP | 1011 | 010000 | 0xB | 0x10 |
| CVTF.SUW4 wreg2, wreg3 | M: 2OP | 1011 | 010001 | 0xB | 0x11 |
| CVTF.HS4 wreg2, wreg3 | M: 2OP | 1011 | 000010 | 0xB | 0x02 |
| CVTF.SH4 wreg2, wreg3 | M: 2OP | 1011 | 000011 | 0xB | 0x03 |
| TRNCF.SW4 wreg2, wreg3 | M: 2OP | 1011 | 000100 | 0xB | 0x04 |
| TRNCF.SUW4 wreg2, wreg3 | M: 2OP | 1011 | 010100 | 0xB | 0x14 |
| CEILF.SW4 wreg2, wreg3 | M: 2OP | 1011 | 000101 | 0xB | 0x05 |
| CEILF.SUW4 wreg2, wreg3 | M: 2OP | 1011 | 010101 | 0xB | 0x15 |
| FLOORF.SW4 wreg2, wreg3 | M: 2OP | 1011 | 000110 | 0xB | 0x06 |
| FLOORF.SUW4 wreg2, wreg3 | M: 2OP | 1011 | 010110 | 0xB | 0x16 |
| ROUNDF.SW4 wreg2, wreg3 | M: 2OP | 1011 | 000111 | 0xB | 0x07 |
| ROUNDF.SUW4 wreg2, wreg3 | M: 2OP | 1011 | 010111 | 0xB | 0x17 |

#### FXU Comparison Opcodes

| Instruction | Format | bits[26:23] | bits[22:17] | Category | Sub-op (hex) |
|-------------|--------|-------------|-------------|----------|--------------|
| CMPF.S4 fcond, wreg1, wreg2, wreg3 | M: 3OP | 1011 | 001100 | 0xB | 0x0C |
| CMOVF.W4 wreg1, wreg2, wreg3, wreg4 | M: 4OP | 1100 | 001110 | 0xC | 0x0E |
| TRFSRV.W4 imm3, wreg3 | M: 2OP | 1011 | 001111 | 0xB | 0x0F |

---

## Registers

### General Purpose Registers (r0-r31)

The V850 has 32 general-purpose 32-bit registers. All registers except r0 can be used freely.

| Register | Alias | Integer Use | FPU Use (V850E2M+) | Description |
|----------|-------|-------------|-------------------|-------------|
| r0 | zero | Always 0 (hardwired) | wr0 (LSB) | Zero register; writes ignored |
| r1 | - | Assembler temporary | wr0 (MSB) | Paired with r0 for 64-bit FP operations |
| r2 | hp | Handler pointer | wr1 (LSB) | Handler pointer or general purpose |
| r3 | sp | Stack pointer | wr1 (MSB) | Stack pointer (critical for function calls) |
| r4 | gp | Global pointer | wr2 (LSB) | Global data pointer |
| r5 | tp | Text pointer | wr2 (MSB) | Text/constant data pointer |
| r6 | - | General purpose | wr3 (LSB) | General purpose |
| r7 | - | General purpose | wr3 (MSB) | General purpose |
| r8 | - | General purpose | wr4 (LSB) | General purpose |
| r9 | - | General purpose | wr4 (MSB) | General purpose |
| r10 | - | General purpose | wr5 (LSB) | General purpose |
| r11 | - | General purpose | wr5 (MSB) | General purpose |
| r12 | - | General purpose | wr6 (LSB) | General purpose |
| r13 | - | General purpose | wr6 (MSB) | General purpose |
| r14 | - | General purpose | wr7 (LSB) | General purpose |
| r15 | - | General purpose | wr7 (MSB) | General purpose |
| r16 | - | General purpose | wr8 (LSB) | General purpose |
| r17 | - | General purpose | wr8 (MSB) | General purpose |
| r18 | - | General purpose | wr9 (LSB) | General purpose |
| r19 | - | General purpose | wr9 (MSB) | General purpose |
| r20 | - | General purpose | wr10 (LSB) | General purpose |
| r21 | - | General purpose | wr10 (MSB) | General purpose |
| r22 | - | General purpose | wr11 (LSB) | General purpose |
| r23 | - | General purpose | wr11 (MSB) | General purpose |
| r24 | - | General purpose | wr12 (LSB) | General purpose |
| r25 | - | General purpose | wr12 (MSB) | General purpose |
| r26 | - | General purpose | wr13 (LSB) | General purpose |
| r27 | - | General purpose | wr13 (MSB) | General purpose |
| r28 | - | General purpose | wr14 (LSB) | General purpose |
| r29 | - | General purpose | wr14 (MSB) | General purpose |
| r30 | ep | Element pointer | wr15 (LSB) | Base register for SLD/SST short load/store |
| r31 | lp | Link pointer | wr15 (MSB) | Return address for function calls |

**Notes:**
- **Integer Operations:** All registers r1-r31 can store 32-bit integer values
- **FPU Operations (V850E2M+):** The FPU uses register pairs for floating-point data:
  - **Single-precision (32-bit):** Uses even registers (r0, r2, r4, ..., r30) only
  - **Double-precision (64-bit):** Uses register pairs (r0+r1=wr0, r2+r3=wr1, etc.)
  - Notation: wr0-wr15 represents 16 logical 64-bit FP registers formed from r0-r31 pairs
- **Stack Pointer (r3):** Must always point to valid stack memory when making function calls
- **Element Pointer (r30):** Used as base for short displacement load/store instructions (SLD/SST)
- **Link Pointer (r31):** Automatically set by JAL/JARL instructions; holds return address

---

## System Interface

This chapter consolidates all system register descriptions for the V850 family, with register
layouts organized by CPU variant.

### System Register Access Models

The V850 family uses different system register access models across generations:

| Generation | Model | Access Method |
|------------|-------|---------------|
| V850/V850ES/V850E1 | Flat | `LDSR reg2, regID` / `STSR regID, reg2` (regID 0-31) |
| V850E2M | Bank Selection | `LDSR/STSR` with BSEL register selecting active bank |
| RH850G3M/G3MH | Group Selection | `LDSR reg2, regID, selID` / `STSR regID, reg2, selID` |

#### V850E2M Bank Selection Model

The V850E2M uses the BSEL register (SR31) to select which bank of system registers is active.
Each bank provides a different view of registers 0-27, while registers 28-31 remain accessible.

| BSEL Value | Bank | Contents |
|------------|------|----------|
| 0x0000 | CPU Main | Basic CPU registers (EIPC, PSW, ECR, etc.) |
| 0x0010 | Exception Handler 0 | Banked exception context |
| 0x0011 | Exception Handler 1 | Banked exception context |
| 0x1000 | Processor Protection 0 | MPU configuration (violation registers) |
| 0x1010 | Processor Protection 1 | MPU configuration (software paging) |
| 0x1001 | Processor Protection 1 | MPU configuration |
| 0x2000 | FPU Status | Floating-point registers |
| 0xFF00 | User Bank 0 | User-accessible registers |
| 0xFFFF | User Compatible | Backward compatibility mapping |

**Bank Selection Process (V850E2M):**
1. Write desired bank value to BSEL (SR31)
2. Execute synchronization if required
3. Access registers via LDSR/STSR with regID 0-27

#### RH850G3M Group Selection Model (selID)

The RH850G3M replaces bank selection with a simpler group-based approach using selID
as a third operand to LDSR/STSR instructions.

**Syntax:**
- `LDSR reg2, regID, selID` — Load system register
- `STSR regID, reg2, selID` — Store system register

| selID | Group Name | Description |
|-------|------------|-------------|
| 0 | Basic | Core system registers (PSW, exception, CALLT, FPU) |
| 1 | Interrupt | Interrupt control registers (ISPR, PMR, ICSR, INTCFG) |
| 2 | MPU | Memory protection registers (MPM, MPLAn, MPUAn, MPATn) |
| 5 | Cache | Instruction cache control (ICCTRL, ICERR, ICCFG) |
| 6 | MPU Entry | MPU entry protection area (MPLA, MPUA, MPAT) |
| 7 | MPU Entry | MPU entry protection area (MPLA, MPUA, MPAT) - alternate bank |
| 10 | FPU | Floating-point control (alternative access) |
| 13 | Guest | Guest mode system registers (RH850G4MH2 only) |

**RH850G4MH2 Extensions:**
- selID 13: Guest mode system registers (GMEIPC, GMEIPSW, GMFEPC, GMFEPSW, GMPSW)
- Host mode system registers accessible via selID 0 (HMEIPC, HMEIPSW, HMFEPC, HMFEPSW, HMPSW)

---

### System Register Summary by CPU Variant

This table shows which system registers are available for each CPU variant.

**Legend:**
- ✅ = Available
- ⚠️ = Available with modifications/extensions
- ❌ = Not available
- SV = Supervisor mode only
- UM = User mode accessible

#### Basic System Registers (selID=0 for RH850)

| Register | regID | V850 | V850ES | V850E1 | V850E2 | V850E2M | RH850G3M | RH850G3MH | RH850G4MH | Description |
|----------|-------|------|--------|--------|--------|---------|----------|-----------|-----------|-------------|
| EIPC | 0 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | EI-level exception PC |
| EIPSW | 1 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | EI-level exception PSW |
| FEPC | 2 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | FE-level exception PC |
| FEPSW | 3 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | FE-level exception PSW |
| PSW | 5 | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | Program status word (extended in later variants) |
| FPSR | 6 | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | FPU status register |
| FPEPC | 7 | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | FPU exception PC |
| FPST | 8 | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | FPU status bits |
| FPCC | 9 | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | FPU condition code |
| FPCFG | 10 | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | FPU configuration |
| FPEC | 11 | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | FPU exception control (removed in G3MH) |
| EIIC | 13 | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | EI-level exception cause |
| FEIC | 14 | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | FE-level exception cause |
| CTPC | 16 | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | CALLT saved PC |
| CTPSW | 17 | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | CALLT saved PSW |
| DBPC | 18 | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Debug exception PC |
| DBPSW | 19 | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Debug exception PSW |
| CTBP | 20 | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | CALLT base pointer |
| DIR | 21 | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Debug interface register |
| EIWR | 28 | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | EI-level working register |
| FEWR | 29 | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | FE-level working register |
| BSEL | 31 | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | Bank select (V850E2M only) |

**V850/V850ES/V850E1 Notes:**
- ECR (regID 4) combines EIIC/FEIC into single register (removed in V850E2M)
- No FPU registers (FPSR-FPCFG)
- PSW has basic 8-bit layout

**V850E2M Notes:**
- BSEL (regID 31) used for bank selection
- Adds FPU registers
- PSW extended with memory protection bits

**RH850G3M+ Notes:**
- BSEL removed; uses selID-based addressing
- FPEC (regID 11) removed in G3MH/G4MH
- PSW adds user/supervisor mode and coprocessor control

#### Interrupt Control Registers (RH850G3M+, selID=1)

| Register | regID | selID | RH850G3M | RH850G3MH | RH850G4MH | Description |
|----------|-------|-------|----------|-----------|-----------|-------------|
| ISPR | 0 | 1 | ✅ | ✅ | ✅ | Interrupt status pending |
| PMR | 1 | 1 | ✅ | ✅ | ✅ | Priority mask register |
| ICSR | 2 | 1 | ✅ | ✅ | ✅ | Interrupt control status |
| INTCFG | 3 | 1 | ✅ | ✅ | ✅ | Interrupt configuration |
| FPIPR | 13 | 1 | ✅ | ❌ | ❌ | FPU interrupt priority (removed in G3MH) |

#### MPU Registers (RH850G3M+, selID=2)

| Register | regID | selID | RH850G3M | RH850G3MH | RH850G4MH | Description |
|----------|-------|-------|----------|-----------|-----------|-------------|
| MPM | 0 | 2 | ✅ | ✅ | ✅ | MPU operation mode |
| MPRC | 1 | 2 | ✅ | ✅ | ✅ | MPU region control |
| MPBRGN | 4 | 2 | ✅ | ✅ | ✅ | MPU base region number (read-only) |
| MPTRGN | 5 | 2 | ✅ | ✅ | ✅ | MPU total region number (read-only) |
| MCA | 8 | 2 | ✅ | ✅ | ✅ | Memory check address |
| MCS | 9 | 2 | ✅ | ✅ | ✅ | Memory check size |
| MCC | 10 | 2 | ✅ | ✅ | ✅ | Memory check command |
| MCR | 11 | 2 | ✅ | ✅ | ✅ | Memory check result (read-only) |
| MPLA0-15 | 16-46 | 2 | ✅ | ✅ | ✅ | Protection area lower address |
| MPUA0-15 | 17-47 | 2 | ✅ | ✅ | ✅ | Protection area upper address |
| MPAT0-15 | 18-48 | 2 | ✅ | ✅ | ✅ | Protection area attributes |

**Note:** MPLAn/MPUAn/MPATn registers organized as triplets for regions 0-15

#### Cache Control Registers (RH850G3M+, selID=5)

| Register | regID | selID | RH850G3M | RH850G3MH | RH850G4MH | Description |
|----------|-------|-------|----------|-----------|-----------|-------------|
| ICCTRL | 0 | 5 | ✅ | ✅ | ✅ | Instruction cache control |
| ICTAGL | 8 | 5 | ✅ | ✅ | ✅ | I-cache tag (low) |
| ICTAGH | 9 | 5 | ✅ | ✅ | ✅ | I-cache tag (high) |
| ICDATL | 10 | 5 | ✅ | ✅ | ✅ | I-cache data (low) |
| ICDATH | 11 | 5 | ✅ | ✅ | ✅ | I-cache data (high) |
| ICERR | 24 | 5 | ✅ | ✅ | ✅ | I-cache error status |
| ICCFG | 26 | 5 | ✅ | ✅ | ✅ | I-cache configuration (read-only) |

#### Virtualization Registers (RH850G4MH2 Only)

**Host Mode Registers (selID=0):**

| Register | regID | selID | Description |
|----------|-------|-------|-------------|
| HMEIPC | 22 | 0 | Host mode EI-level exception PC |
| HMEIPSW | 23 | 0 | Host mode EI-level exception PSW |
| HMFEPC | 24 | 0 | Host mode FE-level exception PC |
| HMFEPSW | 25 | 0 | Host mode FE-level exception PSW |
| HMPSW | 26 | 0 | Host mode PSW |
| HVCFG | 27 | 0 | Hypervisor configuration |
| PSWH | 30 | 0 | PSW high (contains GM bit for Guest/Host mode) |

**Guest Mode Registers (selID=13):**

| Register | regID | selID | Description |
|----------|-------|-------|-------------|
| GMEIPC | 0 | 13 | Guest mode EI-level exception PC |
| GMEIPSW | 1 | 13 | Guest mode EI-level exception PSW |
| GMFEPC | 2 | 13 | Guest mode FE-level exception PC |
| GMFEPSW | 3 | 13 | Guest mode FE-level exception PSW |
| GMPSW | 5 | 13 | Guest mode PSW |

**Notes:**
- Guest/Host mode controlled by PSWH.GM bit
- Host mode registers accessible only when PSWH.GM=0
- Guest mode registers accessible only when PSWH.GM=1 or in Host mode with HV privilege
- LDM.GSR/STM.GSR instructions provide efficient context switching

---

### PSW — Program Status Word

The PSW contains processor flags and control bits. Its layout varies significantly across CPU variants.

#### PSW Register Layout (V850/V850ES/V850E1)

| Bits | Field | Reset | R/W | Description |
|------|-------|-------|-----|-------------|
| 31:8 | - | 0 | R | Reserved (always 0) |
| 7 | NP | 0 | R/W | NMI Pending: disables FE level exceptions when 1 |
| 6 | EP | 0 | R/W | Exception Pending: exception being serviced when 1 |
| 5 | ID | 1 | R/W | Interrupt Disable: disables EI level exceptions when 1 |
| 4 | SAT | 0 | R/W | Saturation flag (cumulative) |
| 3 | CY | 0 | R/W | Carry flag |
| 2 | OV | 0 | R/W | Overflow flag |
| 1 | S | 0 | R/W | Sign flag |
| 0 | Z | 0 | R/W | Zero flag |

**Reset Value:** 0x00000020 (ID=1, all other bits 0)

#### PSW Register Layout (V850E2M)

V850E2M adds memory protection bits to PSW.

```
31   20 19 18 17 16 15   8 7  6  5  4  3  2  1  0
┌────┬──┬──┬──┬──┬────┬──┬──┬──┬──┬──┬──┬──┬──┐
│ 0  │PP│NP│DM│IM│  0 │NP│EP│ID│SA│CY│OV│S │Z │
│    │  │V │P │P │    │  │  │  │T │  │  │  │  │
└────┴──┴──┴──┴──┴────┴──┴──┴──┴──┴──┴──┴──┴──┘
```

| Bits | Field | Reset | R/W | Description |
|------|-------|-------|-----|-------------|
| 31:20 | - | 0 | R | Reserved (always 0) |
| 19 | PP | 0 | R/W | **Peripheral Protection**: Indicates CPU trust level for peripheral access<br>0 = T state (CPU trusts peripheral access)<br>1 = NT state (CPU does not trust peripheral access)<br>When PP=1, peripheral protection function strictly limits accesses |
| 18 | NPV | 0 | R/W | **System Register Protection**: Indicates CPU trust level for system register access<br>0 = T state (CPU trusts system register access)<br>1 = NT state (CPU does not trust system register access)<br>When NPV=1, system register access is limited<br>**Note:** NPV is fixed to 0 when MPM.AUE=0 |
| 17 | DMP | 0 | R/W | **Data Memory Protection**: Indicates CPU trust level for data access<br>0 = T state (CPU trusts data access)<br>1 = NT state (CPU does not trust data access)<br>When DMP=1, data memory protection limits access |
| 16 | IMP | 0 | R/W | **Instruction Memory Protection**: Indicates CPU trust level for instruction fetch<br>0 = T state (CPU trusts instruction fetch)<br>1 = NT state (CPU does not trust instruction fetch)<br>When IMP=1, instruction memory protection limits access |
| 15:8 | - | 0 | R | Reserved (always 0) |
| 7 | NP | 0 | R/W | NMI Pending |
| 6 | EP | 0 | R/W | Exception Pending |
| 5 | ID | 1 | R/W | Interrupt Disable |
| 4 | SAT | 0 | R/W | Saturation flag |
| 3 | CY | 0 | R/W | Carry flag |
| 2 | OV | 0 | R/W | Overflow flag |
| 1 | S | 0 | R/W | Sign flag |
| 0 | Z | 0 | R/W | Zero flag |

**Reset Value:** 0x00000020

**Protection Bit Interaction:**
- These bits interact with MPM.AUE (Auto-Update on Exception)
- When MPM.AUE=1: PP, NPV, DMP, IMP bits are automatically cleared to 0 upon exception
- When MPM.AUE=0: These bits are not automatically updated (except for MDP, MIP, PPI, TSI exceptions and DB-level exceptions, which always update them to 0)
- When MPM.MPE=0: PP bit is fixed to 0 (processor protection disabled)

#### PSW Register Layout (RH850G3M/G3MH)

RH850G3M extends PSW with user/supervisor mode and coprocessor control.

```
31 30 29   19 18 17 16 15 14 12 11 10 9 8 7  6  5  4  3  2  1  0
┌──┬──┬────┬──┬──┬──┬──┬────┬─────────┬─┬──┬──┬──┬──┬──┬──┬──┬──┐
│0 │UM│ 0  │C │C │C │EB│  0 │  Debug  │0│NP│EP│ID│SA│CY│OV│S │Z │
│  │  │    │U2│U1│U0│V │    │         │ │  │  │  │T │  │  │  │  │
└──┴──┴────┴──┴──┴──┴──┴────┴─────────┴─┴──┴──┴──┴──┴──┴──┴──┴──┘
```

| Bits | Field | Reset | Access | Description |
|------|-------|-------|--------|-------------|
| 31 | - | 0 | R | Reserved (always 0) |
| 30 | UM | 0 | SV | **User Mode**: CPU operating mode<br>0 = Supervisor mode (all hardware functions accessible)<br>1 = User mode (restricted hardware functions)<br>**Access:** Read in any mode; write only in supervisor mode<br>Writing in user mode is ignored (no PIE exception) |
| 29:19 | - | 0 | R | Reserved for future expansion (always 0) |
| 18 | CU2 | 0 | SV | **Coprocessor 2 Use Permission** (reserved, set to 0) |
| 17 | CU1 | 0 | SV | **Coprocessor 1 Use Permission** (reserved, set to 0) |
| 16 | CU0 | 0 | SV | **Coprocessor 0 (FPU) Use Permission**<br>0 = FPU disabled (coprocessor unusable exception on FPU instruction)<br>1 = FPU enabled |
| 15 | EBV | 0 | SV | **Exception Base Vector**: Selects exception vector base<br>0 = RBASE register used for reset/exception vectors<br>1 = EBASE register used for exception vectors |
| 14:12 | - | 0 | R | Reserved for future expansion (always 0) |
| 11:9 | Debug | 0 | Special | Debug function field (development tools only, always set to 0) |
| 8 | - | 0 | R | Reserved for future expansion (always 0) |
| 7 | NP | 0 | SV | **NMI Pending**: Disables FE-level exception acknowledgment<br>0 = FE-level exceptions enabled<br>1 = FE-level exceptions disabled (also disables EI-level)<br>Set to 1 when FE-level exception is acknowledged |
| 6 | EP | 0 | SV | **Exception Pending**: Indicates exception (not interrupt) being serviced<br>0 = Interrupt being serviced<br>1 = Exception (other than interrupt) being serviced<br>Does not affect exception acknowledgment |
| 5 | ID | 1 | SV | **Interrupt Disable**: Disables EI-level exception acknowledgment<br>0 = EI-level exceptions enabled<br>1 = EI-level exceptions disabled<br>Set to 1 when EI or FE-level exception is acknowledged<br>Also controlled by DI (set to 1) and EI (clear to 0) instructions |
| 4 | SAT | 0 | UM | **Saturation Flag**: Cumulative saturation indicator<br>0 = Not saturated<br>1 = Saturated (set when saturation occurs, remains set)<br>Cleared only by LDSR instruction |
| 3 | CY | 0 | UM | **Carry Flag**: Indicates carry or borrow<br>0 = No carry/borrow<br>1 = Carry or borrow occurred |
| 2 | OV | 0 | UM | **Overflow Flag**: Indicates signed overflow<br>0 = No overflow<br>1 = Overflow occurred |
| 1 | S | 0 | UM | **Sign Flag**: Indicates result sign<br>0 = Result is positive or zero<br>1 = Result is negative |
| 0 | Z | 0 | UM | **Zero Flag**: Indicates zero result<br>0 = Result is not zero<br>1 = Result is zero |

**Access Modes:**
- **R**: Read-only in all modes
- **SV**: Read/write in supervisor mode only (PSW.UM=0); writes ignored in user mode
- **UM**: Read/write in both user and supervisor modes
- **Special**: Used by debug tools, do not modify in normal operation

**Reset Value:** 0x00000020 (ID=1, all other bits 0)

**User Mode Notes:**
- In user mode (UM=1), only bits 4:0 (SAT, CY, OV, S, Z) can be modified
- Attempting to execute supervisor-privileged instructions in user mode causes a PIE (Privileged Instruction Exception)
- FPU instructions require CU0=1 or a coprocessor unusable exception occurs
- LDSR writes to supervisor-only bits are ignored when UM=1 (no exception raised)

---

### Exception Registers

#### EIPC/EIPSW — EI-Level Exception Registers

| CPU | regID | selID | Name | Reset | R/W | Description |
|-----|-------|-------|------|-------|-----|-------------|
| V850+ | 0 | 0 | EIPC | Undefined | R/W | EI-level exception saved PC |
| V850+ | 1 | 0 | EIPSW | 0x00000020 | R/W | EI-level exception saved PSW |

**EIPC:** Contains the return address for EI-level exceptions. The saved value is typically
PC+4 (instruction after the faulting instruction) or PC (for interrupts).

**EIPSW:** Contains the saved PSW at time of exception. Layout matches PSW for the CPU variant.

#### FEPC/FEPSW — FE-Level Exception Registers

| CPU | regID | selID | Name | Reset | R/W | Description |
|-----|-------|-------|------|-------|-----|-------------|
| V850+ | 2 | 0 | FEPC | Undefined | R/W | FE-level (NMI/fatal) saved PC |
| V850+ | 3 | 0 | FEPSW | 0x00000020 | R/W | FE-level (NMI/fatal) saved PSW |

**FEPC/FEPSW:** Used for NMI and fatal exception handling. Layout same as EIPC/EIPSW.

#### ECR — Exception Cause Register (V850-V850E1)

| CPU | regID | selID | Name | Reset | R/W | Description |
|-----|-------|-------|------|-------|-----|-------------|
| V850-V850E1 | 4 | - | ECR | 0x00000000 | R | Exception cause register |

**ECR Register Layout:**

| Bits | Field | Reset | Description |
|------|-------|-------|-------------|
| 31:16 | FECC | 0x0000 | FE level exception code (NMI/fatal) |
| 15:0 | EICC | 0x0000 | EI level exception code (maskable interrupt/exception) |

#### EIIC/FEIC — Exception Cause Registers (V850E2M+)

| CPU | regID | selID | Name | Reset | R/W | Description |
|-----|-------|-------|------|-------|-----|-------------|
| V850E2M+ | 13 | 0 | EIIC | Undefined | R/W | EI-level exception cause code |
| V850E2M+ | 14 | 0 | FEIC | Undefined | R/W | FE-level exception cause code |

V850E2M separates the exception cause into individual registers instead of the combined ECR.

#### Exception/Interrupt Codes

| Code (hex) | Name | Handler | Description |
|------------|------|---------|-------------|
| 0010H | NMI0 | 0x00000010 | Non-maskable interrupt input 0 |
| 0020H | NMI1 | 0x00000020 | Non-maskable interrupt input 1 |
| 0030H | NMI2 | 0x00000030 | Non-maskable interrupt input 2 |
| 004nH | TRAP0n | 0x00000040 | Software TRAP0n (n = 0..F) |
| 005nH | TRAP1n | 0x00000050 | Software TRAP1n (n = 0..F) |
| 0060H | ILGOP | 0x00000060 | Illegal instruction / Debug trap / Debug break |

---

### CALLT Registers (V850ES+)

The CALLT mechanism provides efficient subroutine calls via a table lookup.

| CPU | regID | selID | Name | Reset | R/W | Description |
|-----|-------|-------|------|-------|-----|-------------|
| V850ES+ | 16 | 0 | CTPC | Undefined | R/W | CALLT saved PC (return address) |
| V850ES+ | 17 | 0 | CTPSW | Undefined | R/W | CALLT saved PSW |
| V850ES+ | 20 | 0 | CTBP | Undefined | R/W | CALLT base pointer (table base address) |

**CTPC:** Holds the return address when CALLT is executed.

**CTPSW:** Holds the saved PSW when CALLT is executed.

**CTBP:** Points to the base of the CALLT table. The CALLT instruction uses this as:
`target = mem[CTBP + (imm6 << 1)]`

---

### Debug Registers (V850E1+)

#### DBPC/DBPSW — Debug Exception Registers

| CPU | regID | selID | Name | Reset | R/W | Description |
|-----|-------|-------|------|-------|-----|-------------|
| V850E1+ | 18 | 0 | DBPC | Undefined | R/W | Debug exception saved PC |
| V850E1+ | 19 | 0 | DBPSW | Undefined | R/W | Debug exception saved PSW |

**DBPC:** Saved PC for debug trap, debug break, or single-step events.

**DBPSW:** Saved PSW for debug events. Bits 31:12, 9, 8 are reserved (0).

#### DIR — Debug Interface Register (V850E1+)

| CPU | regID | selID | Name | Reset | R/W | Description |
|-----|-------|-------|------|-------|-----|-------------|
| V850E1+ | 21 | - | DIR | 0x00000000 | R/W | Debug interface register |

**DIR Register Layout:**

| Bits | Field | R/W | Description |
|------|-------|-----|-------------|
| 31 | - | R | Reserved (0) |
| 30 | SQ1 | R/W | Sequential break mode for channels 2/3 |
| 29 | RE1 | R/W | Range break mode for channels 2/3 |
| 28 | CS1 | R/W | Channel select for channels 2/3 |
| 27:23 | - | R | Reserved (0) |
| 22 | CSL | R/W | Channel group select (0=ch0/1, 1=ch2/3) |
| 21 | BT3 | R/W | Channel 3 break flag |
| 20 | BT2 | R/W | Channel 2 break flag |
| 19:17 | - | R | Reserved (0) |
| 16 | STT | R/W | Debug trap executed flag |
| 15 | - | R | Reserved (0) |
| 14 | SQ0 | R/W | Sequential break mode for channels 0/1 |
| 13 | RE0 | R/W | Range break mode for channels 0/1 |
| 12 | CS0 | R/W | Channel select for channels 0/1 |
| 11 | - | R | Reserved (0) |
| 10 | MAE | R/W | Memory access enable |
| 9 | AEE | R/W | Alignment error enable |
| 8:6 | - | R | Reserved (0) |
| 5 | SET | R/W | Exception trap enable |
| 4 | EXT | R/W | External debug enable |
| 3 | INI | R/W | Initialize debug function |
| 2 | BT1 | R/W | Channel 1 break flag |
| 1 | BT0 | R/W | Channel 0 break flag |
| 0 | DM | R | Debug mode indicator (0=user, 1=debug) |

#### ASID — Address Space Identifier (V850E1+)

| CPU | regID | selID | Name | Reset | R/W | Description |
|-----|-------|-------|------|-------|-----|-------------|
| V850E1+ | 23 | - | ASID | Undefined | R/W | Program ID / Address space identifier |

Used for breakpoint context matching when BPC.IE=1.

#### Breakpoint Registers (V850E1/V850E2)

| CPU | regID | Name | Description |
|-----|-------|------|-------------|
| V850E1 | 22 | BPC0 | Breakpoint control register 0 |
| V850E1 | 24 | BPAV0 | Breakpoint address value 0 |
| V850E1 | 25 | BPAM0 | Breakpoint address mask 0 |
| V850E1 | 26 | BPDV0 | Breakpoint data value 0 |
| V850E1 | 27 | BPDM0 | Breakpoint data mask 0 |

V850E2 extends to 4 channels (BPC0-3, BPAV0-3, BPAM0-3, BPDV0-3, BPDM0-3).

**BPCn Register Layout:**

| Bits | Field | Description |
|------|-------|-------------|
| 31:27 | - | Reserved (must be 0) |
| 26:24 | FB2:FB0 | Break type selection |
| 23:16 | BP_ASID | Program ID to match when IE=1 |
| 15 | IE | Enable ASID comparison |
| 14:12 | - | Reserved (must be 0) |
| 11:10 | TY | Access type (00=all, 01=byte, 10=halfword, 11=word) |
| 9 | VD | Data comparator match condition |
| 8 | VA | Address comparator match condition |
| 7 | MD | Data comparator operation |
| 6:5 | - | Reserved (must be 0) |
| 4 | TE | Trigger output enable |
| 3 | BE | Break notify to CPU |
| 2 | FE | Mask event during instruction fetch |
| 1 | WE | Mask event during data write |
| 0 | RE | Mask event during data read |

**Break Type (FB2:FB0):**
- 000: Break when execution of target instruction is interrupted (initial)
- 001: Break when execution of target instruction ends
- 010: Break when target and previous instruction are interrupted
- 100: Break when target, previous, and before-last are interrupted

---

### FPU Registers (V850E2M+)

#### FPU Register Access

FPU registers can be accessed via:
- V850E2M: FPU Status Bank (BSEL=0x2000)
- RH850G3M: Basic group (selID=0, regID 6-10) or FPU group (selID=10, regID 0-5)

| CPU | regID | selID | Name | Reset | R/W | Privilege | Description |
|-----|-------|-------|------|-------|-----|-----------|-------------|
| V850E2M+ | 6 | 0 | FPSR | 0x00220000 | R/W | UM | Floating-point status register |
| V850E2M+ | 7 | 0 | FPEPC | Undefined | R/W | SV | Floating-point exception PC |
| V850E2M+ | 8 | 0 | FPST | 0x00000000 | R/W | UM | Floating-point status bits |
| V850E2M+ | 9 | 0 | FPCC | 0x00000000 | R/W | UM | Floating-point condition code |
| V850E2M+ | 10 | 0 | FPCFG | Impl-defined | R/W | SV | Floating-point configuration |
| V850E2M | 11 | 0 | FPEC | 0x00000000 | R/W | SV | FP exception control (V850E2M only) |

**Note:** FPEC is removed in RH850G3MH.

#### FPSR Register Layout

| Bits | Field | R/W | Description |
|------|-------|-----|-------------|
| 31:27 | - | R | Reserved (0) |
| 26 | FN | R/W | Flush to nearest (subnormal handling) |
| 25 | IF | R/W | Input flush enable |
| 24 | PEM | R/W | Precise exception mode |
| 23:22 | RM | R/W | Rounding mode: 00=nearest, 01=zero, 10=+∞, 11=-∞ |
| 21 | FS | R/W | Flush subnormal enable |
| 20 | XC | R/W | Cause: invalid operation (FPU exception pending) |
| 19 | XE_V | R/W | Enable: Invalid operation |
| 18 | XE_Z | R/W | Enable: Division by zero |
| 17 | XE_O | R/W | Enable: Overflow |
| 16 | XE_U | R/W | Enable: Underflow |
| 15:14 | - | R | Reserved (0) |
| 13 | XP_V | R/W | Pending: Invalid operation |
| 12 | XP_Z | R/W | Pending: Division by zero |
| 11 | XP_O | R/W | Pending: Overflow |
| 10 | XP_U | R/W | Pending: Underflow |
| 9:6 | - | R | Reserved (0) |
| 5:0 | CC | R/W | Condition code (comparison result) |

**FPU Exception Types:**

| Bit | Name | Description |
|-----|------|-------------|
| E | Unimplemented | Unimplemented operation (always traps) |
| V | Invalid | Invalid operation |
| Z | Division by zero | Division by zero |
| O | Overflow | Result overflow |
| U | Underflow | Result underflow |
| I | Inexact | Inexact result |

---

### FXU Registers (RH850G4MH+)

The FXU (Extended Floating-Point Unit) has its own status and control register separate from the FPU.

#### FXSR — FXU Status Register

| CPU | regID | selID | Name | Reset | R/W | Privilege | Description |
|-----|-------|-------|------|-------|-----|-----------|-------------|
| RH850G4MH+ | 12 | 0 | FXSR | 0x00220000 | R/W | UM | Extended floating-point status register |

**FXSR Register Layout:**

```
31   27 26 25 24 23:22 21 20:16 15:10 9:5  4:0
┌────┬──┬──┬───┬─────┬──┬─────┬─────┬────┬────┐
│ 0  │FN│IF│PEM│ RM  │FS│ XC  │  0  │ XE │ XP │
└────┴──┴──┴───┴─────┴──┴─────┴─────┴────┴────┘
```

| Bits | Field | R/W | Description |
|------|-------|-----|-------------|
| 31:27 | - | R | Reserved (0) |
| 26 | FN | R/W | Flush to nearest (subnormal handling) |
| 25 | IF | R/W | Input flush enable |
| 24 | PEM | R/W | Precise exception mode |
| 23:22 | RM | R/W | Rounding mode: 00=nearest, 01=zero, 10=+∞, 11=-∞ |
| 21 | FS | R/W | Flush subnormal enable |
| 20:16 | XC | R/W | Cause bits (E, V, Z, O, U from MSB to LSB) |
| 15:10 | - | R | Reserved (0) |
| 9:5 | XE | R/W | Enable bits (V, Z, O, U, I from MSB to LSB) |
| 4:0 | XP | R/W | Preservation (pending) bits (V, Z, O, U, I) |

**Cause Bits (XC):**
- Bit 20: E - Unimplemented operation exception
- Bit 19: V - Invalid operation exception
- Bit 18: Z - Division by zero exception
- Bit 17: O - Overflow exception
- Bit 16: U - Underflow exception

**Enable Bits (XE):**
- Bit 9: V - Invalid operation enable
- Bit 8: Z - Division by zero enable
- Bit 7: O - Overflow enable
- Bit 6: U - Underflow enable
- Bit 5: I - Inexact enable

**Preservation Bits (XP):**
- Bit 4: V - Invalid operation pending
- Bit 3: Z - Division by zero pending
- Bit 2: O - Overflow pending
- Bit 1: U - Underflow pending
- Bit 0: I - Inexact pending

**Notes:**
- FXSR is independent from FPSR; each unit maintains its own status
- Exception cause bits are OR-ed across all 4 SIMD elements
- The FXU uses the same rounding mode encoding as the FPU
- Subnormal flush behavior is controlled per-unit

#### FXU Vector Register File

The FXU has 32 dedicated 128-bit vector registers (wreg0-wreg31).

| Register | Width | Access | Description |
|----------|-------|--------|-------------|
| wreg0-wreg31 | 128-bit | PSW.CU1=1 | Vector registers for SIMD operations |

**Access Requirements:**
- PSW.CU1 must be 1 to access FXU registers
- Attempting to access with CU1=0 causes Coprocessor Unusable Exception (code 0x81)

---

### Interrupt Control Registers (RH850G3M+)

These registers are in the Interrupt group (selID=1).

| regID | selID | Name | Reset | R/W | Description |
|-------|-------|------|-------|-----|-------------|
| 0 | 1 | ISPR | 0x0000 | R/W | Interrupt status pending register |
| 1 | 1 | PMR | 0x0000 | R/W | Priority mask register |
| 2 | 1 | ICSR | 0x00000000 | R/W | Interrupt control status |
| 3 | 1 | INTCFG | 0x00000000 | R/W | Interrupt function setting |

**Note:** RH850G3MH removes FPIPR (floating-point interrupt priority register).

#### ISPR Register Layout

| Bits | Field | Description |
|------|-------|-------------|
| 31:16 | - | Reserved (0) |
| 15:0 | ISP15:ISP0 | Interrupt priority level pending (bit N = priority N pending) |

#### PMR Register Layout

| Bits | Field | Description |
|------|-------|-------------|
| 31:16 | - | Reserved (0) |
| 15:0 | PM15:PM0 | Priority mask (bit N=1 masks priority N and lower) |

---

### Memory Protection Registers (V850E2M+)

#### V850E2M Protection Registers (Bank Selection)

V850E2M uses the processor protection banks (BSEL=0x1000, 0x1010).

**Processor Protection Violation Bank (BSEL=0x1000):**

| regID | Name | Description |
|-------|------|-------------|
| 0 | VSECR | System register protection violation cause |
| 1 | VSTID | System register protection violation task identifier |
| 2 | VSADR | System register protection violation address |
| 4 | VMECR | Memory protection violation cause |
| 5 | VMTID | Memory protection violation task identifier |
| 6 | VMADR | Memory protection violation address |
| 24 | MCA | Memory protection check address |
| 25 | MCS | Memory protection check size |
| 26 | MCC | Memory protection check command |
| 27 | MCR | Memory protection check result |

**Software Paging Bank (BSEL=0x1010):**

| regID | Name | Description |
|-------|------|-------------|
| 0 | MPM | Processor protection operation mode |
| 1 | MPC | Processor protection command |
| 2 | TID | Task identifier |
| 6-7 | IPA0L/U | Instruction protection area 0 lower/upper |
| 8-9 | IPA1L/U | Instruction protection area 1 lower/upper |
| 10-11 | IPA2L/U | Instruction protection area 2 lower/upper |
| 12-13 | IPA3L/U | Instruction protection area 3 lower/upper |
| 14-15 | IPA4L/U | Instruction protection area 4 lower/upper |
| 16-17 | DPA0L/U | Data protection area 0 lower/upper |
| 18-19 | DPA1L/U | Data protection area 1 lower/upper |
| 20-21 | DPA2L/U | Data protection area 2 lower/upper |
| 22-23 | DPA3L/U | Data protection area 3 lower/upper |
| 24-25 | DPA4L/U | Data protection area 4 lower/upper |
| 26-27 | DPA5L/U | Data protection area 5 lower/upper |

#### RH850G3M MPU Registers (selID=2)

| regID | selID | Name | R/W | Description |
|-------|-------|------|-----|-------------|
| 0 | 2 | MPM | R/W | MPU operation mode |
| 1 | 2 | MPRC | R/W | MPU region control |
| 4 | 2 | MPBRGN | R | MPU base region number |
| 5 | 2 | MPTRGN | R | MPU total region number |
| 8 | 2 | MCA | R/W | Memory protection check address |
| 9 | 2 | MCS | R/W | Memory protection check size |
| 10 | 2 | MCC | R/W | Memory protection check command |
| 11 | 2 | MCR | R | Memory protection check result |
| 16 | 2 | MPLA0 | R/W | Protection area 0 lower address |
| 17 | 2 | MPUA0 | R/W | Protection area 0 upper address |
| 18 | 2 | MPAT0 | R/W | Protection area 0 attributes |

Additional MPLAn/MPUAn/MPATn registers follow for regions 1-15.

#### MPM Register Layout (V850E2M)

The MPM (Memory Protection Mode) register controls the processor protection function in V850E2M.
This register is typically set once during system initialization and not changed during program execution.

```
31                                   3  2  1  0
┌──────────────────────────────────┬──┬──┬──┐
│               0                  │SP│AU│MP│
│         (Reserved)               │S │E │E │
└──────────────────────────────────┴──┴──┴──┘
```

**Access:** System register bank (BSEL=0x1010), regID 0
**Reset Value:** 0x00000000

| Bits | Field | Reset | R/W | Description |
|------|-------|-------|-----|-------------|
| 31:3 | - | 0 | R | Reserved for future expansion (must be 0) |
| 2 | SPS | 0 | R/W | **Stack Inspection Enable**<br>Enables or disables stack inspection for memory protection<br>0 = Stack inspection disabled<br>1 = Stack inspection enabled<br>When SPS=1, instructions that perform sp-indirect access are limited to the area specified by DPA0L/DPA0U registers<br><br>**Effect on protection registers:**<br>When SPS=0: IPAnL.S=1, DPA0L.S=1, DPAmL.S=1<br>When SPS=1: IPAnL.S=0, DPA0L.S=1, DPAmL.S=0<br>(n=0 to 4, m=1 to 5)<br>**Note:** DPA0L/DPA0U area is always accessible in sp-indirect mode |
| 1 | AUE | 0 | R/W | **Auto-Update on Exception**<br>Controls automatic clearing of PSW protection bits when exception occurs<br>0 = No automatic update (PSW.PP, NPV, DMP, IMP unchanged on exception)<br>1 = Automatic update (PSW.PP, NPV, DMP, IMP cleared to 0 on exception)<br><br>**Exceptions:**<br>- MDP, MIP, PPI, TSI exceptions: Always clear protection bits to 0<br>- DB-level exceptions: Always clear protection bits to 0<br>- Other exceptions: Follow AUE setting<br><br>**Note:** When AUE=0, PSW.NPV bit is fixed to 0 and cannot be changed |
| 0 | MPE | 0 | R/W | **Memory Protection Enable**<br>Enables or disables the processor protection function<br>0 = Processor protection disabled<br>&nbsp;&nbsp;&nbsp;&nbsp;• PSW.PP bit is fixed to 0<br>&nbsp;&nbsp;&nbsp;&nbsp;• Peripheral protection limits only special peripheral violations<br>&nbsp;&nbsp;&nbsp;&nbsp;• PPI exception does not occur<br>1 = Processor protection enabled<br>&nbsp;&nbsp;&nbsp;&nbsp;• Full memory and peripheral protection active<br>&nbsp;&nbsp;&nbsp;&nbsp;• PSW protection bits (PP, NPV, DMP, IMP) are operational |

**Usage Notes:**
- Bits 31:3 must always be set to 0
- MPM register is usually configured once during system initialization
- Protection bits become operational only when MPE=1
- Stack inspection (SPS) provides additional protection for stack operations
- Auto-update (AUE) simplifies exception handler context management by automatically clearing protection bits

---

### Cache Control Registers (RH850G3M+)

These registers are in the Cache group (selID=5).

| regID | selID | Name | Reset | R/W | Description |
|-------|-------|------|-------|-----|-------------|
| 0 | 5 | ICCTRL | Impl-defined | R/W | Instruction cache control |
| 8 | 5 | ICTAGL | Undefined | R/W | Instruction cache tag (low) |
| 9 | 5 | ICTAGH | Undefined | R/W | Instruction cache tag (high) |
| 10 | 5 | ICDATL | Undefined | R/W | Instruction cache data (low) |
| 11 | 5 | ICDATH | Undefined | R/W | Instruction cache data (high) |
| 24 | 5 | ICERR | 0x00000000 | R/W | Instruction cache error |
| 26 | 5 | ICCFG | Impl-defined | R | Instruction cache configuration |

#### ICCTRL Register Layout

| Bits | Field | R/W | Description |
|------|-------|-----|-------------|
| 31:9 | - | R | Reserved (0) |
| 8 | ICHCLR | R/W | Instruction cache clear (write 1 to clear) |
| 7:2 | - | R | Reserved (0) |
| 1 | ICHEMK | R/W | Instruction cache error mask |
| 0 | ICHEN | R/W | Instruction cache enable |

---

### SYSCALL Registers (V850E2M+)

| regID | selID | Name | Reset | R/W | Description |
|-------|-------|------|-------|-----|-------------|
| 11 | 0 | SCCFG | Impl-defined | R/W | SYSCALL operation setting |
| 12 | 0 | SCBP | Undefined | R/W | SYSCALL base pointer |

**SCCFG:** Configures SYSCALL operation (size of table entries, etc.)

**SCBP:** Points to the base of the SYSCALL handler table.

---

### System Configuration Registers (RH850G3M+)

| regID | selID | Name | Reset | R/W | Privilege | Description |
|-------|-------|------|-------|-----|-----------|-------------|
| 2 | 1 | RBASE | Impl-defined | R | SV | Reset vector base address |
| 3 | 1 | EBASE | Impl-defined | R/W | SV | Exception handler base address |
| 4 | 1 | INTBP | Undefined | R/W | SV | Interrupt handler base pointer |
| 5 | 1 | MCTL | 0x00000000 | R/W | SV | CPU control register |
| 6 | 1 | PID | Impl-defined | R | - | Processor ID |
| 25 | 1 | HTCFG0 | Impl-defined | R | - | Hardware thread configuration |
| 30 | 1 | MEA | Undefined | R | SV | Memory error address |
| 31 | 1 | MEI | 0x00000000 | R | SV | Memory error information |

---

### Working Registers (V850E2M+)

Working registers are always accessible regardless of bank selection.

| regID | Name | Reset | R/W | Description |
|-------|------|-------|-----|-------------|
| 28 | EIWR | Undefined | R/W | EI-level working register |
| 29 | FEWR | Undefined | R/W | FE-level working register |
| 30 | DBWR | Undefined | R/W | DB-level working register |
| 31 | BSEL | 0x00000000 | R/W | Register bank selection (V850E2M only) |

**Usage:** Working registers provide scratch space for exception handlers to save/restore
context without disturbing general-purpose registers.

---

### User Banks (V850E2M)

V850E2M provides user-accessible banks for limited system register access.

#### User 0 Bank (BSEL=0xFF00)

| regID | Name | Description |
|-------|------|-------------|
| 5 | PSW | Program status word |
| 8 | FPST | Floating-point operation status |
| 9 | FPCC | Floating-point comparison result |
| 10 | FPCFG | Floating-point function configuration |
| 16 | CTPC | CALLT status-save register |
| 17 | CTPSW | CALLT PSW |
| 20 | CTBP | CALLT base pointer |
| 28 | EIWR | EI-level exception working register |
| 29 | FEWR | FE-level exception working register |
| 30 | DBWR | DB-level exception working register |
| 31 | BSEL | Register bank selection |

#### User Compatible Bank (BSEL=0xFFFF)

Provides backward compatibility with older V850 variants.

| regID | Name | Description |
|-------|------|-------------|
| 0 | EIPC | EI-level exception PC |
| 1 | EIPSW | EI-level exception PSW |
| 2 | FEPC | FE-level exception PC |
| 3 | FEPSW | FE-level exception PSW |
| 4 | ECR | Exception cause |
| 5 | PSW | Program status word |
| 8 | FPST | Floating-point operation status |
| 9 | FPCC | Floating-point comparison result |
| 10 | FPCFG | Floating-point function configuration |
| 13 | EIIC | EI-level exception cause |
| 14 | FEIC | FE-level exception cause |
| 16 | CTPC | CALLT status-save register |
| 17 | CTPSW | CALLT PSW |
| 20 | CTBP | CALLT base pointer |
| 28 | EIWR | EI-level exception working register |
| 29 | FEWR | FE-level exception working register |
| 30 | DBWR | DB-level exception working register |
| 31 | BSEL | Register bank selection |

---

### Privilege Levels Summary (RH850G3M+)

| Symbol | Mode | Description |
|--------|------|-------------|
| SV | Supervisor | PSW.UM=0, full system register access |
| UM | User | PSW.UM=1, restricted access |
| UM* | User (partial) | PSW.UM=1, limited bit access (e.g., PSW flags only) |
| - | Any | No privilege check |

**Privilege Violation:** Accessing SV-privileged registers in user mode causes a PIE
(Privileged Instruction Exception).

---

## Opcode Encoding Maps

This section provides detailed opcode encoding maps for V850 instructions.

### Primary Opcode Map (Bits 10:5)

16-bit instructions use bits [10:5] as the primary opcode field. The encoding is organized by bits [10:7] (row) and bits [6:5] (column):

| Bits 10:7 | 00 (bits 6:5) | 01 (bits 6:5) | 10 (bits 6:5) | 11 (bits 6:5) | Format |
|-----------|---------------|---------------|---------------|---------------|--------|
| 0000 | MOV/NOP | NOT | DIVH | JMP | I |
| 0001 | SATSUBR/ZXB | SATSUB/SXB | SATADD/ZXH | MULH/SXH | I |
| 0010 | OR | XOR | AND | TST | I |
| 0011 | SUBR | SUB | ADD | CMP | I |
| 0100 | MOV imm5 / CALLT | SATADD imm5 | ADD imm5 | CMP imm5 | II |
| 0101 | SHR imm5 | SAR imm5 | SHL imm5 | MULH imm5 | II |
| 0110 | - | SLD.B | - | - | IV |
| 0111 | - | SST.B | - | - | IV |
| 1000 | - | SLD.H | - | - | IV |
| 1001 | - | SST.H | - | - | IV |
| 1010 | - | SLD.W / SST.W | - | - | IV |
| 1011 | - | Bcond | - | - | III |
| 1100 | ADDI | MOVEA | MOVHI | SATSUBI | VI |
| 1101 | ORI | XORI | ANDI | MULHI | VI |
| 1110 | LD.B | LD.H / LD.W | ST.B | ST.H / ST.W | V/VII/VIII |
| 1111 | - | JARL | Bit manip | Extended | V/VIII/IX/X |

**Notes:**
- When `reg2=0` for certain Format I instructions, alternative encodings apply:
  - `DIVH` with `reg2=0` → `SWITCH`
  - `SATSUBR` with `reg2=0` → `ZXB`
  - `SATSUB` with `reg2=0` → `SXB`
  - `SATADD` with `reg2=0` → `ZXH`
  - `MULH` with `reg2=0` → `SXH`
- `MOV imm5` with `reg2=0` → `CALLT`

### Short Load/Store Sub-Opcode (Format IV)

For opcodes 0110-1010 (Format IV), bit 0 distinguishes operations:

| Bits 10:7 | Bit 0 = 0 | Bit 0 = 1 |
|-----------|-----------|-----------|
| 0110 | - | SLD.B |
| 0111 | - | SST.B |
| 1000 | - | SLD.H |
| 1001 | - | SST.H |
| 1010 | SLD.W | SST.W |

### Load/Store Sub-Opcode (Format VII)

For opcode 1110 (bits 10:5), bits [6:5] and bit 16 determine the operation:

| Bits 6:5 | Bit 16 = 0 | Bit 16 = 1 |
|----------|------------|------------|
| 00 | LD.B | - |
| 01 | LD.H | LD.W |
| 10 | ST.B | - |
| 11 | ST.H | ST.W |

### Bit Manipulation Sub-Opcode (Format VIII)

For bit manipulation instructions (opcode 1111, bits 6:5 = 10), bits 15:14 determine the operation:

| Bit 15 | Bit 14 = 0 | Bit 14 = 1 |
|--------|------------|------------|
| 0 | SET1 | NOT1 |
| 1 | CLR1 | TST1 |

### Extended Instruction Sub-Opcode (Format IX/X)

For extended instructions (opcode = 111111), bits 26:21 in the second word determine the operation:

| Bits 26:23 | Bits 22:21 = 00 | Bits 22:21 = 01 | Bits 22:21 = 10 | Bits 22:21 = 11 |
|------------|-----------------|-----------------|-----------------|-----------------|
| 0000 | SETF | LDSR | STSR | Undefined |
| 0001 | SHR reg | SAR reg | SHL reg | Undefined |
| 0010 | TRAP | HALT | RETI | Extension 2 |
| 0011-1111 | Illegal instruction | Illegal instruction | Illegal instruction | Illegal instruction |

### Extension 2 Sub-Opcode (Format X)

For Extension 2 instructions (bits 26:21 = 001011), bits 15:13 determine the operation:

| Bit 15 | Bits 14:13 = 00 | Bits 14:13 = 01 | Bits 14:13 = 10 | Bits 14:13 = 11 |
|--------|-----------------|-----------------|-----------------|-----------------|
| 0 | DI | - | - | Undefined |
| 1 | EI | - | - | Undefined |

---

## Opcode Summary

### Format I (16-bit, reg-reg)

**Encoding:** bits[15:11] = reg2, bits[10:5] = opcode, bits[4:0] = reg1

| Opcode (bits 10:5) | Instruction | Special Encoding | Arch |
|--------------------|-------------|------------------|------|
| 000000 | MOV reg1, reg2 | NOP when reg1=0, reg2=0 | V850 |
| 000001 | NOT reg1, reg2 | | V850 |
| 000010 | DIVH reg1, reg2 | SWITCH reg1 when reg2=0 (V850E1) | V850/V850E1 |
| 000011 | JMP [reg1] | DBTRAP when reg1=0, reg2≠0 (V850E1)<br>SLD.BU disp4[ep], reg2 when reg1[4]=0 (V850E1)<br>SLD.HU disp5[ep], reg2 when reg1[4]=1 (V850E1) | V850/V850E1 |
| 000100 | SATSUBR reg1, reg2 | ZXB reg1 when reg2=0 (V850E1) | V850/V850E1 |
| 000101 | SATSUB reg1, reg2 | SXB reg1 when reg2=0 (V850E1) | V850/V850E1 |
| 000110 | SATADD reg1, reg2 | ZXH reg1 when reg2=0 (V850E1) | V850/V850E1 |
| 000111 | MULH reg1, reg2 | SXH reg1 when reg2=0 (V850E1) | V850/V850E1 |
| 001000 | OR reg1, reg2 | | V850 |
| 001001 | XOR reg1, reg2 | | V850 |
| 001010 | AND reg1, reg2 | | V850 |
| 001011 | TST reg1, reg2 | | V850 |
| 001100 | SUBR reg1, reg2 | | V850 |
| 001101 | SUB reg1, reg2 | | V850 |
| 001110 | ADD reg1, reg2 | | V850 |
| 001111 | CMP reg1, reg2 | | V850 |

**V850E2M Synchronization Instructions (Format I-like, 16-bit fixed encodings):**

| Full Encoding | Instruction | Arch |
|--------------|-------------|------|
| 0x0000 | NOP (MOV r0, r0) | V850 |
| 0x001D | SYNCE | V850E2M |
| 0x001E | SYNCM | V850E2M |
| 0x001F | SYNCP | V850E2M |
| 0x0040 + bits[8:5] | RIE / FETRAP vector4 | V850E2M |

### Format II (16-bit, imm-reg)

**Encoding:** bits[15:11] = reg2, bits[10:5] = opcode, bits[4:0] = imm5

| Opcode (bits 10:5) | Instruction | Special Encoding | Arch |
|--------------------|-------------|------------------|------|
| 010000 | MOV imm5, reg2 | CALLT imm6 when reg2=0 (V850E1, bits[5:0]=imm6) | V850/V850E1 |
| 010001 | SATADD imm5, reg2 | | V850 |
| 010010 | ADD imm5, reg2 | | V850 |
| 010011 | CMP imm5, reg2 | | V850 |
| 010100 | SHR imm5, reg2 | | V850 |
| 010101 | SAR imm5, reg2 | | V850 |
| 010110 | SHL imm5, reg2 | | V850 |
| 010111 | MULH imm5, reg2 | | V850 |

### Format III (16-bit, conditional branch)

**Encoding:** bits[15:11,6:4] = disp9, bits[10:7] = 1011, bits[3:0] = condition

| Condition (bits 3:0) | Mnemonic(s) | Condition Test | Arch |
|---------------------|-------------|----------------|------|
| 0000 | BV | OV = 1 | V850 |
| 0001 | BC / BL | CY = 1 | V850 |
| 0010 | BZ / BE | Z = 1 | V850 |
| 0011 | BNH | (CY or Z) = 1 | V850 |
| 0100 | BN | S = 1 | V850 |
| 0101 | BR | Always (unconditional) | V850 |
| 0110 | BLT | (S xor OV) = 1 | V850 |
| 0111 | BLE | ((S xor OV) or Z) = 1 | V850 |
| 1000 | BNV | OV = 0 | V850 |
| 1001 | BNC / BNL | CY = 0 | V850 |
| 1010 | BNZ / BNE | Z = 0 | V850 |
| 1011 | BH | (CY or Z) = 0 | V850 |
| 1100 | BP | S = 0 | V850 |
| 1101 | BSA | SAT = 1 | V850 |
| 1110 | BGE | (S xor OV) = 0 | V850 |
| 1111 | BGT | ((S xor OV) or Z) = 0 | V850 |

### Format IV (16-bit, short load/store EP-relative)

**Encoding:** bits[15:11] = reg2, bits[10:7] = opcode, bits[6:0] = displacement

| Opcode (bits 10:7) | Bit 0 | Instruction | Displacement | Arch |
|--------------------|-------|-------------|--------------|------|
| 0110 | 1 | SLD.B disp7[ep], reg2 | disp7 (byte) | V850 |
| 0111 | 1 | SST.B reg2, disp7[ep] | disp7 (byte) | V850 |
| 1000 | 1 | SLD.H disp8[ep], reg2 | disp8 (halfword, bit 0 ignored) | V850 |
| 1001 | 1 | SST.H reg2, disp8[ep] | disp8 (halfword, bit 0 ignored) | V850 |
| 1010 | 0 | SLD.W disp8[ep], reg2 | disp8 (word, bits 1:0 ignored) | V850 |
| 1010 | 1 | SST.W reg2, disp8[ep] | disp8 (word, bits 1:0 ignored) | V850 |

### Format V (32-bit, jump with 22-bit displacement)

**Encoding:** bits[15:11] = reg2, bits[10:6] = 11110, bits[5:0,31:17,16] = disp22

| Opcode (bits 10:6) | reg2 Value | Instruction | Arch |
|--------------------|------------|-------------|------|
| 11110 | r0 | JR disp22 | V850 |
| 11110 | ≠ r0 | JARL disp22, reg2 | V850 |

### Format VI (32-bit, 3-operand with 16-bit immediate)

**Encoding:** bits[15:11] = reg2, bits[10:5] = opcode, bits[4:0] = reg1, bits[31:16] = imm16

| Opcode (bits 10:5) | Instruction | Arch |
|--------------------|-------------|------|
| 110000 | ADDI imm16, reg1, reg2 | V850 |
| 110001 | MOVEA imm16, reg1, reg2 | V850 |
| 110010 | MOVHI imm16, reg1, reg2 | V850 |
| 110011 | SATSUBI imm16, reg1, reg2 | V850 |
| 110100 | ORI imm16, reg1, reg2 | V850 |
| 110101 | XORI imm16, reg1, reg2 | V850 |
| 110110 | ANDI imm16, reg1, reg2 | V850 |
| 110111 | MULHI imm16, reg1, reg2 | V850 |

### Format VII (32-bit, load/store with 16-bit displacement)

**Encoding:** bits[15:11] = reg2, bits[10:5] = opcode, bits[4:0] = reg1, bits[31:17,16] = disp16

| Opcode (bits 10:5) | Bits 6:5 | Bit 16 | Instruction | Arch |
|--------------------|----------|--------|-------------|------|
| 111000 | 00 | - | LD.B disp16[reg1], reg2 | V850 |
| 111001 | 01 | 0 | LD.H disp16[reg1], reg2 | V850 |
| 111001 | 01 | 1 | LD.W disp16[reg1], reg2 | V850 |
| 111010 | 10 | - | ST.B reg2, disp16[reg1] | V850 |
| 111011 | 11 | 0 | ST.H reg2, disp16[reg1] | V850 |
| 111011 | 11 | 1 | ST.W reg2, disp16[reg1] | V850 |
| 111100 | - | - | LD.BU disp16[reg1], reg2 | V850E1 |
| 111111 | - | 1 | LD.HU disp16[reg1], reg2 | V850E1 |

### Format VIII (32-bit, bit manipulation)

**Encoding:** bits[15:14] = sub-op, bits[13:11] = bit#, bits[10:5] = 111110, bits[4:0] = reg1, bits[31:16] = disp16

| Sub-op (bits 15:14) | Instruction | Arch |
|---------------------|-------------|------|
| 00 | SET1 bit#3, disp16[reg1] | V850 |
| 01 | NOT1 bit#3, disp16[reg1] | V850 |
| 10 | CLR1 bit#3, disp16[reg1] | V850 |
| 11 | TST1 bit#3, disp16[reg1] | V850 |

### Format XIII (32-bit, PREPARE/DISPOSE)

**Encoding varies - see individual instruction descriptions in main table**

| Instruction | Encoding Pattern | Arch |
|-------------|------------------|------|
| PREPARE list12, imm5 | bits[10:6] = 11110, bits[5:1] = imm5, bit 0 + bits[31:21] = list12 | V850E1 |
| PREPARE list12, imm5, sp | Similar with additional sp setup | V850E1 |
| DISPOSE imm5, list12 | Uses MOVHI opcode space with special encoding | V850E1 |
| DISPOSE imm5, list12, [reg1] | Dispose with tail call | V850E1 |

### Format XIV (48-bit, load/store with 23-bit displacement)

**Encoding:** 3 halfwords, bits[10:5] = opcode, bits[47:17] = disp23

| Opcode (bits 10:5) | Bits 20:16 | Bit 11 | Instruction | Arch |
|--------------------|------------|--------|-------------|------|
| 111110 | 00101 | 0 | LD.B disp23[reg1], reg3 | V850E2M |
| 111110 | 00111 | 0 | LD.H disp23[reg1], reg3 | V850E2M |
| 111110 | 01001 | 0 | LD.W disp23[reg1], reg3 | V850E2M |
| 111110 | 11101 | 0 | ST.B reg3, disp23[reg1] | V850E2M |
| 111101 | 01101 | 1 | ST.H reg3, disp23[reg1] | V850E2M |
| 111110 | 01111 | 0 | ST.W reg3, disp23[reg1] | V850E2M |
| 111101 | 00101 | 1 | LD.BU disp23[reg1], reg3 | V850E2M |
| 111101 | 00111 | 1 | LD.HU disp23[reg1], reg3 | V850E2M |

### Extended Instructions (opcode=111111)

Extended instructions use opcode 111111 with sub-opcodes in the second word. The complete mapping is provided below.

**Extended Format IX - System and Bit Operations**

| Bits 26:23 | Bits 22:21 = 00 | Bits 22:21 = 01 | Bits 22:21 = 10 | Bits 22:21 = 11 | Arch |
|------------|-----------------|-----------------|-----------------|-----------------|------|
| 0000 | SETF | LDSR | STSR | - | V850 |
| 0001 | SHR reg | SAR reg | SHL reg | SET1r/NOT1r/CLR1r/TST1r | V850/V850E1 |
| 0010 | TRAP | HALT | RETI/CTRET/DBRET | DI/EI | V850/V850E1 |
| 0011 | - | - | PREPARE | DISPOSE | V850E1 |
| 0100 | SASF (V850E1) | MUL family | DIV family | DIVH_3 | V850E1 |
| 0101 | DIVHU family | - | DIV family (V850E1) | DIVQ (V850E2M) | V850E1/V850E2M |
| 0110 | CMOV imm | BSW/BSH/HSW/SCH0/SCH1 | CMOV reg | - | V850E1/V850E2 |
| 0111 | SBF (V850E2) | ADF (V850E2) | MAC (V850E2) | MACU (V850E2) | V850E2 |
| 1000 | FPU Instructions (V850E2M) | V850E2M+FPU |

**Extended Format XI - V850E1+ 3-Operand Instructions**

| Sub-opcode (bits 26:21) | Instruction | Operands | Arch |
|------------------------|-------------|----------|------|
| 000010 11010 | SHR | reg1, reg2, reg3 | V850E2 |
| 000100 11010 | SAR | reg1, reg2, reg3 | V850E2 |
| 000110 11010 | SHL | reg1, reg2, reg3 | V850E2 |
| 000111 01110 | CAXI | [reg1], reg2, reg3 | V850E2M |
| 010001 01010 | MUL | reg1, reg2, reg3 | V850E1 |
| 010001 10010 | MULi | imm9, reg2, reg3 | V850E1 |
| 010001 11010 | MULU | reg1, reg2, reg3 | V850E1 |
| 010010 11010 | MULUi | imm9, reg2, reg3 | V850E1 |
| 010100 01010 | DIVH | reg1, reg2, reg3 | V850E1 |
| 010100 11010 | DIV | reg1, reg2, reg3 | V850E1 |
| 010101 01010 | DIVHU | reg1, reg2, reg3 | V850E1 |
| 010110 11010 | DIVU | reg1, reg2, reg3 | V850E1 |
| 010111 11100 | DIVQ | reg1, reg2, reg3 | V850E2M |
| 010111 11110 | DIVQU | reg1, reg2, reg3 | V850E2M |
| 011000 11010 | CMOVi | cccc, imm5, reg2, reg3 | V850E1 |
| 011001 00010 | CMOVr | cccc, reg1, reg2, reg3 | V850E1 |
| 011010 11010 | BSW/BSH/HSW/HSH | reg2, reg3 | V850E1/V850E2 |
| 011010 01000 | SCH0R | reg2, reg3 | V850E2 |
| 011010 01010 | SCH1R | reg2, reg3 | V850E2 |
| 011010 01100 | SCH0L | reg2, reg3 | V850E2 |
| 011010 01110 | SCH1L | reg2, reg3 | V850E2 |
| 011100 xxxxx | SBF | cccc, reg1, reg2, reg3 | V850E2 |
| 011100 11010 | SATSUB | reg1, reg2, reg3 | V850E2 |
| 011101 xxxxx | ADF | cccc, reg1, reg2, reg3 | V850E2 |
| 011101 11010 | SATADD | reg1, reg2, reg3 | V850E2 |
| 011110 xxxxx | MAC | reg1, reg2, reg3, reg4 | V850E2 |
| 011111 xxxxx | MACU | reg1, reg2, reg3, reg4 | V850E2 |

**FPU Instructions (V850E2M+FPU) - bits[10:5]=111111**

All FPU instructions use the extended opcode 111111 (bits 10:5). Format FI encoding:
- bit 4: Precision (0=Double, 1=Single)
- bits [26:21]: Sub-opcode (6 bits)
- bits [20:16], [15:11]: Additional operand/encoding fields

#### FPU Arithmetic Operations

| Mnemonic | Operands | Precision | Bits[26:21] | Bits[20:16] | Notes |
|----------|----------|-----------|-------------|-------------|-------|
| ADDF.D | reg1, reg2, reg3 | Double (bit4=0) | 010000 | reg1[4:0] | Floating-point add |
| ADDF.S | reg1, reg2, reg3 | Single (bit4=1) | 010000 | reg1[4:0] | Floating-point add |
| SUBF.D | reg1, reg2, reg3 | Double (bit4=0) | 010001 | reg1[4:0] | Floating-point subtract |
| SUBF.S | reg1, reg2, reg3 | Single (bit4=1) | 010001 | reg1[4:0] | Floating-point subtract |
| MULF.D | reg1, reg2, reg3 | Double (bit4=0) | 010010 | reg1[4:0] | Floating-point multiply |
| MULF.S | reg1, reg2, reg3 | Single (bit4=1) | 010010 | reg1[4:0] | Floating-point multiply |
| DIVF.D | reg1, reg2, reg3 | Double (bit4=0) | 010011 | reg1[4:0] | Floating-point divide |
| DIVF.S | reg1, reg2, reg3 | Single (bit4=1) | 010011 | reg1[4:0] | Floating-point divide |
| MAXF.D | reg1, reg2, reg3 | Double (bit4=0) | 011110 | reg1[4:0] | Floating-point maximum |
| MAXF.S | reg1, reg2, reg3 | Single (bit4=1) | 011110 | reg1[4:0] | Floating-point maximum |
| MINF.D | reg1, reg2, reg3 | Double (bit4=0) | 011111 | reg1[4:0] | Floating-point minimum |
| MINF.S | reg1, reg2, reg3 | Single (bit4=1) | 011111 | reg1[4:0] | Floating-point minimum |

#### FPU Unary Operations

| Mnemonic | Operands | Precision | Bits[26:21] | Bits[20:16] | Notes |
|----------|----------|-----------|-------------|-------------|-------|
| ABSF.D | reg2, reg3 | Double (bit4=0) | 001000 | 00000 | Floating-point absolute value |
| ABSF.S | reg2, reg3 | Single (bit4=1) | 001000 | reg2[0] | Floating-point absolute value |
| NEGF.D | reg2, reg3 | Double (bit4=0) | 001000 | 00001 | Floating-point negate |
| NEGF.S | reg2, reg3 | Single (bit4=1) | 001000 | reg2[0] | Floating-point negate |
| SQRTF.D | reg2, reg3 | Double (bit4=0) | 001001 | 00000 | Floating-point square root |
| SQRTF.S | reg2, reg3 | Single (bit4=1) | 001001 | reg2[0] | Floating-point square root |
| RECIPF.D | reg2, reg3 | Double (bit4=0) | 001001 | 00001 | Floating-point reciprocal |
| RECIPF.S | reg2, reg3 | Single (bit4=1) | 001001 | reg2[0] | Floating-point reciprocal |
| RSQRTF.D | reg2, reg3 | Double (bit4=0) | 001001 | 00010 | Floating-point reciprocal sqrt |
| RSQRTF.S | reg2, reg3 | Single (bit4=1) | 001001 | reg2[0] | Floating-point reciprocal sqrt |

#### FPU Type Conversion

| Mnemonic | Operands | Precision | Bits[26:21] | Bits[20:16] | Notes |
|----------|----------|-----------|-------------|-------------|-------|
| CVTF.DL | reg2, reg3 | Double→Long | 010100 | 00000 | Convert double to signed 64-bit |
| CVTF.DS | reg2, reg3 | Double→Single | 010100 | 00011 | Convert double to single |
| CVTF.DUL | reg2, reg3 | Double→ULong | 010100 | 10000 | Convert double to unsigned 64-bit |
| CVTF.DUW | reg2, reg3 | Double→UWord | 010100 | reg2[0] | Convert double to unsigned 32-bit |
| CVTF.DW | reg2, reg3 | Double→Word | 010100 | reg2[0] | Convert double to signed 32-bit |
| CVTF.LD | reg2, reg3 | Long→Double | 010100 | 00001 | Convert signed 64-bit to double |
| CVTF.LS | reg2, reg3 | Long→Single | 010100 | reg2[0] | Convert signed 64-bit to single |
| CVTF.SD | reg2, reg3 | Single→Double | 010100 | 00010 | Convert single to double |
| CVTF.SL | reg2, reg3 | Single→Long | 010100 | 00000 | Convert single to signed 64-bit |
| CVTF.SUL | reg2, reg3 | Single→ULong | 010100 | 10000 | Convert single to unsigned 64-bit |
| CVTF.SUW | reg2, reg3 | Single→UWord | 010100 | reg2[0] | Convert single to unsigned 32-bit |
| CVTF.SW | reg2, reg3 | Single→Word | 010100 | reg2[0] | Convert single to signed 32-bit |
| CVTF.ULD | reg2, reg3 | ULong→Double | 010100 | 10001 | Convert unsigned 64-bit to double |
| CVTF.ULS | reg2, reg3 | ULong→Single | 010100 | reg2[0] | Convert unsigned 64-bit to single |
| CVTF.UWD | reg2, reg3 | UWord→Double | 010100 | 10000 | Convert unsigned 32-bit to double |
| CVTF.UWS | reg2, reg3 | UWord→Single | 010100 | reg2[0] | Convert unsigned 32-bit to single |
| CVTF.WD | reg2, reg3 | Word→Double | 010100 | 00000 | Convert signed 32-bit to double |
| CVTF.WS | reg2, reg3 | Word→Single | 010100 | reg2[0] | Convert signed 32-bit to single |

#### FPU Rounding Operations

| Mnemonic | Operands | Precision | Bits[26:21] | Bits[20:16] | Notes |
|----------|----------|-----------|-------------|-------------|-------|
| CEILF.DL | reg2, reg3 | Double→Long | 010100 | 00010 | Round toward +infinity to signed 64-bit |
| CEILF.DUL | reg2, reg3 | Double→ULong | 010100 | 10010 | Round toward +infinity to unsigned 64-bit |
| CEILF.DUW | reg2, reg3 | Double→UWord | 010100 | reg2[0] | Round toward +infinity to unsigned 32-bit |
| CEILF.DW | reg2, reg3 | Double→Word | 010100 | reg2[0] | Round toward +infinity to signed 32-bit |
| CEILF.SL | reg2, reg3 | Single→Long | 010100 | 00010 | Round toward +infinity to signed 64-bit |
| CEILF.SUL | reg2, reg3 | Single→ULong | 010100 | 10010 | Round toward +infinity to unsigned 64-bit |
| CEILF.SUW | reg2, reg3 | Single→UWord | 010100 | reg2[0] | Round toward +infinity to unsigned 32-bit |
| CEILF.SW | reg2, reg3 | Single→Word | 010100 | reg2[0] | Round toward +infinity to signed 32-bit |
| FLOORF.DL | reg2, reg3 | Double→Long | 010100 | 00011 | Round toward -infinity to signed 64-bit |
| FLOORF.DUL | reg2, reg3 | Double→ULong | 010100 | 10011 | Round toward -infinity to unsigned 64-bit |
| FLOORF.DUW | reg2, reg3 | Double→UWord | 010100 | reg2[0] | Round toward -infinity to unsigned 32-bit |
| FLOORF.DW | reg2, reg3 | Double→Word | 010100 | reg2[0] | Round toward -infinity to signed 32-bit |
| FLOORF.SL | reg2, reg3 | Single→Long | 010100 | 00011 | Round toward -infinity to signed 64-bit |
| FLOORF.SUL | reg2, reg3 | Single→ULong | 010100 | 10011 | Round toward -infinity to unsigned 64-bit |
| FLOORF.SUW | reg2, reg3 | Single→UWord | 010100 | reg2[0] | Round toward -infinity to unsigned 32-bit |
| FLOORF.SW | reg2, reg3 | Single→Word | 010100 | reg2[0] | Round toward -infinity to signed 32-bit |
| TRNCF.DL | reg2, reg3 | Double→Long | 010100 | 00001 | Round toward zero to signed 64-bit |
| TRNCF.DUL | reg2, reg3 | Double→ULong | 010100 | 10001 | Round toward zero to unsigned 64-bit |
| TRNCF.DUW | reg2, reg3 | Double→UWord | 010100 | reg2[0] | Round toward zero to unsigned 32-bit |
| TRNCF.DW | reg2, reg3 | Double→Word | 010100 | reg2[0] | Round toward zero to signed 32-bit |
| TRNCF.SL | reg2, reg3 | Single→Long | 010100 | 00001 | Round toward zero to signed 64-bit |
| TRNCF.SUL | reg2, reg3 | Single→ULong | 010100 | 10001 | Round toward zero to unsigned 64-bit |
| TRNCF.SUW | reg2, reg3 | Single→UWord | 010100 | reg2[0] | Round toward zero to unsigned 32-bit |
| TRNCF.SW | reg2, reg3 | Single→Word | 010100 | reg2[0] | Round toward zero to signed 32-bit |

#### FPU Comparison and Conditional Operations

| Mnemonic | Operands | Precision | Bits[26:21] | Bits[20:16] | Notes |
|----------|----------|-----------|-------------|-------------|-------|
| CMPF.D | cond, reg1, reg2, cc#3 | Double | 011000 | 0FFFF (cond) | Compare double and set cc |
| CMPF.S | cond, reg1, reg2, cc#3 | Single | 011000 | 0FFFF (cond) | Compare single and set cc |
| CMOVF.D | cc, reg1, reg2, reg3 | Double | 010000 | reg1[4:0] | Conditional move double |
| CMOVF.S | cc, reg1, reg2, reg3 | Single | 010000 | reg1[4:0] | Conditional move single |
| TRFSR | cc#3 | - | 010000 | 00000 | Transfer PSW.S to FPU cc |

#### FPU Fused Multiply-Add Operations (Single Precision Only)

| Mnemonic | Operands | Precision | Bits[26:21] | Bits[20:16] | Notes |
|----------|----------|-----------|-------------|-------------|-------|
| MADDF.S | reg1, reg2, reg3, reg4 | Single | 101W00 | reg1[4:0] | reg4 = reg1*reg2 + reg3 |
| MSUBF.S | reg1, reg2, reg3, reg4 | Single | 101W01 | reg1[4:0] | reg4 = reg1*reg2 - reg3 |
| NMADDF.S | reg1, reg2, reg3, reg4 | Single | 101W10 | reg1[4:0] | reg4 = -(reg1*reg2 + reg3) |
| NMSUBF.S | reg1, reg2, reg3, reg4 | Single | 101W11 | reg1[4:0] | reg4 = -(reg1*reg2 - reg3) |

Note: In fused multiply-add instructions, 'W' bits encode reg4 register field.

---

## Pipeline Architecture and Scheduling

### Pipeline Characteristics by CPU Variant

| CPU Variant | Pipeline Stages | Issue Width | Branch Prediction | FPU |
|-------------|-----------------|-------------|-------------------|-----|
| V850 | 5 (IF-ID-EX-MEM-WB) | 1 (single) | No | No |
| V850ES | 5 (IF-ID-EX-DF-WB) | 1 (single) | No | No |
| V850E1 | 5 (IF-ID-EX-DF-WB) | 1 (single) | No | No |
| V850E2 | 7 (IF-DP-ID-EX-AT-DF-WB) | 2 (dual) | No | Optional |
| V850E2M | 7 (IF-DP-ID-EX-AT-DF-WB) | 2 (dual) | No | Yes |
| RH850G3M | 7 | 2 (dual) | Yes | Yes |
| RH850G3MH | 7+ (OoO features) | 2 (dual) | Yes | Yes |
| RH850G4MH | 7+ (OoO features) | 2 (dual) | Yes | Yes + FXU |
| RH850G4MH2 | 7+ (OoO features) | 2 (dual) | Yes | Yes + FXU |

### Pipeline Stage Descriptions

**V850/V850ES/V850E1 (5-stage):**
```
IF → ID → EX → MEM → WB
│     │     │      │     └─ Write-Back: Register file update
│     │     │      └────── Memory: Data memory access
│     │     └───────────── Execute: ALU/Branch/Multiply
│     └─────────────────── Decode: Instruction decode, register read
└───────────────────────── Fetch: Instruction fetch from memory
```

**V850E2/V850E2M (7-stage dual-issue):**
```
IF → DP → ID → EX → AT → DF → WB
│     │     │     │     │     │     └─ Write-Back
│     │     │     │     │     └────── Data Fetch (memory read)
│     │     │     │     └──────────── Address Translation
│     │     │     └────────────────── Execute (ALU/MUL)
│     │     └──────────────────────── Decode (dual-issue decision)
│     └────────────────────────────── Pre-Decode (instruction alignment)
└──────────────────────────────────── Fetch
```

### Dual-Issue Pipeline Resources (V850E2+)

| Resource | Pipeline | Instructions |
|----------|----------|--------------|
| MEM | Lpipe | LD.*, ST.*, SLD.*, SST.*, Bit manipulation |
| MUL | Lpipe | MUL, MULU, MULH, MULHI, MAC, MACU |
| ALU | Lpipe or Rpipe | ADD, SUB, CMP, MOV, AND, OR, XOR, etc. |
| BSFT | Rpipe | SAR, SHL, SHR, BSH, BSW, HSW, CMOV, SETF, SCH* |
| DIV | Rpipe | DIV, DIVU, DIVH, DIVHU, DIVQ, DIVQU |
| FPU | FPU pipe | All floating-point operations |
| FXU | FXU pipe | All extended FP vector operations (G4MH) |

### Timing Notation

| Symbol | Meaning | Example |
|--------|---------|---------|
| issue (i) | Cycles before next instruction can start | `1-1-2` → issue=1 |
| repeat (r) | Cycles when same instruction executes consecutively | `1-1-2` → repeat=1 |
| latency (l) | Cycles before result available to dependent instruction | `1-1-2` → latency=2 |

Format: `issue-repeat-latency` (e.g., `1-1-2` means issue=1, repeat=1, latency=2)

### Key Instruction Latencies by Category

#### Integer ALU (1-1-1 on all variants)
- ADD, SUB, CMP, MOV, AND, OR, XOR, NOT, TST
- SATADD, SATSUB, SASF, SETF
- Shift: SHR, SAR, SHL, ROTL
- Data manipulation: BSH, BSW, HSH, HSW, SXB, SXH, ZXB, ZXH

#### Load Instructions

| Instruction | V850/ES/E1 | V850E2/E2M | RH850G3M+ |
|-------------|------------|------------|-----------|
| LD.B/H/W | 1-1-2 | 1-1-3 | 1-1-3 |
| SLD.B/H/W | 1-1-2 | 1-1-3 | 1-1-3 |
| LD.DW | N/A | N/A | 1-1-3 |

#### Store Instructions (1-1-1 on all variants)
- ST.B, ST.H, ST.W, ST.DW
- SST.B, SST.H, SST.W

#### Multiply Instructions

| Instruction | V850 | V850ES/E1 | V850E2+ |
|-------------|------|-----------|---------|
| MULH/MULHI | 1-1-2 | 1-1-2 | 1-1-3 |
| MUL/MULU | N/A | 1-4-5 | 1-1-3 |
| MAC/MACU | N/A | N/A | 1-1-3 (E2), 2-2-4 (G3MH+) |

#### Divide Instructions

| Instruction | V850 | V850ES/E1 | V850E2M | RH850G3M | RH850G3MH+ |
|-------------|------|-----------|---------|----------|------------|
| DIVH | 36-36-36 | 35-35-35 | 36-36-36 | 19-19-19 | 1-19-19 |
| DIV/DIVU | N/A | 35-35-35 | 36-36-36 | 19-19-19 | 1-19-19 |
| DIVQ/DIVQU | N/A | N/A | N+5/N+4 | N+3 | N+3 |

Note: N = (dividend bits) - (divisor bits), range 0-16.

#### Branch Instructions

| Instruction | V850 | V850ES/E1 | V850E2M | RH850 (pred hit) | RH850 (miss) |
|-------------|------|-----------|---------|------------------|--------------|
| Bcond (taken) | 3-3-3 | 2-2-2 | 4-4-4 | 1-1-1 | 4-6 |
| Bcond (not taken) | 1-1-1 | 1-1-1 | 1-1-1 | 1-1-1 | 4-6 |
| JMP [reg1] | 3-3-3 | 3-3-3 | 4-4-4 | 2-6 | 2-6 |
| JR/JARL | 3-3-3 | 2-2-2 | 4-4-4 | 2-3 | 2-3 |

#### FPU Instructions (V850E2M+)

| Instruction | V850E2M | RH850G3MH/G4MH | Notes |
|-------------|---------|----------------|-------|
| ADDF.S/SUBF.S | 4 | 4 | Single precision add/sub |
| ADDF.D/SUBF.D | 4 | 4 | Double precision add/sub |
| MULF.S | 4 | 4 | Single precision multiply |
| MULF.D | 5 | 7 | Double precision multiply |
| DIVF.S | ~35 | 11 | Single precision divide |
| DIVF.D | ~64 | 19 | Double precision divide |
| SQRTF.S | ~30 | 17 | Single precision sqrt |
| SQRTF.D | ~60 | 33 | Double precision sqrt |
| FMAF.S | 4 | 4 | Single precision FMA |
| CMPF.S/D | 1 | 1 | Compare |

#### FXU Instructions (RH850G4MH+)

| Instruction | Latency | Notes |
|-------------|---------|-------|
| ABSF.S4/NEGF.S4 | 4 | Unary vector ops |
| ADDF.S4/SUBF.S4/MULF.S4 | 4 | Binary vector ops |
| DIVF.S4 | ~11 | Vector divide |
| SQRTF.S4 | ~17 | Vector sqrt |
| FMAF.S4 | 4 | Vector FMA |
| LDV.W/DW/QW | 3 | Vector load |
| STV.W/DW/QW | 1 | Vector store |

### Special Instruction Timings

| Instruction | V850 | V850ES/E1 | V850E2M | RH850G3M+ |
|-------------|------|-----------|---------|-----------|
| TRAP | 4-4-4 | 3-3-3 | 7-7-7 | 8-8-8 |
| RETI | 4-4-4 | 3-3-3 | 7-7-7 | 8-8-8 |
| CALLT | N/A | 4-4-4 | 10-10-10 | 17-17-17 |
| SYSCALL | N/A | N/A | 10-10-10 | 17-17-17 |
| PREPARE | N/A | n+1 | n+2 | N+1 to N+3 |
| DISPOSE | N/A | n+1 | n+2 | N+1 to N+8 |

Note: n/N = number of registers in list.

---

## Hazard Management

### Data Hazards

#### Load-Use Hazard

When a load instruction result is used by the immediately following instruction:

| CPU Variant | Load Latency | Required Gap | Hardware Behavior |
|-------------|--------------|--------------|-------------------|
| V850/ES/E1 | 2 cycles | 1 instruction | Hardware interlock stall |
| V850E2+ | 3 cycles | 2 instructions | Hardware interlock stall |

**Example (V850):**
```assembly
LD.W [r4], r6       ; Cycle 1-2
ADD  r6, r7         ; Stalls 1 cycle if immediate
```

**Optimization:** Place independent instructions between load and use.

#### Multiply-Use Hazard

| CPU Variant | Multiply Latency | Required Gap |
|-------------|------------------|--------------|
| V850/ES/E1 | 2 cycles | 1 instruction |
| V850E2+ | 3 cycles | 2 instructions |

#### Divide Hazard

Division is a long-latency blocking operation:

| CPU Variant | Latency | Blocking Behavior |
|-------------|---------|-------------------|
| V850 | 36 cycles | Blocks pipeline entirely |
| V850ES/E1 | 34-35 cycles | Interruptible, restarts if interrupted |
| V850E2M | 35-36 cycles | Interruptible |
| RH850G3M | 19 cycles | Blocking |
| RH850G3MH+ | 19 cycles | Non-blocking issue (result still 19 cycles) |

### Control Hazards

#### Branch Prediction (RH850G3M+)

| Prediction | Penalty |
|------------|---------|
| Correct | 1 cycle |
| Mispredicted | 4-6 cycles |

#### Branch Target Alignment

If a 4-byte instruction is at a non-word-aligned address, an extra fetch cycle is required:
- **Penalty:** 1 cycle for misaligned branch target
- **Avoidance:** Align 4-byte instructions to word boundaries

### System Register Hazards

#### LDSR/STSR Hazards

| Register | Read-after-Write Latency | Required Synchronization |
|----------|-------------------------|--------------------------|
| EIPC/FEPC | 3 cycles | 2 instruction gap |
| PSW.UM | Variable | SYNCI before instruction fetch |
| FPSR/FPU regs | Variable | SYNCP before FPU operation |
| MPU registers | Variable | SYNCP before Load/Store |

### Synchronization Instructions (V850E2M+)

| Instruction | Purpose | When Required |
|-------------|---------|---------------|
| SYNCP | Pipeline synchronization | Before using updated system register values |
| SYNCE | Exception synchronization | Before changing FPSR.PEM |
| SYNCI | Instruction synchronization | After PSW.UM change, self-modifying code |
| SYNCM | Memory synchronization | Memory ordering across CPUs |

### Dual-Issue Restrictions (V850E2+)

These instructions are **single-issue only**:

| Instruction | Reason |
|-------------|--------|
| MOV imm32, reg1 | 6-byte instruction |
| MAC/MACU | Uses MUL and extra register ports |
| ADF/SBF | Conditional arithmetic |
| SATADD/SATSUB (3-op) | Extended saturation |
| PREPARE/DISPOSE | Multi-cycle memory access |
| CAXI | Atomic operation |
| LDL.W/STC.W | Atomic operation |
| TRAP/SYSCALL | Exception |
| EIRET/FERET/RETI | Return from exception |

**Dual-issue constraints:**
1. Same-pipe instructions cannot dual-issue
2. 6-byte instructions cannot dual-issue
3. Register dependency prevents dual-issue
4. Memory ordering must be preserved

### RH850G4MH-Specific Hazards

#### MPU Entry Instructions

| Instruction | Latency | Notes |
|-------------|---------|-------|
| LDM.MP | N+8 | N = entries × 1.5 (rounded). Interruptible. |
| STM.MP | N+2 | N = entries × 1.5 (rounded). Interruptible. |

**Required:** Execute SYNCP after MPU register updates before Load/Store.

#### Virtualization Instructions (RH850G4MH2)

| Instruction | Latency | Notes |
|-------------|---------|-------|
| HVTRAP | 8-8-8 | Guest→Host transition |
| LDM.GSR | 26-26-26 | Load guest system registers |
| STM.GSR | 19-19-19 | Store guest system registers |

### Hazard Summary Table

| Hazard Type | Penalty | Resolution |
|-------------|---------|------------|
| Load-use (V850) | 1 stall | 1 instruction gap |
| Load-use (V850E2+) | 2 stalls | 2 instruction gap |
| Multiply-use (V850) | 1 stall | 1 instruction gap |
| Multiply-use (V850E2+) | 2 stalls | 2 instruction gap |
| LDSR EIPC/FEPC | 2 stalls | 2 instruction gap |
| Divide (V850) | 36 cycles | Blocking |
| Divide (RH850G3MH+) | Issue=1, Latency=19 | Non-blocking issue |
| Branch taken (V850) | 3 cycles | - |
| Branch predicted hit (RH850) | 1 cycle | - |
| Branch mispredicted (RH850) | 4-6 cycles | - |
| Alignment | 1 cycle | Align branch targets |
| System register update | Variable | SYNCP/SYNCE/SYNCI |

---

## LLVM Scheduling Model

### Implemented Models

| Model | Target CPUs | Issue Width | Key Features |
|-------|-------------|-------------|--------------|
| V850Model | V850, V850ES, V850E1 | 1 | 5-stage pipeline, single-issue |
| V850E2MModel | V850E2, V850E2M | 2 | 7-stage dual-issue, FPU support |

### Resource Classes

**V850Model Resources:**
- `V850UnitALU` - Integer ALU
- `V850UnitMem` - Load/Store unit
- `V850UnitBranch` - Branch unit
- `V850UnitMul` - Integer multiply
- `V850UnitDiv` - Integer divide (blocking)

**V850E2MModel Resources:**
- `V850E2MLpipe` - L-pipe (load/store, multiply, MAC)
- `V850E2MRpipe` - R-pipe (ALU, shift, bit search)
- `V850E2MAnyPipe` - Either pipe (most ALU ops)
- `V850E2MUnitBranch` - Branch unit
- `V850E2MUnitDiv` - Integer divide (blocking)
- `V850E2MUnitFPALU` - FP ALU (add, sub, mul, cmp, cvt)
- `V850E2MUnitFPDiv` - FP divide/sqrt (not pipelined)

### Write Resources

| Write Type | V850 Latency | V850E2M Latency | Notes |
|------------|--------------|-----------------|-------|
| WriteIALU | 1 | 1 | Integer ALU |
| WriteIMul | 2 | 3 | Integer multiply |
| WriteIDiv | 36 | 36 | Integer divide |
| WriteLDB/H/W | 2 | 3 | Load operations |
| WriteSTB/H/W | 1 | 1 | Store operations |
| WriteBranch | 3 | 4 | Branch taken |
| WriteFAdd32 | N/A | 4 | FP single add/sub |
| WriteFMul32 | N/A | 4 | FP single multiply |
| WriteFDiv32 | N/A | 35 | FP single divide |

### Missing Scheduling Models

| Target | Status | Required |
|--------|--------|----------|
| RH850G3M | Not implemented | Branch prediction, non-blocking divide issue |
| RH850G3MH | Not implemented | Advanced OoO features |
| RH850G4MH | Not implemented | FXU vector unit, MPU instructions |
| RH850G4MH2 | Not implemented | Virtualization instructions |

---

## References

- NEC V850 Family User's Manual (U10243EJ7V0UM)
- NEC V850ES Architecture User's Manual (U15943EJ4V0UM)
- NEC V850E1 Architecture User's Manual (U14559EJ3V1UM)
- Renesas V850E2 Architecture User's Manual (U17135EJ1V1UM)
- Renesas V850E2M User's Manual: Architecture (R01US0001EJ0100)
- Renesas RH850G3M User's Manual: Software (R01US0123EJ0140)
- Renesas RH850G3MH User's Manual: Software (R01US0143EJ0130)

---

## Architecture Evolution Summary

| Generation | Key Additions |
|------------|---------------|
| V850 | Base 74 instructions, 32 GPRs, 5 system registers (EIPC, EIPSW, FEPC, FEPSW, ECR, PSW) |
| V850ES | Extended ISA (80 instructions): CALLT, PREPARE/DISPOSE, BSH/BSW/HSW, CMOV, 3-op MUL/DIV, SXB/SXH/ZXB/ZXH, LD.BU/HU, SWITCH, DBTRAP/DBRET |
| V850E1 | V850ES ISA + extended system registers: CTPC, CTPSW, DBPC, DBPSW, CTBP, DIR, BPC, ASID, BPAV, BPAM, BPDV, BPDM |
| V850E2 | ADF/SBF, MAC/MACU, HSH, SCH0L/R SCH1L/R, 3-op SAR/SHL/SHR/SATADD/SATSUB, 48-bit JR/JARL/JMP, SLD.BU/SLD.HU |
| V850E2M | FPU, CAXI, SYSCALL, EIRET/FERET/FETRAP, SYNCE/SYNCM/SYNCP, RIE, DIVQ/DIVQU, disp23 load/store, memory protection, register banking |
| V850E3/E3V5 | Enhanced FPU, additional system features |
| RH850G3M | User/supervisor modes (PSW.UM), LDL.W/STC.W atomics, CLL, BINS, ROTL, LD.DW/ST.DW, LOOP, PUSHSP/POPSP, Bcond disp17, JARL [reg1] reg3, CACHE, PREF, SNOOZE, SYNCI, selID-based system registers, MPU, instruction cache |
| RH850G3MH | RH850G3M + performance enhancements, simplified FPU exceptions (FPINT replaces FPP/FPI), FPIPR register removed |
