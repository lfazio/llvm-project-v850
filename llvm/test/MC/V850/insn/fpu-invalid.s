// RUN: not llvm-mc -triple=v850 -mcpu=v850e2m %s 2>&1 | FileCheck %s

// Test invalid FPU operations - odd registers for double-precision
// Odd-numbered registers are rejected at parse time by parseDPRRegister.

// Double-precision arithmetic requires even-numbered registers
// CHECK: error: double-precision FPU requires even-numbered register
addf.d r5, r8, r10

// CHECK: error: double-precision FPU requires even-numbered register
subf.d r6, r9, r10

// CHECK: error: double-precision FPU requires even-numbered register
mulf.d r6, r8, r11

// Double-precision unary operations
// CHECK: error: double-precision FPU requires even-numbered register
absf.d r5, r8

// CHECK: error: double-precision FPU requires even-numbered register
negf.d r6, r9

// Double-precision comparison
// CHECK: error: double-precision FPU requires even-numbered register
cmpf.d eq, r5, r8, 0

// Conversion from double with odd source
// CHECK: error: double-precision FPU requires even-numbered register
cvtf.ds r7, r6

// Conversion to double with odd destination
// CHECK: error: double-precision FPU requires even-numbered register
cvtf.sd r6, r9

// Rounding from double with odd source
// CHECK: error: double-precision FPU requires even-numbered register
trncf.dw r7, r8

// CHECK: error: double-precision FPU requires even-numbered register
ceilf.dl r7, r8

// CHECK: error: double-precision FPU requires even-numbered register
floorf.duw r7, r8
