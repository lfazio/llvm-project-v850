# V850 Intrinsics Implementation Plan

This document catalogs all V850 intrinsics, their implementation status, and provides guidance for adding new intrinsics.

## Legend

- **[IMPLEMENTED]** - Fully implemented (LLVM intrinsic + Clang builtin + CodeGen)
- **[PARTIAL]** - Partially implemented (missing some components)
- **[TODO]** - Planned but not yet implemented
- **[FUTURE]** - Desirable for future implementation

---

## 1. Implemented Intrinsics Summary

| Category | Implemented | TODO | Total |
|----------|-------------|------|-------|
| Interrupt Control | 2 | 0 | 2 |
| System Register Access | 38 | 7+ | 45+ |
| FPU System Registers | 12 | 0 | 12 |
| Memory Barriers | 4 | 0 | 4 |
| Bit Manipulation | 4 | 0 | 4 |
| Byte/Halfword Swap | 3 | 0 | 3 |
| Saturating Arithmetic | 5 | 1 | 6 |
| Multiply-Accumulate | 2 | 0 | 2 |
| Bit Search | 4 | 0 | 4 |
| Atomic Operations | 4 | 0 | 4 |
| Special Instructions | 6 | 0 | 6 |
| Cache Control | 0 | 2 | 2 |
| CLIP Saturation (G4MH) | 0 | 4 | 4 |
| MPU Load/Store (G4MH2) | 0 | 2 | 2 |
| Virtualization (G4MH2) | 0 | 3 | 3 |
| FXU Vector (G4MH) | 0 | 59 | 59 |
| **Total** | **84** | **78+** | **162+** |

### G3M-Specific Instructions (All Implemented)

The following RH850G3M-specific instructions and builtins are now implemented:

| Instruction | Builtin | Description |
|-------------|---------|-------------|
| SYNCI | `__builtin_v850_synci()` | Synchronize instruction pipeline |
| SNOOZE | `__builtin_v850_snooze()` | Enter low-power snooze state |
| CLL | `__builtin_v850_cll()` | Clear load link state |
| LDL.W | `__builtin_v850_ldl_w(ptr)` | Load linked word |
| STC.W | `__builtin_v850_stc_w(ptr, val)` | Store conditional word |

Additional G3M instructions (without builtins):
- ROTL (immediate and register forms)
- PUSHSP / POPSP (stack register push/pop)
- LOOP (hardware loop)
- CACHE / PREF (cache operations)
- BINS (bitfield insert)
- LD.DW / ST.DW (64-bit load/store)

---

## 2. Interrupt Control Intrinsics

### 2.1 DI - Disable Interrupts [IMPLEMENTED]

**Architecture:** V850 (Base)

```c
void __builtin_v850_di(void);
```

**Description:** Sets PSW.ID = 1, disabling EI-level interrupts.

**LLVM Intrinsic:** `@llvm.v850.di()`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:26`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:92-95`
- `llvm/include/llvm/IR/IntrinsicsV850.td:153`

---

### 2.2 EI - Enable Interrupts [IMPLEMENTED]

**Architecture:** V850 (Base)

```c
void __builtin_v850_ei(void);
```

**Description:** Clears PSW.ID = 0, enabling EI-level interrupts.

**LLVM Intrinsic:** `@llvm.v850.ei()`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:30`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:96-99`
- `llvm/include/llvm/IR/IntrinsicsV850.td:157`

---

## 3. System Register Access Intrinsics

### 3.1 Generic LDSR/STSR [IMPLEMENTED]

**Architecture:** V850 (Base)

```c
void __builtin_v850_ldsr(unsigned int value, unsigned int regID);
unsigned int __builtin_v850_stsr(unsigned int regID);
```

**Description:** Generic read/write of system registers by ID.

