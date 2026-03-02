//===-- V850SystemOperands.td - V850 System Register Defs --*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the system register names and encodings for V850.
// System registers are accessed via LDSR/STSR instructions using a 5-bit
// register ID (regID) and an optional 5-bit group ID (selID). On RH850G3M+,
// the selID selects the register bank.
//
// Following the AArch64 system register pattern, all fields are flattened into
// a single 10-bit encoding: Encoding = (selID << 5) | regID.
//
// Base V850 only uses selID=0 (implied). RH850G3M+ explicitly encodes selID
// in bits[20:16] of the LDSR/STSR instruction.
//
//===----------------------------------------------------------------------===//

include "llvm/TableGen/SearchableTable.td"

//===----------------------------------------------------------------------===//
// System Register Entry
//===----------------------------------------------------------------------===//

class V850SysRegEntry<string name, bits<5> regID, bits<5> selID = 0> {
  string Name = name;
  bits<10> Encoding;
  let Encoding{4 -0} = regID;
  let Encoding{9 -5} = selID;
  code FeaturesRequired = [{ {} }];
}

def V850SysRegsList : GenericTable {
  let FilterClass = "V850SysRegEntry";
  let Fields = ["Name", "Encoding", "FeaturesRequired"];
  let PrimaryKey = ["Encoding"];
  let PrimaryKeyName = "lookupV850SysRegByEncoding";
  let PrimaryKeyReturnRange = true;
}

def lookupV850SysRegByName : SearchIndex {
  let Table = V850SysRegsList;
  let Key = ["Name"];
}

//===----------------------------------------------------------------------===//
// Base V850 System Registers (selID=0, always available)
//===----------------------------------------------------------------------===//

def SysRegEIPC : V850SysRegEntry<"eipc", 0>;
def SysRegEIPSW : V850SysRegEntry<"eipsw", 1>;
def SysRegFEPC : V850SysRegEntry<"fepc", 2>;
def SysRegFEPSW : V850SysRegEntry<"fepsw", 3>;
def SysRegECR : V850SysRegEntry<"ecr", 4>;
def SysRegPSW : V850SysRegEntry<"psw", 5>;

//===----------------------------------------------------------------------===//
// FPU System Registers (regID 6-10, selID=0, FPU Bank via BSEL=0x2000)
// FPEC at regID 11 shares encoding with SCCFG in CPU Main Bank.
// The programmer must set BSEL=0x2000 before accessing FPEC.
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureV850FPU} }] in {
  def SysRegFPSR : V850SysRegEntry<"fpsr", 6>;
  def SysRegFPEPC : V850SysRegEntry<"fpepc", 7>;
  def SysRegFPST : V850SysRegEntry<"fpst", 8>;
  def SysRegFPCC : V850SysRegEntry<"fpcc", 9>;
  def SysRegFPCFG : V850SysRegEntry<"fpcfg", 10>;
}

//===----------------------------------------------------------------------===//
// V850E2M CPU Bank System Registers (regID 11-15, selID=0)
// SCCFG at regID 11 is in CPU Main Bank (BSEL=0x0000, the default).
// Listed before FPEC so SCCFG is the preferred name for regID 11.
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureV850E2M} }] in {
  def SysRegSCCFG : V850SysRegEntry<"sccfg", 11>;
  def SysRegSCBP : V850SysRegEntry<"scbp", 12>;
  def SysRegEIIC : V850SysRegEntry<"eiic", 13>;
  def SysRegFEIC : V850SysRegEntry<"feic", 14>;
  def SysRegDBIC : V850SysRegEntry<"dbic", 15>;
}

//===----------------------------------------------------------------------===//
// FPU System Register FPEC (regID 11, selID=0, FPU Bank via BSEL=0x2000)
// Alias for SCCFG encoding - only accessible when BSEL selects FPU bank.
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureV850FPU} }] in {
  def SysRegFPEC : V850SysRegEntry<"fpec", 11>;
}

