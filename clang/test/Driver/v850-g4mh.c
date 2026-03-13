// Check RH850G4MH/G4MH2 driver support

// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=g4mh | FileCheck -check-prefix=G4MH %s
// G4MH: "-target-feature" "+v850fpu"
// G4MH: "-target-cpu" "g4mh"

// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=g4mh2 | FileCheck -check-prefix=G4MH2 %s
// G4MH2: "-target-feature" "+v850fpu"
// G4MH2: "-target-cpu" "g4mh2"

// Verify FPU can be disabled explicitly
// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=g4mh -msoft-float | FileCheck -check-prefix=G4MH-NOFPU %s
// G4MH-NOFPU: "-target-feature" "-v850fpu"
// G4MH-NOFPU: "-target-cpu" "g4mh"

// Verify g4mh2 enables virtualization by default
// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=g4mh2 | FileCheck -check-prefix=G4MH2-VIRT %s
// G4MH2-VIRT: "-target-feature" "+rh850g4mh2"
// G4MH2-VIRT: "-target-cpu" "g4mh2"

// Verify -mvirt enables virtualization on g4mh
// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=g4mh -mvirt | FileCheck -check-prefix=G4MH-VIRT %s
// G4MH-VIRT: "-target-feature" "+rh850g4mh2"
// G4MH-VIRT: "-target-cpu" "g4mh"

// Verify -mno-virt disables virtualization on g4mh2
// RUN: %clang --target=v850 -### -c %s 2>&1 -mcpu=g4mh2 -mno-virt | FileCheck -check-prefix=G4MH2-NOVIRT %s
// G4MH2-NOVIRT: "-target-feature" "-rh850g4mh2"
// G4MH2-NOVIRT: "-target-cpu" "g4mh2"
