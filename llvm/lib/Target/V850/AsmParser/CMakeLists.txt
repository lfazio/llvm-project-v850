add_llvm_component_library(LLVMV850AsmParser
  V850AsmParser.cpp

  LINK_COMPONENTS
  MC
  MCParser
  Support
  TargetParser
  V850Desc
  V850Info

  ADD_TO_COMPONENT
  V850
  )
