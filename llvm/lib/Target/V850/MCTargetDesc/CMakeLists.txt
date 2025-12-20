add_llvm_component_library(LLVMV850Desc
  V850AsmBackend.cpp
  V850ELFObjectWriter.cpp
  V850InstPrinter.cpp
  V850MCAsmInfo.cpp
  V850MCCodeEmitter.cpp
  V850MCTargetDesc.cpp

  LINK_COMPONENTS
  MC
  MCDisassembler
  Support
  TargetParser
  V850Info

  ADD_TO_COMPONENT
  V850
  )
