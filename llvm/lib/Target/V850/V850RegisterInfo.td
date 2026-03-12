//===-- V850RegisterInfo.td - V850 Register defs ----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Declarations that describe the V850 register file.
//
// V850 has 32 general-purpose 32-bit registers (r0-r31):
//   r0       - Zero register (always reads as 0, writes ignored)
//   r1       - Assembler reserved (for address generation)
//   r2       - Reserved for RTOS/variable
//   r3 (SP)  - Stack Pointer
//   r4 (GP)  - Global Pointer (global data area access)
//   r5 (TP)  - Text Pointer (text area start address)
//   r6-r9    - Argument/result registers (caller-saved)
//   r10-r19  - Caller-saved temporary registers
//   r20-r29  - Callee-saved registers
//   r30 (EP) - Element Pointer (SLD/SST base for short-format memory access)
//   r31 (LP) - Link Pointer (return address)
//
// System registers (accessed via LDSR/STSR):
//   0 - EIPC  (Exception/Interrupt PC)
//   1 - EIPSW (Exception/Interrupt PSW)
//   2 - FEPC  (Fatal Error PC)
//   3 - FEPSW (Fatal Error PSW)
//   4 - ECR   (Exception Cause Register, read-only via STSR)
//   5 - PSW   (Program Status Word)
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// V850 Register Class Definitions
//===----------------------------------------------------------------------===//

class V850Reg<bits<5> Enc, string n, list<string> altNames = []>
    : Register<n, altNames> {
  let HWEncoding{4-0} = Enc;
  let Namespace = "V850";
}

//===----------------------------------------------------------------------===//
// General Purpose Registers (r0-r31)
//===----------------------------------------------------------------------===//

// r0 - Zero register (always reads as 0, writes are ignored)
// Used to synthesize immediate-zero operations (e.g., MOV r0, rX for clear)
def R0 : V850Reg<0, "r0", ["zero"]>, DwarfRegNum<[0]>;

// r1 - Assembler reserved register (used for address generation helpers)
// Higher cost to discourage allocation
let CostPerUse = [1] in
def R1 : V850Reg<1, "r1">, DwarfRegNum<[1]>;

// r2 - Variable/RTOS register (may be used by real-time OS)
// Higher cost to discourage allocation
let CostPerUse = [1] in
def R2 : V850Reg<2, "r2">, DwarfRegNum<[2]>;

// r3 - Stack Pointer
let CostPerUse = [1] in
def SP : V850Reg<3, "r3", ["sp"]>, DwarfRegNum<[3]>;

// r4 - Global Pointer (global data area access)
let CostPerUse = [1] in
def GP : V850Reg<4, "r4", ["gp"]>, DwarfRegNum<[4]>;

// r5 - Text Pointer (text area start address)
let CostPerUse = [1] in
def TP : V850Reg<5, "r5", ["tp"]>, DwarfRegNum<[5]>;

// r6-r9 - Argument/result registers (caller-saved)
// These are used to pass arguments and return values
def R6  : V850Reg<6,  "r6">, DwarfRegNum<[6]>;
def R7  : V850Reg<7,  "r7">, DwarfRegNum<[7]>;
def R8  : V850Reg<8,  "r8">, DwarfRegNum<[8]>;
def R9  : V850Reg<9,  "r9">, DwarfRegNum<[9]>;

// r10-r19 - Caller-saved temporary registers
// Return value in r10 (32-bit) or r10:r11 (64-bit)
def R10 : V850Reg<10, "r10">, DwarfRegNum<[10]>;
def R11 : V850Reg<11, "r11">, DwarfRegNum<[11]>;
def R12 : V850Reg<12, "r12">, DwarfRegNum<[12]>;
def R13 : V850Reg<13, "r13">, DwarfRegNum<[13]>;
def R14 : V850Reg<14, "r14">, DwarfRegNum<[14]>;
def R15 : V850Reg<15, "r15">, DwarfRegNum<[15]>;
def R16 : V850Reg<16, "r16">, DwarfRegNum<[16]>;
def R17 : V850Reg<17, "r17">, DwarfRegNum<[17]>;
def R18 : V850Reg<18, "r18">, DwarfRegNum<[18]>;
def R19 : V850Reg<19, "r19">, DwarfRegNum<[19]>;

