// Check RH850G4MH/G4MH2 preprocessor macros

// RUN: %clang -target v850 -mcpu=g4mh -E -dM %s -o - | FileCheck -check-prefix=G4MH %s
// G4MH: #define __V850_FPU__ 1
// G4MH: #define __V850__ 1
// G4MH: #define __rh850__ 1
// G4MH: #define __rh850g3m__ 1
// G4MH: #define __rh850g3mh__ 1
// G4MH: #define __rh850g4mh__ 1
// G4MH: #define __v850e2__ 1
// G4MH: #define __v850e2m__ 1
// G4MH: #define __v850e__ 1
// G4MH-NOT: #define __rh850g4mh2__

// RUN: %clang -target v850 -mcpu=g4mh2 -E -dM %s -o - | FileCheck -check-prefix=G4MH2 %s
// G4MH2: #define __V850_FPU__ 1
// G4MH2: #define __V850__ 1
// G4MH2: #define __rh850__ 1
// G4MH2: #define __rh850g3m__ 1
// G4MH2: #define __rh850g3mh__ 1
// G4MH2: #define __rh850g4mh2__ 1
// G4MH2: #define __rh850g4mh__ 1
// G4MH2: #define __v850e2__ 1
// G4MH2: #define __v850e2m__ 1
// G4MH2: #define __v850e__ 1

// Verify soft-float disables FPU macros on G4MH
// RUN: %clang -target v850 -mcpu=g4mh -mv850-soft-float -E -dM %s -o - | FileCheck -check-prefix=G4MH-SOFT %s
// G4MH-SOFT: #define __V850_SOFT_FLOAT__ 1
// G4MH-SOFT: #define __rh850g4mh__ 1
// G4MH-SOFT-NOT: #define __V850_FPU__
