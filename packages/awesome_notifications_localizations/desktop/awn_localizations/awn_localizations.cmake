# The portable desktop localization decorator (Windows + Linux). Platform
# plugins include this file and compile AWN_LOCALIZATIONS_SOURCES; they get the
# core headers by linking the core plugin target.

set(AWN_LOCALIZATIONS_DIR "${CMAKE_CURRENT_LIST_DIR}")
set(AWN_LOCALIZATIONS_INCLUDE_DIR "${AWN_LOCALIZATIONS_DIR}/include")
set(AWN_LOCALIZATIONS_SOURCES
  "${AWN_LOCALIZATIONS_DIR}/src/localizations.cpp"
)