**LLVM Intrinsics:**
- `@llvm.v850.ldsr(i32 %value, i32 %regID)`
- `@llvm.v850.stsr(i32 %regID)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:34-38`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:105-115`
- `llvm/include/llvm/IR/IntrinsicsV850.td:172-179`

---

### 3.2 Named System Register Intrinsics (Base V850) [IMPLEMENTED]

| Register | regID | Read Builtin | Write Builtin | Description |
|----------|-------|--------------|---------------|-------------|
| EIPC | 0 | `__builtin_v850_read_eipc()` | `__builtin_v850_write_eipc(v)` | Exception saved PC |
| EIPSW | 1 | `__builtin_v850_read_eipsw()` | `__builtin_v850_write_eipsw(v)` | Exception saved PSW |
| FEPC | 2 | `__builtin_v850_read_fepc()` | `__builtin_v850_write_fepc(v)` | Fatal error saved PC |
| FEPSW | 3 | `__builtin_v850_read_fepsw()` | `__builtin_v850_write_fepsw(v)` | Fatal error saved PSW |
| ECR | 4 | `__builtin_v850_read_ecr()` | (read-only) | Exception cause |
| PSW | 5 | `__builtin_v850_read_psw()` | `__builtin_v850_write_psw(v)` | Program status word |

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:56-87`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:121-180`

---

### 3.3 Named System Register Intrinsics (V850E1+) [IMPLEMENTED]

| Register | regID | Read Builtin | Write Builtin | Description |
|----------|-------|--------------|---------------|-------------|
| CTPC | 16 | `__builtin_v850_read_ctpc()` | `__builtin_v850_write_ctpc(v)` | CALLT saved PC |
| CTPSW | 17 | `__builtin_v850_read_ctpsw()` | `__builtin_v850_write_ctpsw(v)` | CALLT saved PSW |
| CTBP | 20 | `__builtin_v850_read_ctbp()` | `__builtin_v850_write_ctbp(v)` | CALLT base pointer |

**Feature Required:** `v850e1`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:148-164`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:186-217`

---

### 3.4 Named Debug System Register Intrinsics (V850E1+) [IMPLEMENTED]

| Register | regID | Read Builtin | Write Builtin | Description |
|----------|-------|--------------|---------------|-------------|
| DBPC | 18 | `__builtin_v850_read_dbpc()` | `__builtin_v850_write_dbpc(v)` | Debug saved PC |
| DBPSW | 19 | `__builtin_v850_read_dbpsw()` | `__builtin_v850_write_dbpsw(v)` | Debug saved PSW |
| DIR | 21 | `__builtin_v850_read_dir()` | (read-only) | Debug interface register |
| BPC | 22 | `__builtin_v850_read_bpc()` | `__builtin_v850_write_bpc(v)` | Breakpoint control |
| ASID | 23 | `__builtin_v850_read_asid()` | `__builtin_v850_write_asid(v)` | Address space ID |
| BPAV | 24 | `__builtin_v850_read_bpav()` | `__builtin_v850_write_bpav(v)` | Breakpoint address value |
| BPAM | 25 | `__builtin_v850_read_bpam()` | `__builtin_v850_write_bpam(v)` | Breakpoint address mask |
| BPDV | 26 | `__builtin_v850_read_bpdv()` | `__builtin_v850_write_bpdv(v)` | Breakpoint data value |
| BPDM | 27 | `__builtin_v850_read_bpdm()` | `__builtin_v850_write_bpdm(v)` | Breakpoint data mask |

**Feature Required:** `v850e1`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:166-223`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:219-315`

---

### 3.5 Named Exception Cause Register Intrinsics (V850E2+) [IMPLEMENTED]

| Register | regID | Read Builtin | Write Builtin | Description |
|----------|-------|--------------|---------------|-------------|
| EIIC | 13 | `__builtin_v850_read_eiic()` | `__builtin_v850_write_eiic(v)` | EI exception cause |
| FEIC | 14 | `__builtin_v850_read_feic()` | `__builtin_v850_write_feic(v)` | FE exception cause |

**Feature Required:** `v850e2`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:225-241`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:317-341`

---

### 3.6 Named System Register Intrinsics (V850E2M+) [IMPLEMENTED]

| Register | regID | Read Builtin | Write Builtin | Description |
|----------|-------|--------------|---------------|-------------|
| EIWR | 28 | `__builtin_v850_read_eiwr()` | `__builtin_v850_write_eiwr(v)` | EI working register |
| FEWR | 29 | `__builtin_v850_read_fewr()` | `__builtin_v850_write_fewr(v)` | FE working register |
| DBWR | 30 | `__builtin_v850_read_dbwr()` | `__builtin_v850_write_dbwr(v)` | Debug working register |
| BSEL | 31 | `__builtin_v850_read_bsel()` | `__builtin_v850_write_bsel(v)` | Bank selection |

**Feature Required:** `v850e2m`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:262-291`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:343-389`

---

### 3.7 RH850G3M+ System Registers [TODO]

| Register | regID | Description | Priority |
|----------|-------|-------------|----------|
| SCBP | 22 | Syscall base pointer | Medium |
| HTCFG0 | 24 | Thread configuration | Low |
| MEA | 26 | Memory error address | Medium |
| MEI | 27 | Memory error info | Medium |
| ISPR | 28 | Interrupt priority | Medium |
| INTCFG | 29 | Interrupt configuration | Low |
| PLMR | 30 | Priority level mask | Low |

**Feature Required:** `rh850g3m`

---

### 3.7 RH850G4MH Virtualization Registers [TODO]

| Register | Bank | Description | Priority |
|----------|------|-------------|----------|
| HVCFG | 2 | Hypervisor config | Future |
| HVTYPE | 2 | Hypervisor type | Future |
| GMEIPC | 1 | Guest EI saved PC | Future |
| GMEIPSW | 1 | Guest EI saved PSW | Future |
| GMFEPC | 1 | Guest FE saved PC | Future |
| GMFEPSW | 1 | Guest FE saved PSW | Future |

**Feature Required:** `rh850g4mh2`

---

## 4. FPU System Register Intrinsics

### 4.1 FPU Status Registers (V850E2M+) [IMPLEMENTED]

| Register | regID | Read Builtin | Write Builtin | Description |
|----------|-------|--------------|---------------|-------------|
| FPSR | 6 | `__builtin_v850_read_fpsr()` | `__builtin_v850_write_fpsr(v)` | FPU status |
| FPEPC | 7 | `__builtin_v850_read_fpepc()` | `__builtin_v850_write_fpepc(v)` | FPU exception PC |
| FPST | 8 | `__builtin_v850_read_fpst()` | `__builtin_v850_write_fpst(v)` | FPU sticky flags |
| FPCC | 9 | `__builtin_v850_read_fpcc()` | `__builtin_v850_write_fpcc(v)` | FPU compare flags |
| FPCFG | 10 | `__builtin_v850_read_fpcfg()` | `__builtin_v850_write_fpcfg(v)` | FPU configuration |
| FPEC | 11 | `__builtin_v850_read_fpec()` | `__builtin_v850_write_fpec(v)` | FPU exception cause |

**Feature Required:** `v850fpu`

**Implementation Notes:**
- These intrinsics automatically handle BSEL bank switching
- BSEL must be set to 0x2000 before accessing FPU registers

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:211-246`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:321-374`
- `llvm/include/llvm/IR/IntrinsicsV850.td:69-117`

---

## 5. Memory Barrier Intrinsics

### 5.1 SYNCP - Pipeline Synchronization [IMPLEMENTED]

**Architecture:** V850E2M+

```c
void __builtin_v850_syncp(void);
```

**Description:** Full pipeline synchronization. Equivalent to `__sync_synchronize()`.

**LLVM Intrinsic:** `@llvm.v850.syncp()`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:168`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:75-78`
- `llvm/include/llvm/IR/IntrinsicsV850.td:131`

---

### 5.2 SYNCM - Memory Synchronization [IMPLEMENTED]

**Architecture:** V850E2M+

```c
void __builtin_v850_syncm(void);
```

**Description:** Memory synchronization fence.

**LLVM Intrinsic:** `@llvm.v850.syncm()`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:172`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:79-82`
- `llvm/include/llvm/IR/IntrinsicsV850.td:136`

---

### 5.3 SYNCE - Exception Synchronization [IMPLEMENTED]

**Architecture:** V850E2M+

```c
void __builtin_v850_synce(void);
```

**Description:** Synchronize pending exceptions.

**LLVM Intrinsic:** `@llvm.v850.synce()`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:176`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:83-86`
- `llvm/include/llvm/IR/IntrinsicsV850.td:141`

---

### 5.4 SYNCI - Instruction Synchronization [IMPLEMENTED]

**Architecture:** RH850G3M+

```c
void __builtin_v850_synci(void);
```

**Description:** Synchronize memory for instruction fetches. Required after self-modifying code.

**LLVM Intrinsic:** `@llvm.v850.synci()`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:452`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp`
- `llvm/include/llvm/IR/IntrinsicsV850.td`
- `llvm/lib/Target/V850/V850InstrInfo.td` (SYNCI instruction)

---

## 6. Bit Manipulation Intrinsics

### 6.1 SET1 - Atomic Set Bit [IMPLEMENTED]

**Architecture:** V850E1+

```c
void __builtin_v850_set1(void *addr, unsigned int bit);
```

**Description:** Atomically sets bit `bit` at memory location `addr`.

**LLVM Intrinsic:** `@llvm.v850.set1(ptr %addr, i32 %bit)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:98`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:31-36`
- `llvm/include/llvm/IR/IntrinsicsV850.td:23-24`

