// Check V850 preprocessor macros

// RUN: %clang -target v850 -E -dM %s -o - | FileCheck -check-prefix=V850-BASE %s
// V850-BASE: #define __V850__ 1
// V850-BASE: #define __v850 1
// V850-BASE: #define __v850__ 1
// V850-BASE-NOT: #define __v850e__
// V850-BASE-NOT: #define __V850_FPU__

// RUN: %clang -target v850 -mcpu=v850e1 -E -dM %s -o - | FileCheck -check-prefix=V850E1 %s
// V850E1: #define __V850__ 1
// V850E1: #define __v850e1__ 1
// V850E1: #define __v850e__ 1
// V850E1-NOT: #define __v850e2__
// V850E1-NOT: #define __V850_FPU__

// RUN: %clang -target v850 -mcpu=v850es -E -dM %s -o - | FileCheck -check-prefix=V850ES %s
// V850ES: #define __V850__ 1
// V850ES: #define __v850e__ 1
// V850ES: #define __v850es__ 1
// V850ES-NOT: #define __v850e2__
// V850ES-NOT: #define __V850_FPU__

// RUN: %clang -target v850 -mcpu=v850e2 -E -dM %s -o - | FileCheck -check-prefix=V850E2 %s
// V850E2: #define __V850__ 1
// V850E2: #define __v850e2__ 1
// V850E2: #define __v850e__ 1
// V850E2-NOT: #define __v850e2m__
// V850E2-NOT: #define __V850_FPU__

// RUN: %clang -target v850 -mcpu=v850e2m -E -dM %s -o - | FileCheck -check-prefix=V850E2M %s
// V850E2M: #define __V850_FEATURE_FMA__ 1
// V850E2M: #define __V850_FEATURE_MINMAX__ 1
// V850E2M: #define __V850_FEATURE_SQRT__ 1
// V850E2M: #define __V850_FPU__ 1
// V850E2M: #define __V850_FP__ 0x6
// V850E2M: #define __V850__ 1
// V850E2M: #define __v850e2__ 1
// V850E2M: #define __v850e2m__ 1
// V850E2M: #define __v850e__ 1
// V850E2M-NOT: #define __V850_SOFT_FLOAT__

// RUN: %clang -target v850 -mcpu=v850e2v3 -E -dM %s -o - | FileCheck -check-prefix=V850E2V3 %s
// V850E2V3: #define __V850_FPU__ 1
// V850E2V3: #define __V850__ 1
// V850E2V3: #define __v850e2__ 1
// V850E2V3: #define __v850e2v3__ 1
// V850E2V3: #define __v850e3__ 1
// V850E2V3: #define __v850e__ 1

// RUN: %clang -target v850 -mcpu=v850e3 -E -dM %s -o - | FileCheck -check-prefix=V850E3 %s
// V850E3: #define __V850_FPU__ 1
// V850E3: #define __V850__ 1
// V850E3: #define __v850e2__ 1
// V850E3: #define __v850e3__ 1
// V850E3: #define __v850e__ 1
// V850E3-NOT: #define __v850e2v3__

// Test soft-float disables FPU macros
// RUN: %clang -target v850 -mcpu=v850e2m -msoft-float -E -dM %s -o - | FileCheck -check-prefix=V850E2M-SOFT %s
// V850E2M-SOFT: #define __V850_SOFT_FLOAT__ 1
// V850E2M-SOFT: #define __v850e2m__ 1
// V850E2M-SOFT-NOT: #define __V850_FPU__
// V850E2M-SOFT-NOT: #define __V850_FP__
// V850E2M-SOFT-NOT: #define __V850_FEATURE_FMA__

// Test enabling FPU on base V850
// RUN: %clang -target v850 -mcpu=v850 -mhard-float -E -dM %s -o - | FileCheck -check-prefix=V850-FPU %s
// V850-FPU: #define __V850_FPU__ 1
// V850-FPU: #define __V850_FP__ 0x6
// V850-FPU: #define __V850__ 1
// V850-FPU-NOT: #define __v850e__

// Test disabling FPU on V850E2M (uses -msoft-float which also sets soft-float ABI)
// RUN: %clang -target v850 -mcpu=v850e2m -msoft-float -E -dM %s -o - | FileCheck -check-prefix=V850E2M-NOFPU %s
// V850E2M-NOFPU: #define __V850_SOFT_FLOAT__ 1
// V850E2M-NOFPU: #define __v850e2m__ 1
// V850E2M-NOFPU-NOT: #define __V850_FPU__
// V850E2M-NOFPU-NOT: #define __V850_FP__
