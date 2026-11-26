# The portable call logic of the desktop platforms (Linux and Windows): plain
# C++17 on the desktop core. Each platform plugin includes this file through a
# relative path, compiles AWN_CALLS_SOURCES and adds AWN_CALLS_INCLUDE_DIR; the
# core headers come with the core plugin target it links.

set(AWN_CALLS_DIR "${CMAKE_CURRENT_LIST_DIR}")
set(AWN_CALLS_INCLUDE_DIR "${AWN_CALLS_DIR}/include")
set(AWN_CALLS_SOURCES
  "${AWN_CALLS_DIR}/src/calls.cpp"
)
