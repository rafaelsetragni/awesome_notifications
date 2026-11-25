# The platform-independent part of the Windows media session (plain C++17 on
# the desktop core). The plugin compiles AWN_MEDIA_SOURCES; it gets the core
# headers by linking the core plugin target.

set(AWN_MEDIA_DIR "${CMAKE_CURRENT_LIST_DIR}")
set(AWN_MEDIA_INCLUDE_DIR "${AWN_MEDIA_DIR}/include")
set(AWN_MEDIA_SOURCES
  "${AWN_MEDIA_DIR}/src/media.cpp"
)
