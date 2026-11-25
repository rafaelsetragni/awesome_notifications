# The portable media logic of the desktop platforms (Linux and Windows): plain
# C++17 on the desktop core. Each platform plugin includes this file through a
# relative path, compiles AWN_MEDIA_SOURCES and adds AWN_MEDIA_INCLUDE_DIR; the
# core headers come with the core plugin target it links.

set(AWN_MEDIA_DIR "${CMAKE_CURRENT_LIST_DIR}")
set(AWN_MEDIA_INCLUDE_DIR "${AWN_MEDIA_DIR}/include")
set(AWN_MEDIA_SOURCES
  "${AWN_MEDIA_DIR}/src/media.cpp"
)
