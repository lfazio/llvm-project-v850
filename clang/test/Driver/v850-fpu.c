// Check V850 FPU and soft-float options

// RUN: %clang --target=v850 -mcpu=v850e2m -### -c %s 2>&1 | FileCheck -check-prefix=FPU-DEFAULT %s
// FPU-DEFAULT: "-target-cpu" "v850e2m"
// FPU-DEFAULT-NOT: "-target-feature" "+fpu"
// FPU-DEFAULT-NOT: "-target-feature" "-fpu"

// RUN: %clang --target=v850 -mcpu=v850e2m -mv850-fpu -### -c %s 2>&1 | FileCheck -check-prefix=FPU-ENABLE %s
// FPU-ENABLE: "-target-cpu" "v850e2m"
// FPU-ENABLE: "-target-feature" "+fpu"

// RUN: %clang --target=v850 -mcpu=v850e2m -mno-v850-fpu -### -c %s 2>&1 | FileCheck -check-prefix=FPU-DISABLE %s
// FPU-DISABLE: "-target-cpu" "v850e2m"
// FPU-DISABLE: "-target-feature" "-fpu"

// RUN: %clang --target=v850 -mcpu=v850 -mv850-fpu -### -c %s 2>&1 | FileCheck -check-prefix=FPU-BASE %s
// FPU-BASE: "-target-cpu" "v850"
// FPU-BASE: "-target-feature" "+fpu"

// Test soft-float options
// RUN: %clang --target=v850 -mcpu=v850e2m -mv850-soft-float -### -c %s 2>&1 | FileCheck -check-prefix=SOFT-FLOAT %s
// SOFT-FLOAT: "-target-cpu" "v850e2m"
// SOFT-FLOAT: "-target-feature" "+soft-float"

// RUN: %clang --target=v850 -mcpu=v850e2m -mno-v850-soft-float -### -c %s 2>&1 | FileCheck -check-prefix=NO-SOFT-FLOAT %s
// NO-SOFT-FLOAT: "-target-cpu" "v850e2m"
// NO-SOFT-FLOAT: "-target-feature" "-soft-float"

// Test combining FPU and soft-float options
// RUN: %clang --target=v850 -mcpu=v850e2m -mv850-fpu -mv850-soft-float -### -c %s 2>&1 | FileCheck -check-prefix=FPU-SOFT %s
// FPU-SOFT: "-target-feature" "+fpu"
// FPU-SOFT: "-target-feature" "+soft-float"