//===----------------------------------------------------------------------===//
// V850E1+ System Registers (regID 16-27, selID=0)
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureV850E1} }] in {
  def SysRegCTPC : V850SysRegEntry<"ctpc", 16>;
  def SysRegCTPSW : V850SysRegEntry<"ctpsw", 17>;
  def SysRegDBPC : V850SysRegEntry<"dbpc", 18>;
  def SysRegDBPSW : V850SysRegEntry<"dbpsw", 19>;
  def SysRegCTBP : V850SysRegEntry<"ctbp", 20>;
  def SysRegDIR : V850SysRegEntry<"dir", 21>;
  def SysRegBPC : V850SysRegEntry<"bpc", 22>;
  def SysRegASID : V850SysRegEntry<"asid", 23>;
  def SysRegBPAV : V850SysRegEntry<"bpav", 24>;
  def SysRegBPAM : V850SysRegEntry<"bpam", 25>;
  def SysRegBPDV : V850SysRegEntry<"bpdv", 26>;
  def SysRegBPDM : V850SysRegEntry<"bpdm", 27>;
}

//===----------------------------------------------------------------------===//
// V850E2M+ System Registers (regID 28-31, selID=0)
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureV850E2M} }] in {
  def SysRegEIWR : V850SysRegEntry<"eiwr", 28>;
  def SysRegFEWR : V850SysRegEntry<"fewr", 29>;
  def SysRegDBWR : V850SysRegEntry<"dbwr", 30>;
  def SysRegBSEL : V850SysRegEntry<"bsel", 31>;
}

//===----------------------------------------------------------------------===//
// RH850G3M+ System Registers - Group 1 (selID=1)
// Machine configuration registers accessed with selID=1.
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureRH850G3M} }] in {
  // MCFG0 - Machine configuration register 0 (regID=0, selID=1)
  // Encoding = (1 << 5) | 0 = 32
  def SysRegMCFG0 : V850SysRegEntry<"mcfg0", 0, 1>;
  // RBASE - Reset vector base (regID=2, selID=1)
  // Encoding = (1 << 5) | 2 = 34
  def SysRegRBASE : V850SysRegEntry<"rbase", 2, 1>;
  // EBASE - Exception handler vector base (regID=3, selID=1)
  // Encoding = (1 << 5) | 3 = 35
  def SysRegEBASE : V850SysRegEntry<"ebase", 3, 1>;
  // INTBP - Interrupt handler table base (regID=4, selID=1)
  // Encoding = (1 << 5) | 4 = 36
  def SysRegINTBP : V850SysRegEntry<"intbp", 4, 1>;
  // MCTL - Machine control register (regID=5, selID=1)
  // Encoding = (1 << 5) | 5 = 37
  def SysRegMCTL : V850SysRegEntry<"mctl", 5, 1>;
  // PID - Processor ID (regID=6, selID=1, read-only)
  // Encoding = (1 << 5) | 6 = 38
  def SysRegPID : V850SysRegEntry<"pid", 6, 1>;
  // FPIPR - FPU interrupt priority register (regID=7, selID=1)
  // Encoding = (1 << 5) | 7 = 39
  // NOTE: Deleted in RH850G3MH (FPINT exception replaces FPP/FPI).
  def SysRegFPIPR : V850SysRegEntry<"fpipr", 7, 1>;
  // SCBP - SYSCALL base pointer (regID=12, selID=1)
  // Encoding = (1 << 5) | 12 = 44
  def SysRegSCBPG1 : V850SysRegEntry<"scbp_g1", 12, 1>;
}

