add_llvm_component_group(V850)

set(LLVM_TARGET_DEFINITIONS V850.td)

tablegen(LLVM V850GenAsmMatcher.inc -gen-asm-matcher)
tablegen(LLVM V850GenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM V850GenCallingConv.inc -gen-callingconv)
tablegen(LLVM V850GenDAGISel.inc -gen-dag-isel)
tablegen(LLVM V850GenDisassemblerTables.inc -gen-disassembler)
tablegen(LLVM V850GenInstrInfo.inc -gen-instr-info)
tablegen(LLVM V850GenMCCodeEmitter.inc -gen-emitter)
tablegen(LLVM V850GenRegisterInfo.inc -gen-register-info)
tablegen(LLVM V850GenSearchableTables.inc -gen-searchable-tables)
tablegen(LLVM V850GenSubtargetInfo.inc -gen-subtarget)

add_public_tablegen_target(V850CommonTableGen)

add_llvm_target(V850CodeGen
  V850AsmPrinter.cpp
  V850FrameLowering.cpp
  V850InstrInfo.cpp
  V850ISelDAGToDAG.cpp
  V850ISelLowering.cpp
  V850LoadStoreOptimizer.cpp
  V850MCInstLower.cpp
  V850PeepholeOptimizer.cpp
  V850RegisterInfo.cpp
  V850Subtarget.cpp
  V850TargetMachine.cpp
  V850TargetObjectFile.cpp

  LINK_COMPONENTS
  Analysis
  AsmPrinter
  CodeGen
  CodeGenTypes
  Core
  GlobalISel
  MC
  SelectionDAG
  Support
  Target
  TargetParser
  TransformUtils
  V850Desc
  V850Info

  ADD_TO_COMPONENT
  V850
  )

add_subdirectory(AsmParser)
add_subdirectory(Disassembler)
add_subdirectory(MCTargetDesc)
add_subdirectory(TargetInfo)
