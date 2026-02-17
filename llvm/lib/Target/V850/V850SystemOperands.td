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
// register ID (regID). On RH850G3M+, an additional 5-bit group ID (selID)
// selects the register bank.
//
// Following the RISC-V CSR pattern, system registers are modeled as
// immediate operands with a lookup table for name<->encoding mapping.
//
//===----------------------------------------------------------------------===//

include "llvm/TableGen/SearchableTable.td"

//===----------------------------------------------------------------------===//
// System Register Entry
//===----------------------------------------------------------------------===//

class V850SysRegEntry<string name, bits<5> op> {
  string Name = name;
  bits<5> Encoding = op;
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
// Base V850 System Registers (always available)
//===----------------------------------------------------------------------===//

def SysRegEIPC  : V850SysRegEntry<"eipc",  0>;
def SysRegEIPSW : V850SysRegEntry<"eipsw", 1>;
def SysRegFEPC  : V850SysRegEntry<"fepc",  2>;
def SysRegFEPSW : V850SysRegEntry<"fepsw", 3>;
def SysRegECR   : V850SysRegEntry<"ecr",   4>;
def SysRegPSW   : V850SysRegEntry<"psw",   5>;

//===----------------------------------------------------------------------===//
// FPU System Registers (regID 6-10, FPU Bank via BSEL=0x2000)
// FPEC at regID 11 shares encoding with SCCFG in CPU Main Bank.
// The programmer must set BSEL=0x2000 before accessing FPEC.
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureV850FPU} }] in {
def SysRegFPSR  : V850SysRegEntry<"fpsr",  6>;
def SysRegFPEPC : V850SysRegEntry<"fpepc", 7>;
def SysRegFPST  : V850SysRegEntry<"fpst",  8>;
def SysRegFPCC  : V850SysRegEntry<"fpcc",  9>;
def SysRegFPCFG : V850SysRegEntry<"fpcfg", 10>;
}

//===----------------------------------------------------------------------===//
// V850E2M CPU Bank System Registers (regID 11-15)
// SCCFG at regID 11 is in CPU Main Bank (BSEL=0x0000, the default).
// Listed before FPEC so SCCFG is the preferred name for regID 11.
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureV850E2M} }] in {
def SysRegSCCFG : V850SysRegEntry<"sccfg", 11>;
def SysRegSCBP  : V850SysRegEntry<"scbp",  12>;
def SysRegEIIC  : V850SysRegEntry<"eiic",  13>;
def SysRegFEIC  : V850SysRegEntry<"feic",  14>;
def SysRegDBIC  : V850SysRegEntry<"dbic",  15>;
}

//===----------------------------------------------------------------------===//
// FPU System Register FPEC (regID 11, FPU Bank via BSEL=0x2000)
// Alias for SCCFG encoding - only accessible when BSEL selects FPU bank.
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureV850FPU} }] in {
def SysRegFPEC  : V850SysRegEntry<"fpec",  11>;
}

//===----------------------------------------------------------------------===//
// V850E1+ System Registers (regID 16-27)
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureV850E1} }] in {
def SysRegCTPC  : V850SysRegEntry<"ctpc",  16>;
def SysRegCTPSW : V850SysRegEntry<"ctpsw", 17>;
def SysRegDBPC  : V850SysRegEntry<"dbpc",  18>;
def SysRegDBPSW : V850SysRegEntry<"dbpsw", 19>;
def SysRegCTBP  : V850SysRegEntry<"ctbp",  20>;
def SysRegDIR   : V850SysRegEntry<"dir",   21>;
def SysRegBPC   : V850SysRegEntry<"bpc",   22>;
def SysRegASID  : V850SysRegEntry<"asid",  23>;
def SysRegBPAV  : V850SysRegEntry<"bpav",  24>;
def SysRegBPAM  : V850SysRegEntry<"bpam",  25>;
def SysRegBPDV  : V850SysRegEntry<"bpdv",  26>;
def SysRegBPDM  : V850SysRegEntry<"bpdm",  27>;
}

//===----------------------------------------------------------------------===//
// V850E2M+ System Registers (regID 28-31)
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureV850E2M} }] in {
def SysRegEIWR  : V850SysRegEntry<"eiwr",  28>;
def SysRegFEWR  : V850SysRegEntry<"fewr",  29>;
def SysRegDBWR  : V850SysRegEntry<"dbwr",  30>;
def SysRegBSEL  : V850SysRegEntry<"bsel",  31>;
}
