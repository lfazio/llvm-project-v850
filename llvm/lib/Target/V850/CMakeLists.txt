add_llvm_component_group(V850)

set(LLVM_TARGET_DEFINITIONS V850.td)

tablegen(LLVM V850GenAsmMatcher.inc -gen-asm-matcher)
tablegen(LLVM V850GenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM V850GenDisassemblerTables.inc -gen-disassembler)
tablegen(LLVM V850GenInstrInfo.inc -gen-instr-info)
tablegen(LLVM V850GenMCCodeEmitter.inc -gen-emitter)
tablegen(LLVM V850GenRegisterInfo.inc -gen-register-info)
tablegen(LLVM V850GenSubtargetInfo.inc -gen-subtarget)

add_public_tablegen_target(V850CommonTableGen)

add_llvm_target(V850CodeGen
  V850TargetMachine.cpp

  LINK_COMPONENTS
  CodeGen
  CodeGenTypes
  Core
  MC
  Support
  Target
  TargetParser
  V850Desc
  V850Info

  ADD_TO_COMPONENT
  V850
  )

add_subdirectory(AsmParser)
add_subdirectory(Disassembler)
add_subdirectory(MCTargetDesc)
add_subdirectory(TargetInfo)
