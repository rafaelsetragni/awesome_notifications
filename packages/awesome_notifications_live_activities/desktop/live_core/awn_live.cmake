# The portable live activity logic of the desktop platforms (Linux and
# Windows): plain C++17 on the desktop core. Each platform plugin includes this
# file through a relative path, compiles AWN_LIVE_SOURCES and adds
# AWN_LIVE_INCLUDE_DIR; the core headers come with the core plugin target it
# links.

set(AWN_LIVE_DIR "${CMAKE_CURRENT_LIST_DIR}")
set(AWN_LIVE_INCLUDE_DIR "${AWN_LIVE_DIR}/include")
set(AWN_LIVE_SOURCES
  "${AWN_LIVE_DIR}/src/live.cpp"
)
