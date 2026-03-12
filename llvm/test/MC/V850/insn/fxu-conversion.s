// RUN: llvm-mc -triple=v850 -mcpu=g4mh -show-encoding %s | FileCheck %s

// FXU Conversion and Rounding Instructions (RH850G4MH)

// ROUNDF.SW4 - Round to signed int
// CHECK: roundf.sw4 wreg2, wreg4 ; encoding: [0xe0,0x17,0xa0,0x25]
roundf.sw4 wreg2, wreg4

// ROUNDF.SUW4 - Round to unsigned int
// CHECK: roundf.suw4 wreg4, wreg6 ; encoding: [0xe1,0x27,0xa0,0x35]
roundf.suw4 wreg4, wreg6

// TRNCF.SW4 - Truncate to signed int
// CHECK: trncf.sw4 wreg6, wreg8 ; encoding: [0xe2,0x37,0xa0,0x45]
trncf.sw4 wreg6, wreg8

// TRNCF.SUW4 - Truncate to unsigned int
// CHECK: trncf.suw4 wreg8, wreg10 ; encoding: [0xe3,0x47,0xa0,0x55]
trncf.suw4 wreg8, wreg10

// CEILF.SW4 - Ceiling to signed int
// CHECK: ceilf.sw4 wreg2, wreg4 ; encoding: [0xe4,0x17,0xa0,0x25]
ceilf.sw4 wreg2, wreg4

// CEILF.SUW4 - Ceiling to unsigned int
// CHECK: ceilf.suw4 wreg4, wreg6 ; encoding: [0xe5,0x27,0xa0,0x35]
ceilf.suw4 wreg4, wreg6

// FLOORF.SW4 - Floor to signed int
// CHECK: floorf.sw4 wreg6, wreg8 ; encoding: [0xe6,0x37,0xa0,0x45]
floorf.sw4 wreg6, wreg8

// FLOORF.SUW4 - Floor to unsigned int
// CHECK: floorf.suw4 wreg8, wreg10 ; encoding: [0xe7,0x47,0xa0,0x55]
floorf.suw4 wreg8, wreg10

// CVTF.SW4 - Float to signed int
// CHECK: cvtf.sw4 wreg2, wreg4 ; encoding: [0xe8,0x17,0xa0,0x25]
cvtf.sw4 wreg2, wreg4

// CVTF.SUW4 - Float to unsigned int
// CHECK: cvtf.suw4 wreg4, wreg6 ; encoding: [0xe9,0x27,0xa0,0x35]
cvtf.suw4 wreg4, wreg6

// CVTF.WS4 - Signed int to float
// CHECK: cvtf.ws4 wreg6, wreg8 ; encoding: [0xea,0x37,0xa0,0x45]
cvtf.ws4 wreg6, wreg8

// CVTF.UWS4 - Unsigned int to float
// CHECK: cvtf.uws4 wreg8, wreg10 ; encoding: [0xeb,0x47,0xa0,0x55]
cvtf.uws4 wreg8, wreg10

// CVTF.HS4 - Half to float
// CHECK: cvtf.hs4 wreg10, wreg12 ; encoding: [0xec,0x57,0xa0,0x65]
cvtf.hs4 wreg10, wreg12

// CVTF.SH4 - Float to half
// CHECK: cvtf.sh4 wreg12, wreg14 ; encoding: [0xed,0x67,0xa0,0x75]
cvtf.sh4 wreg12, wreg14
