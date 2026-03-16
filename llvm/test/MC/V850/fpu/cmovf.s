# RUN: llvm-mc -triple=v850-unknown-elf -mcpu=v850e2m -show-encoding %s | FileCheck %s

# Test CMOVF.S encoding
# CMOVF.S fcbit, reg1, reg2, reg3
# If FPCC[fcbit]==1 then reg3 = reg1, else reg3 = reg2

# CHECK: cmovf.s 0, r6, r7, r10
# CHECK-SAME: encoding: [0xe6,0x3f,0x00,0x54]
cmovf.s 0, r6, r7, r10

# CHECK: cmovf.s 1, r8, r9, r11
# CHECK-SAME: encoding: [0xe8,0x4f,0x02,0x5c]
cmovf.s 1, r8, r9, r11

# CHECK: cmovf.s 7, r10, r11, r12
# CHECK-SAME: encoding: [0xea,0x5f,0x0e,0x64]
cmovf.s 7, r10, r11, r12

# Test CMOVF.D encoding (double-precision, even registers)
# CMOVF.D fcbit, reg1, reg2, reg3

# CHECK: cmovf.d 0, r6, r8, d10
# CHECK-SAME: encoding: [0xe6,0x47,0x10,0x54]
cmovf.d 0, r6, r8, d10

# CHECK: cmovf.d 3, r10, r12, d14
# CHECK-SAME: encoding: [0xea,0x67,0x16,0x74]
cmovf.d 3, r10, r12, d14