---

### 6.2 CLR1 - Atomic Clear Bit [IMPLEMENTED]

**Architecture:** V850E1+

```c
void __builtin_v850_clr1(void *addr, unsigned int bit);
```

**Description:** Atomically clears bit `bit` at memory location `addr`.

**LLVM Intrinsic:** `@llvm.v850.clr1(ptr %addr, i32 %bit)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:102`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:37-42`
- `llvm/include/llvm/IR/IntrinsicsV850.td:28-29`

---

### 6.3 NOT1 - Atomic Toggle Bit [IMPLEMENTED]

**Architecture:** V850E1+

```c
void __builtin_v850_not1(void *addr, unsigned int bit);
```

**Description:** Atomically toggles bit `bit` at memory location `addr`.

**LLVM Intrinsic:** `@llvm.v850.not1(ptr %addr, i32 %bit)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:106`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:43-48`
- `llvm/include/llvm/IR/IntrinsicsV850.td:33-34`

---

### 6.4 TST1 - Test Bit [IMPLEMENTED]

**Architecture:** V850E1+

```c
int __builtin_v850_tst1(void *addr, unsigned int bit);
```

**Description:** Tests bit `bit` at memory location `addr`. Returns 1 if bit was 0, 0 otherwise.

**LLVM Intrinsic:** `@llvm.v850.tst1(ptr %addr, i32 %bit)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:111`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:49-54`
- `llvm/include/llvm/IR/IntrinsicsV850.td:38-40`

---

## 7. Byte/Halfword Swap Intrinsics

### 7.1 HSW - Halfword Swap Word [IMPLEMENTED]

**Architecture:** V850E1+

```c
unsigned int __builtin_v850_hsw(unsigned int x);
```

**Description:** Swaps upper and lower halfwords: `0xAABBCCDD → 0xCCDDAABB`

**LLVM Intrinsic:** `@llvm.v850.hsw(i32 %x)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:116`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:60-64`
- `llvm/include/llvm/IR/IntrinsicsV850.td:49-50`

---

### 7.2 BSH - Byte Swap Halfword [IMPLEMENTED]

**Architecture:** V850E1+

```c
unsigned int __builtin_v850_bsh(unsigned int x);
```

**Description:** Swaps bytes in each halfword: `0xAABBCCDD → 0xBBAADDCC`

**LLVM Intrinsic:** `@llvm.v850.bsh(i32 %x)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:121`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:65-69`
- `llvm/include/llvm/IR/IntrinsicsV850.td:54-55`

---

### 7.3 HSH - Halfword Swap Halfword [IMPLEMENTED]

**Architecture:** V850E2+

```c
unsigned int __builtin_v850_hsh(unsigned int x);
```

**Description:** Sign-extends lower halfword to 32 bits, then swaps bytes within each halfword.

**LLVM Intrinsic:** `@llvm.v850.hsh(i32 %x)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:259`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:70-74`
- `llvm/include/llvm/IR/IntrinsicsV850.td:57-62`

---

## 8. Saturating Arithmetic Intrinsics

### 8.1 SATADD - Saturating Add [IMPLEMENTED]

**Architecture:** V850 (Base)

```c
int __builtin_v850_satadd(int a, int b);
```

**Description:** Signed saturating addition. Result saturates to INT_MAX/INT_MIN on overflow.

**Implementation:** Uses LLVM's `@llvm.sadd.sat.i32`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:42`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:260-266`

---

### 8.2 SATSUB - Saturating Subtract [IMPLEMENTED]

**Architecture:** V850 (Base)

```c
int __builtin_v850_satsub(int a, int b);
```

**Description:** Signed saturating subtraction. Returns `saturate(b - a)`.

**Implementation:** Uses LLVM's `@llvm.ssub.sat.i32`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:46`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:267-273`

---

### 8.3 SATSUBR - Saturating Subtract Reverse [IMPLEMENTED]