//===----------------------------------------------------------------------===//
// RH850G3M+ System Registers - Group 2 (selID=2)
// Interrupt/thread configuration registers accessed with selID=2.
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureRH850G3M} }] in {
  // HTCFG0 - Hardware thread configuration 0 (regID=0, selID=2, read-only)
  // Encoding = (2 << 5) | 0 = 64
  // Contains PEID (Processor Element ID) for multi-core identification.
  def SysRegHTCFG0 : V850SysRegEntry<"htcfg0", 0, 2>;
  // MEA - Memory error address (regID=6, selID=2)
  // Encoding = (2 << 5) | 6 = 70
  def SysRegMEA : V850SysRegEntry<"mea", 6, 2>;
  // ASID - Address space ID (regID=7, selID=2)
  // Encoding = (2 << 5) | 7 = 71
  // NOTE: On G3M ASID moved from the V850E1 location (regID=23, selID=0) to
  // (regID=7, selID=2). Use "asid_g2" to access it on G3M targets.
  def SysRegASIDG2 : V850SysRegEntry<"asid_g2", 7, 2>;
  // MEI - Memory error information (regID=8, selID=2)
  // Encoding = (2 << 5) | 8 = 72
  def SysRegMEI : V850SysRegEntry<"mei", 8, 2>;
  // ISPR - Interrupt priority register (regID=10, selID=2)
  // Encoding = (2 << 5) | 10 = 74
  def SysRegISPR : V850SysRegEntry<"ispr", 10, 2>;
  // PMR - Priority level mask (regID=11, selID=2)
  // Encoding = (2 << 5) | 11 = 75
  def SysRegPMR : V850SysRegEntry<"pmr", 11, 2>;
  // ICSR - Interrupt control status (regID=12, selID=2)
  // Encoding = (2 << 5) | 12 = 76
  def SysRegICSR : V850SysRegEntry<"icsr", 12, 2>;
  // INTCFG - Interrupt function setting (regID=13, selID=2)
  // Encoding = (2 << 5) | 13 = 77
  def SysRegINTCFG : V850SysRegEntry<"intcfg", 13, 2>;
}

//===----------------------------------------------------------------------===//
// RH850G3M+ System Registers - Group 4 (selID=4)
// Instruction cache control registers. Only present when an instruction cache
// is installed in the hardware.
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureRH850G3M} }] in {
  // ICTAGL - Instruction cache tag Lo access (regID=16, selID=4)
  // Encoding = (4 << 5) | 16 = 144
  def SysRegICTAGL : V850SysRegEntry<"ictagl", 16, 4>;
  // ICTAGH - Instruction cache tag Hi access (regID=17, selID=4)
  // Encoding = (4 << 5) | 17 = 145
  def SysRegICTAGH : V850SysRegEntry<"ictagh", 17, 4>;
  // ICDATL - Instruction cache data Lo access (regID=18, selID=4)
  // Encoding = (4 << 5) | 18 = 146
  def SysRegICDATL : V850SysRegEntry<"icdatl", 18, 4>;
  // ICDATH - Instruction cache data Hi access (regID=19, selID=4)
  // Encoding = (4 << 5) | 19 = 147
  def SysRegICDATH : V850SysRegEntry<"icdath", 19, 4>;
  // ICCTRL - Instruction cache control (regID=24, selID=4)
  // Encoding = (4 << 5) | 24 = 152
  def SysRegICCTRL : V850SysRegEntry<"icctrl", 24, 4>;
  // ICCFG - Instruction cache configuration (regID=26, selID=4, read-only)
  // Encoding = (4 << 5) | 26 = 154
  def SysRegICCFG : V850SysRegEntry<"iccfg", 26, 4>;
  // ICERR - Instruction cache error (regID=28, selID=4)
  // Encoding = (4 << 5) | 28 = 156
  def SysRegICERR : V850SysRegEntry<"icerr", 28, 4>;
}

