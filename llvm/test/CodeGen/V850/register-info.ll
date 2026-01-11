; RUN: llvm-tblgen --gen-register-info -I %p/../../../lib/Target/V850 \
; RUN:     -I %p/../../../include %p/../../../lib/Target/V850/V850.td \
; RUN:     | FileCheck %s

; Test that V850 register definitions are correctly generated.

; Check register descriptors are defined
; CHECK: extern const MCRegisterDesc V850RegDesc[]

; Check register classes exist
; CHECK: // SysReg Register Class
; CHECK: // FPR Register Class
; CHECK: // GPR Register Class
; CHECK: // GPRnoR0 Register Class

; Check DWARF register mappings are generated
; CHECK: V850 Dwarf<->LLVM register mappings
; CHECK: V850DwarfFlavour0Dwarf2L
; CHECK: V850DwarfFlavour0L2Dwarf

; Check InitV850MCRegisterInfo function maps DWARF registers
; CHECK: InitV850MCRegisterInfo
; CHECK: mapDwarfRegsToLLVMRegs
; CHECK: mapLLVMRegsToDwarfRegs

; Check CostPerUse table is generated (special registers have cost 1)
; CHECK: static const uint8_t CostPerUseTable[]