**Architecture:** V850 (Base)

```c
int __builtin_v850_satsubr(int a, int b);
```

**Description:** Signed saturating subtraction with reversed operand order. Returns `saturate(a - b)`.

**Note:** The difference between SATSUB and SATSUBR:
- `satsub(a, b)` computes `saturate(b - a)`
- `satsubr(a, b)` computes `saturate(a - b)`

**LLVM Intrinsic:** `@llvm.v850.satsubr(i32 %a, i32 %b)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:53`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:274-280`
- `llvm/include/llvm/IR/IntrinsicsV850.td:71-72`
- `llvm/lib/Target/V850/V850InstrInfo.td:407-409`

---

### 8.5 SATADD3 - 3-operand Saturating Add [IMPLEMENTED]

**Architecture:** V850E2+

```c
int __builtin_v850_satadd3(int a, int b);
```

**Description:** 3-operand saturating addition. Returns `saturate(a + b)` with result in separate register.

**LLVM Intrinsic:** `@llvm.v850.satadd3(i32 %a, i32 %b)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:271`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:421-427`
- `llvm/include/llvm/IR/IntrinsicsV850.td:74-79`

---

### 8.6 SATSUB3 - 3-operand Saturating Subtract [IMPLEMENTED]

**Architecture:** V850E2+

```c
int __builtin_v850_satsub3(int a, int b);
```

**Description:** 3-operand saturating subtraction. Returns `saturate(a - b)` with result in separate register.

**LLVM Intrinsic:** `@llvm.v850.satsub3(i32 %a, i32 %b)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:276`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:428-434`
- `llvm/include/llvm/IR/IntrinsicsV850.td:81-86`

---

### 8.7 SATSUBI - Saturating Subtract Immediate [TODO]

**Architecture:** V850 (Base)

```c
int __builtin_v850_satsubi(int a, int imm16);
```

**Priority:** Low (compiler can use immediate form)

---

## 9. Multiply-Accumulate Intrinsics

### 9.1 MAC - Signed Multiply-Accumulate [IMPLEMENTED]

**Architecture:** V850E1+

```c
long long __builtin_v850_mac(int a, int b, long long acc);
```

**Description:** Returns `acc + (a * b)` as 64-bit signed result.

**LLVM Intrinsic:** `@llvm.v850.mac(i32 %a, i32 %b, i32 %acc_hi, i32 %acc_lo)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:126`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:279-296`
- `llvm/include/llvm/IR/IntrinsicsV850.td:192-194`

---

### 9.2 MACU - Unsigned Multiply-Accumulate [IMPLEMENTED]

**Architecture:** V850E1+

```c
unsigned long long __builtin_v850_macu(unsigned int a, unsigned int b,
                                       unsigned long long acc);
```

**Description:** Returns `acc + (a * b)` as 64-bit unsigned result.

**LLVM Intrinsic:** `@llvm.v850.macu(i32 %a, i32 %b, i32 %acc_hi, i32 %acc_lo)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:132`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:297-315`
- `llvm/include/llvm/IR/IntrinsicsV850.td:199-201`

---

## 10. Bit Search Intrinsics [IMPLEMENTED]

### 10.1 SCH1L - Search for Leftmost 1 (CLZ) [IMPLEMENTED]

**Architecture:** V850E2+

```c
unsigned int __builtin_v850_sch1l(unsigned int x);
```

**Description:** Returns position of leftmost 1 bit (31 = MSB, 0 = LSB), or 32 if x == 0.

**LLVM Intrinsic:** `@llvm.v850.sch1l(i32 %x)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:235`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:421-425`
- `llvm/include/llvm/IR/IntrinsicsV850.td:84-85`

---

### 10.2 SCH1R - Search for Rightmost 1 (CTZ) [IMPLEMENTED]

**Architecture:** V850E2+

```c
unsigned int __builtin_v850_sch1r(unsigned int x);
```

**Description:** Returns position of rightmost 1 bit (0 = LSB, 31 = MSB), or 32 if x == 0.

**LLVM Intrinsic:** `@llvm.v850.sch1r(i32 %x)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:240`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:426-430`
- `llvm/include/llvm/IR/IntrinsicsV850.td:90-91`

---

### 10.3 SCH0L - Search for Leftmost 0 (CLO) [IMPLEMENTED]

**Architecture:** V850E2+

```c
unsigned int __builtin_v850_sch0l(unsigned int x);
```

**Description:** Returns position of leftmost 0 bit, or 32 if x == 0xFFFFFFFF.

**LLVM Intrinsic:** `@llvm.v850.sch0l(i32 %x)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:245`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:431-435`
- `llvm/include/llvm/IR/IntrinsicsV850.td:96-97`

---

### 10.4 SCH0R - Search for Rightmost 0 (CTO) [IMPLEMENTED]

**Architecture:** V850E2+

```c
unsigned int __builtin_v850_sch0r(unsigned int x);
```

**Description:** Returns position of rightmost 0 bit, or 32 if x == 0xFFFFFFFF.

**LLVM Intrinsic:** `@llvm.v850.sch0r(i32 %x)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:250`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:436-440`
- `llvm/include/llvm/IR/IntrinsicsV850.td:102-103`

---

## 11. Atomic Operations Intrinsics [PARTIAL]

### 11.1 CAXI - Compare and Exchange [IMPLEMENTED]

**Architecture:** V850E2M+

```c
unsigned int __builtin_v850_caxi(void *addr, unsigned int expected,
                                 unsigned int desired);
```

**Description:** Atomic compare-and-swap. Returns old value at addr.
Atomically: if (*addr == expected) *addr = desired; return old *addr

**LLVM Intrinsic:** `@llvm.v850.caxi(ptr %addr, i32 %expected, i32 %desired)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:292`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:446-452`
- `llvm/include/llvm/IR/IntrinsicsV850.td:112-114`

