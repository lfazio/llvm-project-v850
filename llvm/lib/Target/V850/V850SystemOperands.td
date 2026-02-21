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
  // RBASE - Reset vector base (regID=2, selID=1)
  // Encoding = (1 << 5) | 2 = 34
  def SysRegRBASE : V850SysRegEntry<"rbase", 2, 1>;
  // EBASE - Exception handler vector base (regID=3, selID=1)
  // Encoding = (1 << 5) | 3 = 35
  def SysRegEBASE : V850SysRegEntry<"ebase", 3, 1>;
  // INTBP - Interrupt handler table base (regID=4, selID=1)
  // Encoding = (1 << 5) | 4 = 36
  def SysRegINTBP : V850SysRegEntry<"intbp", 4, 1>;
  // SCBP - SYSCALL base pointer (regID=12, selID=1)
  // Encoding = (1 << 5) | 12 = 44
  def SysRegSCBPG1 : V850SysRegEntry<"scbp_g1", 12, 1>;
}

//===----------------------------------------------------------------------===//
// RH850G3M+ System Registers - Group 2 (selID=2)
// Interrupt/thread configuration registers accessed with selID=2.
//===----------------------------------------------------------------------===//

let FeaturesRequired = [{ {V850::FeatureRH850G3M} }] in {
  // MEA - Memory error address (regID=6, selID=2)
  // Encoding = (2 << 5) | 6 = 70
  def SysRegMEA : V850SysRegEntry<"mea", 6, 2>;
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