// r20-r29 - Callee-saved registers
// Functions must preserve these across calls
def R20 : V850Reg<20, "r20">, DwarfRegNum<[20]>;
def R21 : V850Reg<21, "r21">, DwarfRegNum<[21]>;
def R22 : V850Reg<22, "r22">, DwarfRegNum<[22]>;
def R23 : V850Reg<23, "r23">, DwarfRegNum<[23]>;
def R24 : V850Reg<24, "r24">, DwarfRegNum<[24]>;
def R25 : V850Reg<25, "r25">, DwarfRegNum<[25]>;
def R26 : V850Reg<26, "r26">, DwarfRegNum<[26]>;
def R27 : V850Reg<27, "r27">, DwarfRegNum<[27]>;
def R28 : V850Reg<28, "r28">, DwarfRegNum<[28]>;
def R29 : V850Reg<29, "r29">, DwarfRegNum<[29]>;

// r30 - Element Pointer (base for SLD/SST short-format memory access)
let CostPerUse = [1] in
def EP : V850Reg<30, "r30", ["ep"]>, DwarfRegNum<[30]>;

// r31 - Link Pointer (return address for function calls)
let CostPerUse = [1] in
def LP : V850Reg<31, "r31", ["lp"]>, DwarfRegNum<[31]>;

//===----------------------------------------------------------------------===//
// Program Counter (pseudo register for DWARF)
//===----------------------------------------------------------------------===//

// PC is not directly accessible on V850 but is needed for DWARF CFI.
// It's implicitly modified by branches/calls and saved/restored via system registers.
// We use a separate definition without HWEncoding since PC has no hardware register number.
def PC : Register<"pc"> {
  let Namespace = "V850";
  let DwarfNumbers = [64];
}

//===----------------------------------------------------------------------===//
// Register Classes
//===----------------------------------------------------------------------===//

// General purpose register class - all 32 registers
// Order: caller-saved temporaries first (preferred for allocation),
// then callee-saved, then special-purpose registers
def GPR : RegisterClass<"V850", [i32], 32,
    (add
     // Caller-saved temporaries (preferred for allocation)
     R10, R11, R12, R13, R14, R15, R16, R17, R18, R19,
     // Argument registers
     R6, R7, R8, R9,
     // Callee-saved registers
     R20, R21, R22, R23, R24, R25, R26, R27, R28, R29,
     // Special-purpose registers (less preferred)
     R1, R2, EP, LP, SP, GP, TP,
     // Zero register (read-only)
     R0
    )>;

// GPR class excluding r0 (for destinations that can't be r0)
def GPRnoR0 : RegisterClass<"V850", [i32], 32,
    (sub GPR, R0)>;

//===----------------------------------------------------------------------===//
// Sub-register indices for 64-bit register pairs (double-precision FP)
//
// V850 double-precision FP uses even/odd GPR pairs:
//   - Even register (sub_lo): holds low 32 bits
//   - Odd register (sub_hi):  holds high 32 bits
//===----------------------------------------------------------------------===//

def sub_lo : SubRegIndex<32, 0>;   // bits [31:0]  — even register
def sub_hi : SubRegIndex<32, 32>;  // bits [63:32] — odd register

// V850 double-precision register pair: {even, odd} = {low, high}
// HWEncoding = even register number (0, 2, 4, ..., 30)
// Instructions encode only the even register; hardware implicitly uses reg+1.
class V850RegPair<bits<5> Enc, string n, list<Register> subregs>
    : RegisterWithSubRegs<n, subregs> {
  let HWEncoding{4-0} = Enc;
  let Namespace = "V850";
  let SubRegIndices = [sub_lo, sub_hi];
  let CoveredBySubRegs = 1;
}

// Double-precision register pairs.
// Named "dN" (not "rN") to avoid conflict with GPR register names in the
// AsmMatcher. The assembly parser maps even GPR names (r0, r2, r6, ...) to
// the appropriate DPR register via a custom parseDPRRegister() method.
// The instruction printer maps DPR registers back to even GPR names via
// printDPRRegister().
// D0/D2/D4/D30 include reserved GPRs; they exist for MC but are not allocatable.
def D0  : V850RegPair<0,  "d0",  [R0,  R1]>;  // R0 = zero register
def D2  : V850RegPair<2,  "d2",  [R2,  SP]>;  // SP is stack pointer
def D4  : V850RegPair<4,  "d4",  [GP,  TP]>;  // GP/TP are reserved pointers
def D6  : V850RegPair<6,  "d6",  [R6,  R7]>;
def D8  : V850RegPair<8,  "d8",  [R8,  R9]>;
def D10 : V850RegPair<10, "d10", [R10, R11]>;
def D12 : V850RegPair<12, "d12", [R12, R13]>;
def D14 : V850RegPair<14, "d14", [R14, R15]>;
def D16 : V850RegPair<16, "d16", [R16, R17]>;
def D18 : V850RegPair<18, "d18", [R18, R19]>;
def D20 : V850RegPair<20, "d20", [R20, R21]>;
def D22 : V850RegPair<22, "d22", [R22, R23]>;
def D24 : V850RegPair<24, "d24", [R24, R25]>;
def D26 : V850RegPair<26, "d26", [R26, R27]>;
def D28 : V850RegPair<28, "d28", [R28, R29]>;
def D30 : V850RegPair<30, "d30", [EP,  LP]>;  // EP=element ptr, LP=link ptr

