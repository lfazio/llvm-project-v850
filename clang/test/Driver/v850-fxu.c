// Check V850 FXU (vector unit) options

// g4mh has FXU enabled by default via getV850TargetFeatures()
// RUN: %clang --target=v850 -mcpu=g4mh -### -c %s 2>&1 | FileCheck -check-prefix=FXU-DEFAULT %s
// FXU-DEFAULT: "-target-feature" "+v850fxu"
// FXU-DEFAULT: "-target-cpu" "g4mh"

// g4mh2 also has FXU enabled by default
// RUN: %clang --target=v850 -mcpu=g4mh2 -### -c %s 2>&1 | FileCheck -check-prefix=FXU-G4MH2 %s
// FXU-G4MH2: "-target-feature" "+v850fxu"
// FXU-G4MH2: "-target-cpu" "g4mh2"

// Explicit -mfxu should enable the FXU
// RUN: %clang --target=v850 -mcpu=g4mh -mfxu -### -c %s 2>&1 | FileCheck -check-prefix=FXU-ENABLE %s
// FXU-ENABLE: "-target-feature" "+v850fxu"
// FXU-ENABLE: "-target-cpu" "g4mh"

// Explicit -mno-fxu disables the FXU on g4mh
// RUN: %clang --target=v850 -mcpu=g4mh -mno-fxu -### -c %s 2>&1 | FileCheck -check-prefix=FXU-DISABLE %s
// FXU-DISABLE: "-target-feature" "-v850fxu"
// FXU-DISABLE: "-target-cpu" "g4mh"

// Non-G4MH CPUs have no FXU by default
// RUN: %clang --target=v850 -mcpu=g3mh -### -c %s 2>&1 | FileCheck -check-prefix=FXU-G3MH %s
// FXU-G3MH: "-target-feature" "-v850fxu"
// FXU-G3MH: "-target-cpu" "g3mh"

// RUN: %clang --target=v850 -mcpu=v850e2m -### -c %s 2>&1 | FileCheck -check-prefix=FXU-E2M %s
// FXU-E2M: "-target-feature" "-v850fxu"
// FXU-E2M: "-target-cpu" "v850e2m"

// Explicit -mfxu can force-enable FXU on non-G4MH CPU
// RUN: %clang --target=v850 -mcpu=g3mh -mfxu -### -c %s 2>&1 | FileCheck -check-prefix=FXU-FORCE %s
// FXU-FORCE: "-target-feature" "+v850fxu"
// FXU-FORCE: "-target-cpu" "g3mh"