---

### 11.2 LDL.W - Load Linked Word [IMPLEMENTED]

**Architecture:** RH850G3M+

```c
unsigned int __builtin_v850_ldl_w(volatile unsigned int *ptr);
```

**Description:** Load linked - establishes exclusive monitor for lock-free synchronization.
Similar to ARM's LDREX or RISC-V's LR instruction.

**LLVM Intrinsic:** `@llvm.v850.ldl.w(ptr %ptr)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:467`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp`
- `llvm/include/llvm/IR/IntrinsicsV850.td`
- `llvm/lib/Target/V850/V850InstrInfo.td` (LDL_W instruction)

---

### 11.3 STC.W - Store Conditional Word [IMPLEMENTED]

**Architecture:** RH850G3M+

```c
int __builtin_v850_stc_w(volatile unsigned int *ptr, unsigned int value);
```

**Description:** Store conditional - succeeds only if exclusive monitor intact. Returns 1 on success, 0 on failure.
Similar to ARM's STREX or RISC-V's SC instruction.

**LLVM Intrinsic:** `@llvm.v850.stc.w(ptr %ptr, i32 %value)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:473`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp`
- `llvm/include/llvm/IR/IntrinsicsV850.td`
- `llvm/lib/Target/V850/V850InstrInfo.td` (STC_W instruction)

---

### 11.4 CLL - Clear Load Link [IMPLEMENTED]

**Architecture:** RH850G3M+

```c
void __builtin_v850_cll(void);
```

**Description:** Clears load-link state. Used to release exclusive monitor without storing.

**LLVM Intrinsic:** `@llvm.v850.cll()`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:462`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp`
- `llvm/include/llvm/IR/IntrinsicsV850.td`
- `llvm/lib/Target/V850/V850InstrInfo.td` (CLL instruction)

---

## 12. Cache Control Intrinsics [TODO]

### 12.1 CACHE - Cache Operations [TODO]

**Architecture:** RH850G3M+

```c
void __builtin_v850_cache(unsigned int op, void *addr);
```

**Cache Operations:**
| op | Name | Description |
|----|------|-------------|
| 0x00 | CHBII | Invalidate instruction cache line |
| 0x04 | CIBII | Invalidate instruction cache by index |
| 0x06 | CFALI | Flush and invalidate cache line |
| 0x07 | CISTI | Store instruction cache tag |
| 0x0C | CILDI | Load instruction cache tag |

**Priority:** Medium

---

### 12.2 PREF - Prefetch [TODO]

**Architecture:** RH850G3M+

```c
void __builtin_v850_prefetch(void *addr);
```

**Description:** Prefetch hint - no privilege required.

**Priority:** Medium

---

## 13. Special Instructions [PARTIAL]

### 13.1 HALT [IMPLEMENTED]

**Architecture:** V850 (Base)

```c
void __builtin_v850_halt(void);
```

**Description:** Halt CPU until interrupt.

**LLVM Intrinsic:** `@llvm.v850.halt()`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:330`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:456-459`
- `llvm/include/llvm/IR/IntrinsicsV850.td:206`

---

### 13.2 TRAP [IMPLEMENTED]

**Architecture:** V850 (Base)

```c
void __builtin_v850_trap(unsigned int vector);
```

**Description:** Software trap (vector 0-31).

**LLVM Intrinsic:** `@llvm.v850.trap(i32 %vector)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:331`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:460-464`
- `llvm/include/llvm/IR/IntrinsicsV850.td:209-210`

---

### 13.3 SYSCALL [IMPLEMENTED]

**Architecture:** V850E2M+

```c
void __builtin_v850_syscall(unsigned int vector);
```

**Description:** System call (vector 0-255).

**LLVM Intrinsic:** `@llvm.v850.syscall(i32 %vector)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:336`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:465-469`
- `llvm/include/llvm/IR/IntrinsicsV850.td:213-214`

---

### 13.4 FETRAP [IMPLEMENTED]

**Architecture:** V850E2M+

```c
void __builtin_v850_fetrap(unsigned int vector);
```

**Description:** FE-level trap (vector 1-15, 0 is reserved).

**LLVM Intrinsic:** `@llvm.v850.fetrap(i32 %vector)`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def:341`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp:470-474`
- `llvm/include/llvm/IR/IntrinsicsV850.td:217-218`

---

### 13.5 SNOOZE [IMPLEMENTED]

**Architecture:** RH850G3M+

```c
void __builtin_v850_snooze(void);
```

**Description:** Low-power spin-wait. Enters a low-power state waiting for an interrupt.

**LLVM Intrinsic:** `@llvm.v850.snooze()`

**Files:**
- `clang/include/clang/Basic/BuiltinsV850.def`
- `clang/lib/CodeGen/TargetBuiltins/V850.cpp`
- `llvm/include/llvm/IR/IntrinsicsV850.td`
- `llvm/lib/Target/V850/V850InstrInfo.td` (SNOOZE instruction)

---

## 14. Data Manipulation Intrinsics [PARTIAL]

### 14.1 BINS - Bitfield Insert [PARTIAL]

**Architecture:** RH850G3M+

```c
unsigned int __builtin_v850_bins(unsigned int src, unsigned int dst,
                                 unsigned int pos, unsigned int width);
```

**Description:** Insert bitfield: `dst[pos+width-1:pos] = src[width-1:0]`

**Instruction Status:** IMPLEMENTED in `V850InstrInfo.td`
- Three encoding variants (BINS0, BINS1, BINS2) based on msb/lsb range
- Assembler always uses variant 0; disassembler handles all variants

**Intrinsic Status:** TODO - Clang builtin not yet implemented

**Priority:** Medium

