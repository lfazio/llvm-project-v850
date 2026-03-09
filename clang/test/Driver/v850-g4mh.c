// Check RH850G4MH/G4MH2 driver support

// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=g4mh | FileCheck -check-prefix=G4MH %s
// G4MH: "-target-feature" "+v850fpu"
// G4MH: "-target-cpu" "g4mh"

// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=g4mh2 | FileCheck -check-prefix=G4MH2 %s
// G4MH2: "-target-feature" "+v850fpu"
// G4MH2: "-target-cpu" "g4mh2"

// Verify FPU can be disabled explicitly
// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=g4mh -mno-v850-fpu | FileCheck -check-prefix=G4MH-NOFPU %s
// G4MH-NOFPU: "-target-feature" "-v850fpu"
// G4MH-NOFPU: "-target-cpu" "g4mh"