//===----------------------------------------------------------------------===//
// RH850G3M+ System Registers - Group 5 (selID=5)
// MPU mode and control registers. Only present when MPU is installed.
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureRH850G3M} }] in {
  // MPM - Memory protection operation mode (regID=0, selID=5)
  // Encoding = (5 << 5) | 0 = 160
  def SysRegMPM : V850SysRegEntry<"mpm", 0, 5>;
  // MPRC - MPU region control (regID=1, selID=5)
  // Encoding = (5 << 5) | 1 = 161
  def SysRegMPRC : V850SysRegEntry<"mprc", 1, 5>;
  // MPBRGN - MPU base region number (regID=4, selID=5, read-only)
  // Encoding = (5 << 5) | 4 = 164
  def SysRegMPBRGN : V850SysRegEntry<"mpbrgn", 4, 5>;
  // MPTRGN - MPU end region number (regID=5, selID=5, read-only)
  // Encoding = (5 << 5) | 5 = 165
  def SysRegMPTRGN : V850SysRegEntry<"mptrgn", 5, 5>;
  // MCA - Memory protection setting check address (regID=8, selID=5)
  // Encoding = (5 << 5) | 8 = 168
  def SysRegMCA : V850SysRegEntry<"mca", 8, 5>;
  // MCS - Memory protection setting check size (regID=9, selID=5)
  // Encoding = (5 << 5) | 9 = 169
  def SysRegMCS : V850SysRegEntry<"mcs", 9, 5>;
  // MCC - Memory protection setting check command (regID=10, selID=5)
  // Encoding = (5 << 5) | 10 = 170
  def SysRegMCC : V850SysRegEntry<"mcc", 10, 5>;
  // MCR - Memory protection setting check result (regID=11, selID=5)
  // Encoding = (5 << 5) | 11 = 171
  def SysRegMCR : V850SysRegEntry<"mcr", 11, 5>;
}

//===----------------------------------------------------------------------===//
// RH850G3M+ System Registers - Group 6 (selID=6)
// MPU protection area registers for regions 0-7 (MPLA/MPUA/MPAT).
// The number of regions incorporated depends on hardware configuration.
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureRH850G3M} }] in {
  def SysRegMPLA0 : V850SysRegEntry<"mpla0", 0, 6>;   // (6<<5)|0  = 192
  def SysRegMPUA0 : V850SysRegEntry<"mpua0", 1, 6>;   // (6<<5)|1  = 193
  def SysRegMPAT0 : V850SysRegEntry<"mpat0", 2, 6>;   // (6<<5)|2  = 194
  def SysRegMPLA1 : V850SysRegEntry<"mpla1", 4, 6>;   // (6<<5)|4  = 196
  def SysRegMPUA1 : V850SysRegEntry<"mpua1", 5, 6>;   // (6<<5)|5  = 197
  def SysRegMPAT1 : V850SysRegEntry<"mpat1", 6, 6>;   // (6<<5)|6  = 198
  def SysRegMPLA2 : V850SysRegEntry<"mpla2", 8, 6>;   // (6<<5)|8  = 200
  def SysRegMPUA2 : V850SysRegEntry<"mpua2", 9, 6>;   // (6<<5)|9  = 201
  def SysRegMPAT2 : V850SysRegEntry<"mpat2", 10, 6>;  // (6<<5)|10 = 202
  def SysRegMPLA3 : V850SysRegEntry<"mpla3", 12, 6>;  // (6<<5)|12 = 204
  def SysRegMPUA3 : V850SysRegEntry<"mpua3", 13, 6>;  // (6<<5)|13 = 205
  def SysRegMPAT3 : V850SysRegEntry<"mpat3", 14, 6>;  // (6<<5)|14 = 206
  def SysRegMPLA4 : V850SysRegEntry<"mpla4", 16, 6>;  // (6<<5)|16 = 208
  def SysRegMPUA4 : V850SysRegEntry<"mpua4", 17, 6>;  // (6<<5)|17 = 209
  def SysRegMPAT4 : V850SysRegEntry<"mpat4", 18, 6>;  // (6<<5)|18 = 210
  def SysRegMPLA5 : V850SysRegEntry<"mpla5", 20, 6>;  // (6<<5)|20 = 212
  def SysRegMPUA5 : V850SysRegEntry<"mpua5", 21, 6>;  // (6<<5)|21 = 213
  def SysRegMPAT5 : V850SysRegEntry<"mpat5", 22, 6>;  // (6<<5)|22 = 214
  def SysRegMPLA6 : V850SysRegEntry<"mpla6", 24, 6>;  // (6<<5)|24 = 216
  def SysRegMPUA6 : V850SysRegEntry<"mpua6", 25, 6>;  // (6<<5)|25 = 217
  def SysRegMPAT6 : V850SysRegEntry<"mpat6", 26, 6>;  // (6<<5)|26 = 218
  def SysRegMPLA7 : V850SysRegEntry<"mpla7", 28, 6>;  // (6<<5)|28 = 220
  def SysRegMPUA7 : V850SysRegEntry<"mpua7", 29, 6>;  // (6<<5)|29 = 221
  def SysRegMPAT7 : V850SysRegEntry<"mpat7", 30, 6>;  // (6<<5)|30 = 222
}