// FPR - Floating-point register class (uses same physical registers as GPR)
// V850 uses GPRs for single-precision FP operations
def FPR : RegisterClass<"V850", [f32], 32,
    (add
     // Caller-saved temporaries (preferred for allocation)
     R10, R11, R12, R13, R14, R15, R16, R17, R18, R19,
     // Argument registers
     R6, R7, R8, R9,
     // Callee-saved registers
     R20, R21, R22, R23, R24, R25, R26, R27, R28, R29,
     // Special-purpose registers (less preferred)
     R1, R2, EP, LP, SP, GP, TP,
     // Zero register
     R0
    )>;

// DPR - Double-precision floating-point register class (f64, 64-bit pairs)
// V850 double-precision FP uses even/odd GPR pairs.
// Only D6-D28 are allocatable (D0/D2/D4 contain reserved GPRs; D30 has EP/LP).
// Allocation order: caller-saved temporaries first, then arg regs, then
// callee-saved. This matches the GPR/FPR preference order.
def DPR : RegisterClass<"V850", [f64], 64,
    (add
     // Caller-saved temporaries (preferred for allocation)
     D10, D12, D14, D16, D18,
     // Argument registers
     D6, D8,
     // Callee-saved registers
     D20, D22, D24, D26, D28
    )>;

//===----------------------------------------------------------------------===//
// FXU Vector Registers (RH850G4MH+)
//
// The FXU (Extended Floating-point Unit) has 32 dedicated 128-bit vector
// registers (wreg0-wreg31), each holding 4 x single-precision floats.
// These are independent from the GPR-based FPR/DPR register files.
//
// Register encoding: 5-bit field (0-31) directly encodes the register number.
// Requires PSW.CU1=1 (Coprocessor 1 Use Permission).
//===----------------------------------------------------------------------===//

class VGPRReg<bits<5> Enc, string n> : Register<n> {
  let HWEncoding{4-0} = Enc;
  let Namespace = "V850";
}

// wreg0-wreg31: 32 x 128-bit FXU vector registers
foreach i = 0-31 in
  def WREG#i : VGPRReg<!cast<bits<5>>(i), "wreg"#i>;

// VGPR - 128-bit vector register class for FXU (RH850G4MH+)
// All 32 vector registers are caller-saved (no callee-save convention defined).
// v4f32: 4 x single-precision float (primary FXU type)
def VGPR : RegisterClass<"V850", [v4f32], 128,
    (add WREG0, WREG1, WREG2, WREG3, WREG4, WREG5, WREG6, WREG7,
         WREG8, WREG9, WREG10, WREG11, WREG12, WREG13, WREG14, WREG15,
         WREG16, WREG17, WREG18, WREG19, WREG20, WREG21, WREG22, WREG23,
         WREG24, WREG25, WREG26, WREG27, WREG28, WREG29, WREG30, WREG31
    )>;

//===----------------------------------------------------------------------===//
// System Registers
//===----------------------------------------------------------------------===//

class V850SysReg<bits<5> Enc, string n> : Register<n> {
  let HWEncoding{4-0} = Enc;
  let Namespace = "V850";
}

//===----------------------------------------------------------------------===//
// Base System Registers (All V850 variants: V850, V850ES, V850E1, V850E2, V850E2M)
//
// DWARF Register Number Mapping:
//   DWARF 0-31:  General purpose registers r0-r31
//   DWARF 64:    PC (Program Counter)
//   DWARF 65:    PSW (Program Status Word)
//   DWARF 66-69: Exception registers (EIPC, EIPSW, FEPC, FEPSW)
//   DWARF 70:    ECR (Exception Cause Register)
//   DWARF 71-73: CALLT registers (CTPC, CTPSW, CTBP)
//   DWARF 74-75: Debug registers (DBPC, DBPSW)
//===----------------------------------------------------------------------===//

