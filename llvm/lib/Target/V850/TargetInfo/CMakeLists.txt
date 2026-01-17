add_llvm_component_library(LLVMV850Info
  V850TargetInfo.cpp

  LINK_COMPONENTS
  MC
  Support

  ADD_TO_COMPONENT
  V850
  )