//===----------------------------------------------------------------------===//
// RH850G3M+ System Registers - Group 7 (selID=7)
// MPU protection area registers for regions 8-15 (MPLA/MPUA/MPAT).
// The number of regions incorporated depends on hardware configuration.
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureRH850G3M} }] in {
  def SysRegMPLA8  : V850SysRegEntry<"mpla8",  0,  7>;  // (7<<5)|0  = 224
  def SysRegMPUA8  : V850SysRegEntry<"mpua8",  1,  7>;  // (7<<5)|1  = 225
  def SysRegMPAT8  : V850SysRegEntry<"mpat8",  2,  7>;  // (7<<5)|2  = 226
  def SysRegMPLA9  : V850SysRegEntry<"mpla9",  4,  7>;  // (7<<5)|4  = 228
  def SysRegMPUA9  : V850SysRegEntry<"mpua9",  5,  7>;  // (7<<5)|5  = 229
  def SysRegMPAT9  : V850SysRegEntry<"mpat9",  6,  7>;  // (7<<5)|6  = 230
  def SysRegMPLA10 : V850SysRegEntry<"mpla10", 8,  7>;  // (7<<5)|8  = 232
  def SysRegMPUA10 : V850SysRegEntry<"mpua10", 9,  7>;  // (7<<5)|9  = 233
  def SysRegMPAT10 : V850SysRegEntry<"mpat10", 10, 7>;  // (7<<5)|10 = 234
  def SysRegMPLA11 : V850SysRegEntry<"mpla11", 12, 7>;  // (7<<5)|12 = 236
  def SysRegMPUA11 : V850SysRegEntry<"mpua11", 13, 7>;  // (7<<5)|13 = 237
  def SysRegMPAT11 : V850SysRegEntry<"mpat11", 14, 7>;  // (7<<5)|14 = 238
  def SysRegMPLA12 : V850SysRegEntry<"mpla12", 16, 7>;  // (7<<5)|16 = 240
  def SysRegMPUA12 : V850SysRegEntry<"mpua12", 17, 7>;  // (7<<5)|17 = 241
  def SysRegMPAT12 : V850SysRegEntry<"mpat12", 18, 7>;  // (7<<5)|18 = 242
  def SysRegMPLA13 : V850SysRegEntry<"mpla13", 20, 7>;  // (7<<5)|20 = 244
  def SysRegMPUA13 : V850SysRegEntry<"mpua13", 21, 7>;  // (7<<5)|21 = 245
  def SysRegMPAT13 : V850SysRegEntry<"mpat13", 22, 7>;  // (7<<5)|22 = 246
  def SysRegMPLA14 : V850SysRegEntry<"mpla14", 24, 7>;  // (7<<5)|24 = 248
  def SysRegMPUA14 : V850SysRegEntry<"mpua14", 25, 7>;  // (7<<5)|25 = 249
  def SysRegMPAT14 : V850SysRegEntry<"mpat14", 26, 7>;  // (7<<5)|26 = 250
  def SysRegMPLA15 : V850SysRegEntry<"mpla15", 28, 7>;  // (7<<5)|28 = 252
  def SysRegMPUA15 : V850SysRegEntry<"mpua15", 29, 7>;  // (7<<5)|29 = 253
  def SysRegMPAT15 : V850SysRegEntry<"mpat15", 30, 7>;  // (7<<5)|30 = 254
}
