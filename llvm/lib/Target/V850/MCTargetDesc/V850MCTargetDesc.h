//===-- V850MCTargetDesc.h - V850 Target Descriptions -----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file provides V850 specific target descriptions.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_V850_MCTARGETDESC_V850MCTARGETDESC_H
#define LLVM_LIB_TARGET_V850_MCTARGETDESC_V850MCTARGETDESC_H

#include "llvm/Support/DataTypes.h"
#include <memory>

namespace llvm {

class Target;

} // namespace llvm

// Defines symbolic names for V850 registers.
#define GET_REGINFO_ENUM
#include "V850GenRegisterInfo.inc"

#endif // LLVM_LIB_TARGET_V850_MCTARGETDESC_V850MCTARGETDESC_H