---

### 14.2 ROTL - Rotate Left [PARTIAL]

**Architecture:** RH850G3M+

```c
unsigned int __builtin_v850_rotl(unsigned int x, unsigned int count);
```

**Description:** Rotate left by count bits.

**Instruction Status:** IMPLEMENTED in `V850InstrInfo.td`
- ROTL_imm5: Rotate left by 5-bit immediate (0-31)
- ROTL_reg: Rotate left by register value

**Intrinsic Status:** TODO - Clang builtin not yet implemented
(Can use `__builtin_rotateleft32` which maps to LLVM's `fshl` intrinsic)

**Priority:** Medium

---

## 15. CLIP Saturation Intrinsics (RH850G4MH+) [TODO]

### 15.1 CLIP.B — Clip to Signed Byte [TODO]

**Architecture:** RH850G4MH+

```c
int __builtin_v850_clip_b(int x);
```

**Description:** Saturates x to signed byte range (-128 to 127).

### 15.2 CLIP.BU — Clip to Unsigned Byte [TODO]

```c
unsigned int __builtin_v850_clip_bu(int x);
```

**Description:** Saturates x to unsigned byte range (0 to 255).

### 15.3 CLIP.H — Clip to Signed Halfword [TODO]

```c
int __builtin_v850_clip_h(int x);
```

**Description:** Saturates x to signed halfword range (-32768 to 32767).

### 15.4 CLIP.HU — Clip to Unsigned Halfword [TODO]

```c
unsigned int __builtin_v850_clip_hu(int x);
```

**Description:** Saturates x to unsigned halfword range (0 to 65535).

**Feature Required:** `rh850g4mh`

---

## 16. MPU Load/Store Intrinsics (RH850G4MH2+) [TODO]

### 16.1 LDM.MP — Load Multiple MPU Entries [TODO]

```c
void __builtin_v850_ldm_mp(void *addr, unsigned int eh, unsigned int et);
```

**Description:** Loads MPU entries (MPLA/MPUA/MPAT) from memory for entries eh through et.
SV privilege required.

### 16.2 STM.MP — Store Multiple MPU Entries [TODO]

```c
void __builtin_v850_stm_mp(unsigned int eh, unsigned int et, void *addr);
```

**Description:** Stores MPU entries to memory. SV privilege required.

**Feature Required:** `rh850g4mh2`

---

## 17. Virtualization Intrinsics (RH850G4MH2+) [TODO]

### 17.1 HVTRAP — Hypervisor Trap [TODO]

```c
void __builtin_v850_hvtrap(unsigned int vector);
```

**Description:** Hypervisor EI-level trap (vector 0-31). Saves PC, PSW, enters host mode.
SV privilege, requires HVCFG.HVE=1.

### 17.2 LDM.GSR — Load Multiple Guest System Registers [TODO]

```c
void __builtin_v850_ldm_gsr(void *addr);
```

**Description:** Loads pre-defined guest system registers from memory. HV privilege.

### 17.3 STM.GSR — Store Multiple Guest System Registers [TODO]

```c
void __builtin_v850_stm_gsr(void *addr);
```

**Description:** Stores pre-defined guest system registers to memory. HV privilege.

**Feature Required:** `rh850g4mh2`

---

## 18. FXU Vector Intrinsics (RH850G4MH+) [FUTURE]

The FXU provides SIMD operations on 128-bit vectors (4 × single-precision floats).
See [plan-v850-g4m-g4mh.md](plan-v850-g4m-g4mh.md) Phase 5 for full implementation plan.

### 18.1 FXU Vector Types

```c
typedef float v4sf __attribute__((vector_size(16)));
```

### 18.2 FXU Intrinsics — Full Instruction List (59 Total)

#### Manipulation (3)

| Builtin | Instruction | Description |
|---------|-------------|-------------|
| `__builtin_v850_movv_w4(v4sf src)` | MOVV.W4 | Move vector register |
| `__builtin_v850_flpv_s4(v4sf a, v4sf b)` | FLPV.S4 | Flip (exchange) elements |
| `__builtin_v850_shflv_w4(int imm12, v4sf a, v4sf b)` | SHFLV.W4 | Shuffle elements |

#### Load/Store (8)

| Builtin | Instruction | Description |
|---------|-------------|-------------|
| `__builtin_v850_ldv_w(void *addr)` | LDV.W | Load single word to element |
| `__builtin_v850_ldv_dw(void *addr)` | LDV.DW | Load double-word |
| `__builtin_v850_ldv_qw(void *addr)` | LDV.QW | Load quad-word (full 128-bit) |
| `__builtin_v850_ldvz_h4(void *addr)` | LDVZ.H4 | Load 4 halfwords, zero-extend |
| `__builtin_v850_stv_w(v4sf src, void *addr)` | STV.W | Store single word |
| `__builtin_v850_stv_dw(v4sf src, void *addr)` | STV.DW | Store double-word |
| `__builtin_v850_stv_qw(v4sf src, void *addr)` | STV.QW | Store quad-word |
| `__builtin_v850_stvz_h4(v4sf src, void *addr)` | STVZ.H4 | Store truncated to halfwords |

#### Arithmetic (11)

| Builtin | Instruction | Description |
|---------|-------------|-------------|
| `__builtin_v850_absf_s4(v4sf a)` | ABSF.S4 | Absolute value (4x) |
| `__builtin_v850_negf_s4(v4sf a)` | NEGF.S4 | Negate (4x) |
| `__builtin_v850_addf_s4(v4sf a, v4sf b)` | ADDF.S4 | Add (4x) |
| `__builtin_v850_subf_s4(v4sf a, v4sf b)` | SUBF.S4 | Subtract (4x) |
| `__builtin_v850_mulf_s4(v4sf a, v4sf b)` | MULF.S4 | Multiply (4x) |
| `__builtin_v850_divf_s4(v4sf a, v4sf b)` | DIVF.S4 | Divide (4x) |
| `__builtin_v850_maxf_s4(v4sf a, v4sf b)` | MAXF.S4 | Maximum (4x) |
| `__builtin_v850_minf_s4(v4sf a, v4sf b)` | MINF.S4 | Minimum (4x) |
| `__builtin_v850_sqrtf_s4(v4sf a)` | SQRTF.S4 | Square root (4x) |
| `__builtin_v850_recipf_s4(v4sf a)` | RECIPF.S4 | Reciprocal (4x) |
| `__builtin_v850_rsqrtf_s4(v4sf a)` | RSQRTF.S4 | Reciprocal sqrt (4x) |

#### FMA (4)

| Builtin | Instruction | Description |
|---------|-------------|-------------|
| `__builtin_v850_fmaf_s4(v4sf a, v4sf b, v4sf c)` | FMAF.S4 | c = b*a + c |
| `__builtin_v850_fmsf_s4(v4sf a, v4sf b, v4sf c)` | FMSF.S4 | c = b*a - c |
| `__builtin_v850_fnmaf_s4(v4sf a, v4sf b, v4sf c)` | FNMAF.S4 | c = -(b*a) + c |
| `__builtin_v850_fnmsf_s4(v4sf a, v4sf b, v4sf c)` | FNMSF.S4 | c = -(b*a) - c |

#### Compound Arithmetic (4)

| Builtin | Instruction | Description |
|---------|-------------|-------------|
| `__builtin_v850_addsubf_s4(v4sf a, v4sf b)` | ADDSUBF.S4 | [3:2]=add, [1:0]=sub |
| `__builtin_v850_addsubnf_s4(v4sf a, v4sf b)` | ADDSUBNF.S4 | [3:2]=add, [1:0]=sub (neg) |
| `__builtin_v850_subaddf_s4(v4sf a, v4sf b)` | SUBADDF.S4 | [3:2]=sub, [1:0]=add |
| `__builtin_v850_subaddnf_s4(v4sf a, v4sf b)` | SUBADDNF.S4 | [3:2]=sub, [1:0]=add (neg) |

#### Exchange Arithmetic (7)

| Builtin | Instruction | Description |
|---------|-------------|-------------|
| `__builtin_v850_addxf_s4(v4sf a, v4sf b)` | ADDXF.S4 | Add with exchange |
| `__builtin_v850_subxf_s4(v4sf a, v4sf b)` | SUBXF.S4 | Sub with exchange |
| `__builtin_v850_mulxf_s4(v4sf a, v4sf b)` | MULXF.S4 | Mul with exchange |
| `__builtin_v850_addsubxf_s4(v4sf a, v4sf b)` | ADDSUBXF.S4 | Add-sub with exchange |
| `__builtin_v850_addsubnxf_s4(v4sf a, v4sf b)` | ADDSUBNXF.S4 | Add-sub neg with exchange |
| `__builtin_v850_subaddxf_s4(v4sf a, v4sf b)` | SUBADDXF.S4 | Sub-add with exchange |
| `__builtin_v850_subaddnxf_s4(v4sf a, v4sf b)` | SUBADDNXF.S4 | Sub-add neg with exchange |

#### Reduction (5)

| Builtin | Instruction | Description |
|---------|-------------|-------------|
| `__builtin_v850_addrf_s4(v4sf a)` | ADDRF.S4 | Reduction add |
| `__builtin_v850_subrf_s4(v4sf a)` | SUBRF.S4 | Reduction subtract |
| `__builtin_v850_mulrf_s4(v4sf a)` | MULRF.S4 | Reduction multiply |
| `__builtin_v850_maxrf_s4(v4sf a)` | MAXRF.S4 | Reduction maximum |
| `__builtin_v850_minrf_s4(v4sf a)` | MINRF.S4 | Reduction minimum |

#### Conversion (14)

| Builtin | Instruction | Description |
|---------|-------------|-------------|
| `__builtin_v850_cvtf_hs4(v4sf a)` | CVTF.HS4 | 4x half → 4x single |
| `__builtin_v850_cvtf_sh4(v4sf a)` | CVTF.SH4 | 4x single → 4x half |
| `__builtin_v850_cvtf_sw4(v4sf a)` | CVTF.SW4 | 4x single → 4x int |
| `__builtin_v850_cvtf_ws4(v4sf a)` | CVTF.WS4 | 4x int → 4x single |
| `__builtin_v850_cvtf_suw4(v4sf a)` | CVTF.SUW4 | 4x single → 4x uint |
| `__builtin_v850_cvtf_uws4(v4sf a)` | CVTF.UWS4 | 4x uint → 4x single |
| `__builtin_v850_trncf_sw4(v4sf a)` | TRNCF.SW4 | Truncate 4x single → int |
| `__builtin_v850_trncf_suw4(v4sf a)` | TRNCF.SUW4 | Truncate 4x single → uint |
| `__builtin_v850_ceilf_sw4(v4sf a)` | CEILF.SW4 | Ceiling 4x single → int |
| `__builtin_v850_ceilf_suw4(v4sf a)` | CEILF.SUW4 | Ceiling 4x single → uint |
| `__builtin_v850_floorf_sw4(v4sf a)` | FLOORF.SW4 | Floor 4x single → int |
| `__builtin_v850_floorf_suw4(v4sf a)` | FLOORF.SUW4 | Floor 4x single → uint |
| `__builtin_v850_roundf_sw4(v4sf a)` | ROUNDF.SW4 | Round 4x single → int |
| `__builtin_v850_roundf_suw4(v4sf a)` | ROUNDF.SUW4 | Round 4x single → uint |

#### Comparison (3)

| Builtin | Instruction | Description |
|---------|-------------|-------------|
| `__builtin_v850_cmpf_s4(int fcond, v4sf a, v4sf b)` | CMPF.S4 | Compare 4x, store mask |
| `__builtin_v850_cmovf_w4(int fcond4, v4sf a, v4sf b)` | CMOVF.W4 | Conditional move |
| `__builtin_v850_trfsrv_w4(int imm3, v4sf a)` | TRFSRV.W4 | Transfer FXU status |

**Implementation Notes:**
- Requires new vector register class (wreg0-wreg31)
- Requires PSW.CU1 coprocessor enable
- Consider auto-vectorization support via TargetTransformInfo
- See [plan-v850-g4m-g4mh.md](plan-v850-g4m-g4mh.md) Phase 5 for implementation details

---

## 19. Implementation Guidelines

### 16.1 Adding a New Builtin

1. **Define in BuiltinsV850.def:**
```c
// For base V850:
BUILTIN(__builtin_v850_xxx, "signature", "attrs")

// For V850E1+:
TARGET_BUILTIN(__builtin_v850_xxx, "signature", "attrs", "v850e1")
```

2. **Add LLVM Intrinsic in IntrinsicsV850.td:**
```tablegen
def int_v850_xxx : Intrinsic<[return_ty], [arg_tys],
                             [properties]>;
```

3. **Add CodeGen in V850.cpp:**
```cpp
case V850::BI__builtin_v850_xxx: {
  // Emit LLVM IR
  Function *F = CGM.getIntrinsic(Intrinsic::v850_xxx);
  return Builder.CreateCall(F, args);
}
```

4. **Add Instruction Pattern in V850InstrInfo.td:**
```tablegen
def : Pat<(int_v850_xxx args), (XXX args)>;
```

5. **Add Tests:**
- `clang/test/CodeGen/V850/builtins.c`
- `clang/test/Sema/v850-builtins-*.c`

### 16.2 Type Signatures

| Code | Type |
|------|------|
| `v` | void |
| `i` | int |
| `Ui` | unsigned int |
| `LLi` | long long |
| `ULLi` | unsigned long long |
| `v*` | void* |
| `I` | (prefix) immediate/constant |

### 16.3 Builtin Attributes

| Attr | Meaning |
|------|---------|
| `n` | nothrow |
| `c` | const (no side effects, no memory access) |
| `r` | readonly (reads memory, no side effects) |

---

## 20. Implementation Priority

### Phase 1 (High Priority) - COMPLETE
1. ~~Bit search: SCH1L, SCH1R, SCH0L, SCH0R~~ [DONE]
2. ~~Atomics: CAXI~~ [DONE], ~~LDL.W, STC.W~~ [DONE] (G3M builtins)
3. ~~SYNCI memory barrier~~ [DONE] (G3M builtin)
4. ~~HALT instruction~~ [DONE]

### Phase 2 (Medium Priority)
1. Cache: CACHE, PREF (instructions exist, builtins TODO)
2. Data manipulation: BINS (instruction exists, builtin TODO)
3. Additional system registers (G3M groups 1-7, see plan-v850-g3m-g3mh.md)
4. ~~TRAP, SYSCALL~~ [DONE]

### Phase 3 (Low Priority)
1. ~~HSH halfword swap~~ [DONE]
2. ~~3-operand saturating arithmetic~~ [DONE]
3. ~~SNOOZE~~ [DONE], ~~FETRAP~~ [DONE]
4. ~~CLL (clear load link)~~ [DONE]

### Phase 4 (G4MH — see [plan-v850-g4m-g4mh.md](plan-v850-g4m-g4mh.md))
1. CLIP saturation intrinsics: clip_b, clip_bu, clip_h, clip_hu (4 total)
2. MPU load/store intrinsics: ldm_mp, stm_mp (2 total, G4MH2)
3. Virtualization intrinsics: hvtrap, ldm_gsr, stm_gsr (3 total, G4MH2)
4. FXU vector intrinsics (59 total)

---

## 21. Test Coverage

### Existing Tests
- `clang/test/CodeGen/V850/builtins.c`
- `clang/test/Sema/v850-builtins-error.c`
- `clang/test/Sema/v850-builtins-v850e1.c`
- `clang/test/Sema/v850-builtins-v850e2m.c`

### Required Tests for New Intrinsics
1. **CodeGen tests** - Verify correct LLVM IR generation
2. **Sema tests** - Verify feature requirements
3. **MC tests** - Verify instruction encoding
4. **Runtime tests** - Verify correct execution (if simulator available)

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2026-03-08 | 1.7 | Added G4MH intrinsic sections: CLIP saturation (§15), MPU load/store (§16), virtualization (§17); expanded FXU section (§18) with full 59-instruction builtin list; updated priority table (Phase 4 now references plan-v850-g4m-g4mh.md) |
| 2026-02-11 | 1.6 | Updated G3M intrinsics status: SYNCI, SNOOZE, CLL, LDL.W, STC.W all DONE; created plan-v850-g3m-g3mh.md for remaining features |
| 2026-01-18 | 1.5 | Added special instruction intrinsics (HALT, TRAP, SYSCALL, FETRAP) |
| 2026-01-18 | 1.4 | Added HSH, SATADD3, SATSUB3 intrinsics |
| 2026-01-18 | 1.3 | Added bit search intrinsics (SCH1L, SCH1R, SCH0L, SCH0R) and CAXI atomic CAS |
| 2026-01-18 | 1.2 | Added 23 new system register intrinsics (debug regs, exception cause, DBWR) |
| 2026-01-17 | 1.1 | Added SATSUBR intrinsic (saturating subtract reverse) |
| 2026-01-17 | 1.0 | Initial version with implementation audit |