// Exception/Interrupt PC - saved PC when exception/interrupt occurs
def EIPC  : V850SysReg<0, "eipc">, DwarfRegNum<[66]>;

// Exception/Interrupt PSW - saved PSW when exception/interrupt occurs
def EIPSW : V850SysReg<1, "eipsw">, DwarfRegNum<[67]>;

// Fatal Error PC - saved PC when fatal error (NMI, etc.) occurs
def FEPC  : V850SysReg<2, "fepc">, DwarfRegNum<[68]>;

// Fatal Error PSW - saved PSW when fatal error occurs
def FEPSW : V850SysReg<3, "fepsw">, DwarfRegNum<[69]>;

// Exception Cause Register - indicates cause of exception (read-only via STSR)
def ECR   : V850SysReg<4, "ecr">, DwarfRegNum<[70]>;

// Program Status Word - contains flags (Z, S, OV, CY, SAT) and control bits
def PSW   : V850SysReg<5, "psw">, DwarfRegNum<[65]>;

//===----------------------------------------------------------------------===//
// V850E1 Additional System Registers (V850E1, V850E2, V850E2M, V850E3)
// NOTE: These are NOT available on V850ES
//===----------------------------------------------------------------------===//

// CALLT caller status saving registers
// CTPC - CALLT caller PC (return address)
def CTPC  : V850SysReg<16, "ctpc">, DwarfRegNum<[71]>;

// CTPSW - CALLT caller PSW
def CTPSW : V850SysReg<17, "ctpsw">, DwarfRegNum<[72]>;

// CTBP - CALLT base pointer
def CTBP  : V850SysReg<20, "ctbp">, DwarfRegNum<[73]>;

// Debug registers (for Type A/B products with debug function)
// DBPC - Debug PC (return address from debug trap)
def DBPC  : V850SysReg<18, "dbpc">, DwarfRegNum<[74]>;

// DBPSW - Debug PSW
def DBPSW : V850SysReg<19, "dbpsw">, DwarfRegNum<[75]>;

// DIR - Debug Interface Register
// Controls debug mode and breakpoint channel selection (DIR.CS)
def DIR   : V850SysReg<21, "dir">;

// BPC - Breakpoint Control
// Note: There are two breakpoint channels (BPC0/BPC1) selected by DIR.CS bit
// This represents the currently selected channel
def BPC   : V850SysReg<22, "bpc">;

// ASID - Address Space ID
// Used for process identification in MMU and debug operations
def ASID  : V850SysReg<23, "asid">;

// BPAV - Breakpoint Address Value
// Contains address to match for breakpoint (BPAV0/BPAV1 selected by DIR.CS)
def BPAV  : V850SysReg<24, "bpav">;

// BPAM - Breakpoint Address Mask
// Mask for breakpoint address matching (BPAM0/BPAM1 selected by DIR.CS)
def BPAM  : V850SysReg<25, "bpam">;

// BPDV - Breakpoint Data Value
// Data value to match for data breakpoint (BPDV0/BPDV1 selected by DIR.CS)
def BPDV  : V850SysReg<26, "bpdv">;

// BPDM - Breakpoint Data Mask
// Mask for breakpoint data matching (BPDM0/BPDM1 selected by DIR.CS)
def BPDM  : V850SysReg<27, "bpdm">;

//===----------------------------------------------------------------------===//
// V850E2M System Registers (V850E2M, V850E3)
// NOTE: These are NOT available on V850 or V850ES or V850E1
//===----------------------------------------------------------------------===//

// SYSCALL registers (V850E2M+)
// SCCFG - SYSCALL operation setting (CPU Main Bank, regID 11)
// Note: Same regID as FPEC, but FPEC is in FPU Bank (BSEL=0x2000)
// Access: Available in CPU Main Bank (BSEL=0x0000, default)
def SCCFG : V850SysReg<11, "sccfg">;

// SCBP - SYSCALL base pointer
def SCBP  : V850SysReg<12, "scbp">;

// Exception cause registers (V850E2M+)
// EIIC - EI-level exception cause code
def EIIC  : V850SysReg<13, "eiic">;

// FEIC - FE-level exception cause code
def FEIC  : V850SysReg<14, "feic">;

// DBIC - Debug exception cause code
def DBIC  : V850SysReg<15, "dbic">;

// Exception handler working registers (V850E2M+)
// EIWR - EI level working register
def EIWR  : V850SysReg<28, "eiwr">;

// FEWR - FE level working register
def FEWR  : V850SysReg<29, "fewr">;

