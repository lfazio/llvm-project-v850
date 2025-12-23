add_llvm_component_library(LLVMV850Disassembler
  V850Disassembler.cpp

  LINK_COMPONENTS
  MC
  MCDisassembler
  V850Desc
  V850Info
  Support

  ADD_TO_COMPONENT
  V850
  )
