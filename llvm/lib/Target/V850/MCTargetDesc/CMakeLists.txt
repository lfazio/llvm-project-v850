add_llvm_component_library(LLVMV850Desc
  V850MCAsmInfo.cpp
  V850MCTargetDesc.cpp

  LINK_COMPONENTS
  MC
  Support
  V850Info

  ADD_TO_COMPONENT
  V850
  )
