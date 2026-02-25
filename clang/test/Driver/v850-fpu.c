// Check V850 FPU and soft-float options

// v850e2m has FPU enabled by default via getV850TargetFeatures()
// RUN: %clang --target=v850 -mcpu=v850e2m -### -c %s 2>&1 | FileCheck -check-prefix=FPU-DEFAULT %s
// FPU-DEFAULT: "-target-feature" "+v850fpu"
// FPU-DEFAULT: "-target-cpu" "v850e2m"

// Explicit -mv850-fpu should also enable the FPU
// RUN: %clang --target=v850 -mcpu=v850e2m -mv850-fpu -### -c %s 2>&1 | FileCheck -check-prefix=FPU-ENABLE %s
// FPU-ENABLE: "-target-feature" "+v850fpu"
// FPU-ENABLE: "-target-cpu" "v850e2m"

// Explicit -mno-v850-fpu disables the FPU
// RUN: %clang --target=v850 -mcpu=v850e2m -mno-v850-fpu -### -c %s 2>&1 | FileCheck -check-prefix=FPU-DISABLE %s
// FPU-DISABLE: "-target-feature" "-v850fpu"
// FPU-DISABLE: "-target-cpu" "v850e2m"

// Base v850 CPU has no FPU by default
// RUN: %clang --target=v850 -mcpu=v850 -### -c %s 2>&1 | FileCheck -check-prefix=FPU-BASE-DEFAULT %s
// FPU-BASE-DEFAULT: "-target-feature" "-v850fpu"
// FPU-BASE-DEFAULT: "-target-cpu" "v850"

// Base v850 with explicit -mv850-fpu enables the FPU
// RUN: %clang --target=v850 -mcpu=v850 -mv850-fpu -### -c %s 2>&1 | FileCheck -check-prefix=FPU-BASE %s
// FPU-BASE: "-target-feature" "+v850fpu"
// FPU-BASE: "-target-cpu" "v850"

// Test soft-float options
// RUN: %clang --target=v850 -mcpu=v850e2m -mv850-soft-float -### -c %s 2>&1 | FileCheck -check-prefix=SOFT-FLOAT %s
// SOFT-FLOAT: "-target-feature" "+v850fpu"
// SOFT-FLOAT: "-target-feature" "+soft-float"
// SOFT-FLOAT: "-target-cpu" "v850e2m"

// RUN: %clang --target=v850 -mcpu=v850e2m -mno-v850-soft-float -### -c %s 2>&1 | FileCheck -check-prefix=NO-SOFT-FLOAT %s
// NO-SOFT-FLOAT: "-target-feature" "+v850fpu"
// NO-SOFT-FLOAT: "-target-feature" "-soft-float"
// NO-SOFT-FLOAT: "-target-cpu" "v850e2m"

// Test combining FPU and soft-float options
// RUN: %clang --target=v850 -mcpu=v850e2m -mv850-fpu -mv850-soft-float -### -c %s 2>&1 | FileCheck -check-prefix=FPU-SOFT %s
// FPU-SOFT: "-target-feature" "+v850fpu"
// FPU-SOFT: "-target-feature" "+soft-float"
