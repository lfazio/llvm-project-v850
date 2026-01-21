//===-- V850BaseInfo.h - Top level definitions for V850 MC ------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains small standalone helper functions and enum definitions for
// the V850 target useful for the compiler back-end and the MC libraries.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V850_MCTARGETDESC_V850BASEINFO_H
#define LLVM_LIB_TARGET_V850_MCTARGETDESC_V850BASEINFO_H

#include "llvm/Support/DataTypes.h"

namespace llvm {

/// V850II - This namespace holds all of the target specific flags that
/// instruction info tracks.
namespace V850II {

/// Target Operand Flag enum.
enum TOF {
  //===------------------------------------------------------------------===//
  // V850 Specific MachineOperand flags.

  MO_NO_FLAG = 0,

  /// MO_GPREL - Represents the offset from the GP (global pointer) register.
  /// Used for small data section (SDA) access.
  MO_GPREL = 1,

  /// MO_HI16 - Represents the high 16 bits of a 32-bit address.
  MO_HI16 = 2,

  /// MO_LO16 - Represents the low 16 bits of a 32-bit address.
  MO_LO16 = 3,
};

} // namespace V850II

} // namespace llvm

#endif // LLVM_LIB_TARGET_V850_MCTARGETDESC_V850BASEINFO_H
