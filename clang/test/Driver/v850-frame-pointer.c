// Check V850 frame pointer options

// By default with optimizations, frame pointer should be omitted
// RUN: %clang --target=v850 -O2 -### -c %s 2>&1 | FileCheck -check-prefix=OPT-OMIT %s
// OPT-OMIT-NOT: "-mframe-pointer=all"
// OPT-OMIT-NOT: "-mframe-pointer=non-leaf"

// Without optimizations, frame pointer should be kept
// RUN: %clang --target=v850 -O0 -### -c %s 2>&1 | FileCheck -check-prefix=NO-OPT %s
// NO-OPT: "-mframe-pointer=all"

// -fno-omit-frame-pointer should force frame pointer
// RUN: %clang --target=v850 -O2 -fno-omit-frame-pointer -### -c %s 2>&1 | FileCheck -check-prefix=FORCE-FP %s
// FORCE-FP: "-mframe-pointer=all"

// -fomit-frame-pointer should allow omitting even without optimizations
// RUN: %clang --target=v850 -O0 -fomit-frame-pointer -### -c %s 2>&1 | FileCheck -check-prefix=FORCE-OMIT %s
// FORCE-OMIT: "-mframe-pointer=none"

