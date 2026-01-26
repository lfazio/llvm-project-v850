add_lldb_library(lldbPluginABIV850 PLUGIN
  ABISysV_v850.cpp

  LINK_COMPONENTS
    Support
    TargetParser
  LINK_LIBS
    lldbCore
    lldbSymbol
    lldbTarget
    lldbValueObject
  )
