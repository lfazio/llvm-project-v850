add_lldb_library(lldbPluginInstructionV850 PLUGIN
  EmulateInstructionV850.cpp

  LINK_COMPONENTS
    Support
  LINK_LIBS
    lldbCore
    lldbInterpreter
    lldbSymbol
  )
