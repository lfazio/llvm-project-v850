// Check V850 CPU selection and target features

// RUN: %clang --target=v850 -### -c %s 2>&1 | FileCheck -check-prefix=DEFAULT %s
// DEFAULT: "-triple" "v850"
// DEFAULT-NOT: "-target-cpu"

// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=v850 | FileCheck -check-prefix=V850 %s
// V850: "-target-cpu" "v850"

// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=v850e1 | FileCheck -check-prefix=V850E1 %s
// V850E1: "-target-cpu" "v850e1"

// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=v850es | FileCheck -check-prefix=V850ES %s
// V850ES: "-target-cpu" "v850es"

// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=v850e2 | FileCheck -check-prefix=V850E2 %s
// V850E2: "-target-cpu" "v850e2"

// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=v850e2m | FileCheck -check-prefix=V850E2M %s
// V850E2M: "-target-cpu" "v850e2m"

// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=v850e2v3 | FileCheck -check-prefix=V850E2V3 %s
// V850E2V3: "-target-cpu" "v850e2v3"

// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=v850e3 | FileCheck -check-prefix=V850E3 %s
// V850E3: "-target-cpu" "v850e3"
