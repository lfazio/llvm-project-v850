add_lldb_library(lldbPluginArchitectureV850 PLUGIN
  ArchitectureV850.cpp

  LINK_COMPONENTS
    Support
  LINK_LIBS
    lldbCore
    lldbTarget
    lldbUtility
  )