// DBWR - DB level working register
def DBWR  : V850SysReg<30, "dbwr">;

// BSEL - Register bank selection (V850E2M+)
// This register selects which bank of system registers (regID 0-27) is active.
// Registers 28-31 (EIWR, FEWR, DBWR, BSEL) are always accessible regardless of bank.
//
// Bank Values:
//   0x0000 - CPU Main Bank (default): Basic system registers
//   0x0010 - Exception Handler Switching Bank 0
//   0x0011 - Exception Handler Switching Bank 1
//   0x1000 - Processor Protection Violation Bank
//   0x1010 - Software Paging Bank
//   0x2000 - FPU Status Bank: FPSR, FPEPC, FPST, FPCC, FPCFG, FPEC at regID 6-11
//   0xFF00 - User Bank 0
//   0xFFFF - User Compatible Bank
//
// Usage:
//   movhi 0x20, r0, r10    ; r10 = 0x2000
//   ldsr  r10, bsel        ; Select FPU Status Bank
//   stsr  fpsr, r11        ; Read FPSR from FPU bank
//   mov   r0, r10
//   ldsr  r10, bsel        ; Restore CPU Main Bank
def BSEL  : V850SysReg<31, "bsel">;

//===----------------------------------------------------------------------===//
// FPU System Registers (V850E2M+)
//
// IMPORTANT: V850E2M Register Banking
// ====================================
// On V850E2M, FPU system registers (regID 6-11) are accessed via register
// banking using the BSEL register (SR31).
//
// To access FPU registers, software must:
//   1. Load BSEL with 0x2000 (FPU Status Bank):
//        movhi 0x20, r0, r10    ; r10 = 0x20000000 >> 16 = 0x2000
//        ldsr  r10, bsel        ; Select FPU bank
//   2. Access FPU registers via LDSR/STSR with regID 6-11
//   3. Restore BSEL to 0x0000 (CPU Main Bank) when done:
//        mov   r0, r10
//        ldsr  r10, bsel        ; Select CPU main bank
//
// Bank Summary:
//   BSEL=0x0000 (CPU Main):  regID 6-10 are undefined, regID 11 is SCCFG
//   BSEL=0x2000 (FPU Bank):  regID 6-11 are FPSR, FPEPC, FPST, FPCC, FPCFG, FPEC
//
// Note: The assembler generates the correct encoding (regID 6-11), but it is
// the programmer's responsibility to set BSEL appropriately before access.
// Accessing FPU registers without setting BSEL=0x2000 causes undefined behavior.
//
// RH850G3M uses selID-based access instead of BSEL banking.
//===----------------------------------------------------------------------===//

// FPSR - Floating-point configuration/status (FPU Bank, regID 6)
// Contains CC (condition codes), rounding mode, and exception flags
// Access: Set BSEL=0x2000 before LDSR/STSR
def FPSR  : V850SysReg<6, "fpsr">;

// FPEPC - Floating-point exception PC (FPU Bank, regID 7)
// Access: Set BSEL=0x2000 before LDSR/STSR
def FPEPC : V850SysReg<7, "fpepc">;

// FPST - Floating-point status (FPU Bank, regID 8)
// Alias for FPSR.RM and FPSR.XE bits
// Access: Set BSEL=0x2000 before LDSR/STSR
def FPST  : V850SysReg<8, "fpst">;

// FPCC - Floating-point comparison result (FPU Bank, regID 9)
// Contains 8 condition code bits from FPU comparisons
// Access: Set BSEL=0x2000 before LDSR/STSR
def FPCC  : V850SysReg<9, "fpcc">;

// FPCFG - Floating-point configuration (FPU Bank, regID 10)
// Contains rounding mode and flush-to-zero settings
// Access: Set BSEL=0x2000 before LDSR/STSR
def FPCFG : V850SysReg<10, "fpcfg">;

// FPEC - Floating-point exception control (FPU Bank, regID 11)
// Controls FPI exception checking/canceling
// Access: Set BSEL=0x2000 before LDSR/STSR
// Note: Same regID as SCCFG, but SCCFG is in CPU Main Bank (BSEL=0x0000)
def FPEC  : V850SysReg<11, "fpec">;

// Note: System registers are no longer modeled as a register class.
// They are accessed via LDSR/STSR instructions using immediate regID operands
// (see V850SystemOperands.td for the name<->encoding lookup table).
//
// The register definitions above (EIPC, PSW, FPSR, etc.) are kept because
// they are referenced in Defs/Uses lists to model side effects accurately.
