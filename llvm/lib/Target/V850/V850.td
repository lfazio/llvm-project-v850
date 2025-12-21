//===- V850.td - Describe the V850 Target Machine ----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This is the top level entry point for the V850 target.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Target-independent interfaces which we are implementing
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

//===----------------------------------------------------------------------===//
// V850 subtarget features and instruction predicates
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Register File, Calling Conv, Instruction Descriptions
//===----------------------------------------------------------------------===//

include "V850RegisterInfo.td"
include "V850InstrInfo.td"

def V850InstrInfo : InstrInfo;

//===----------------------------------------------------------------------===//
// V850 processors supported
//===----------------------------------------------------------------------===//

class Proc<string Name, list<SubtargetFeature> Features>
    : Processor<Name, NoItineraries, Features>;

def : Proc<"generic", []>;
def : Proc<"v850", []>;
def : Proc<"v850e", []>;
def : Proc<"v850e2", []>;

//===----------------------------------------------------------------------===//
// V850 assembly writer
//===----------------------------------------------------------------------===//

def V850InstPrinter : AsmWriter {
  string AsmWriterClassName = "InstPrinter";
  bit isMCAsmWriter = 1;
  int PassSubtarget = 1;
}

//===----------------------------------------------------------------------===//
// V850 assembly parser
//===----------------------------------------------------------------------===//

def V850AsmParser : AsmParser {
  let ShouldEmitMatchRegisterAltName = 1;
  let AllowDuplicateRegisterNames = 1;
}

//===----------------------------------------------------------------------===//
// Declare the target which we are implementing
//===----------------------------------------------------------------------===//

def V850 : Target {
  let InstructionSet = V850InstrInfo;
  let AssemblyWriters = [V850InstPrinter];
  let AssemblyParsers = [V850AsmParser];
}
