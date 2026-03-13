// Check V850 FPU and soft-float options using standard -mhard-float/-msoft-float

// v850e2m has FPU enabled by default via getV850TargetFeatures()
// RUN: %clang --target=v850 -mcpu=v850e2m -### -c %s 2>&1 | FileCheck -check-prefix=FPU-DEFAULT %s
// FPU-DEFAULT: "-target-feature" "+v850fpu"
// FPU-DEFAULT: "-target-cpu" "v850e2m"

// Explicit -mhard-float should also enable the FPU
// RUN: %clang --target=v850 -mcpu=v850e2m -mhard-float -### -c %s 2>&1 | FileCheck -check-prefix=FPU-ENABLE %s
// FPU-ENABLE: "-target-feature" "+v850fpu"
// FPU-ENABLE: "-target-cpu" "v850e2m"

// Explicit -msoft-float disables the FPU and sets soft-float ABI
// RUN: %clang --target=v850 -mcpu=v850e2m -msoft-float -### -c %s 2>&1 | FileCheck -check-prefix=FPU-DISABLE %s
// FPU-DISABLE: "-target-feature" "-v850fpu"
// FPU-DISABLE: "-target-feature" "+soft-float"
// FPU-DISABLE: "-target-cpu" "v850e2m"

// Base v850 CPU has no FPU by default
// RUN: %clang --target=v850 -mcpu=v850 -### -c %s 2>&1 | FileCheck -check-prefix=FPU-BASE-DEFAULT %s
// FPU-BASE-DEFAULT: "-target-feature" "-v850fpu"
// FPU-BASE-DEFAULT: "-target-cpu" "v850"

// Base v850 with explicit -mhard-float enables the FPU
// RUN: %clang --target=v850 -mcpu=v850 -mhard-float -### -c %s 2>&1 | FileCheck -check-prefix=FPU-BASE %s
// FPU-BASE: "-target-feature" "+v850fpu"
// FPU-BASE: "-target-cpu" "v850"

// -msoft-float on v850e2m disables FPU and enables soft-float ABI
// RUN: %clang --target=v850 -mcpu=v850e2m -msoft-float -### -c %s 2>&1 | FileCheck -check-prefix=SOFT-FLOAT %s
// SOFT-FLOAT: "-target-feature" "-v850fpu"
// SOFT-FLOAT: "-target-feature" "+soft-float"
// SOFT-FLOAT: "-target-cpu" "v850e2m"

// -mhard-float on v850e2m enables FPU (no soft-float)
// RUN: %clang --target=v850 -mcpu=v850e2m -mhard-float -### -c %s 2>&1 | FileCheck -check-prefix=HARD-FLOAT %s
// HARD-FLOAT: "-target-feature" "+v850fpu"
// HARD-FLOAT-NOT: "+soft-float"
// HARD-FLOAT: "-target-cpu" "v850e2m"

// Test -mhard-float after -msoft-float (last wins)
// RUN: %clang --target=v850 -mcpu=v850e2m -msoft-float -mhard-float -### -c %s 2>&1 | FileCheck -check-prefix=FPU-SOFT-HARD %s
// FPU-SOFT-HARD: "-target-feature" "+v850fpu"
// FPU-SOFT-HARD-NOT: "+soft-float"
// FPU-SOFT-HARD: "-target-cpu" "v850e2m"

// -mno-soft-float undoes -msoft-float (re-enables FPU)
// RUN: %clang --target=v850 -mcpu=v850e2m -msoft-float -mno-soft-float -### -c %s 2>&1 | FileCheck -check-prefix=NO-SOFT %s
// NO-SOFT: "-target-feature" "+v850fpu"
// NO-SOFT-NOT: "+soft-float"
// NO-SOFT: "-target-cpu" "v850e2m"

// -msingle-float enables FPU with single-precision only
// RUN: %clang --target=v850 -mcpu=v850e2m -msingle-float -### -c %s 2>&1 | FileCheck -check-prefix=SINGLE-FLOAT %s
// SINGLE-FLOAT: "-target-feature" "+v850fpu"
// SINGLE-FLOAT: "-target-feature" "+single-float-only"
// SINGLE-FLOAT-NOT: "+soft-float"
// SINGLE-FLOAT: "-target-cpu" "v850e2m"

// -msingle-float on base v850 enables FPU (single only)
// RUN: %clang --target=v850 -mcpu=v850 -msingle-float -### -c %s 2>&1 | FileCheck -check-prefix=SINGLE-BASE %s
// SINGLE-BASE: "-target-feature" "+v850fpu"
// SINGLE-BASE: "-target-feature" "+single-float-only"
// SINGLE-BASE: "-target-cpu" "v850"
