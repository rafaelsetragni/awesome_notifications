# Standalone unit tests of the desktop media logic: the shared library and the
# MPRIS (linux/) and SMTC (windows/) mappings, all portable C++17, built against
# the desktop core sources (monorepo layout: the core package is a sibling).
# No Flutter, GLib or Windows needed.
#   cmake -S desktop/media_core/tests -B build/awn_media_tests
#   cmake --build build/awn_media_tests --config Debug
#   ctest --test-dir build/awn_media_tests -C Debug --output-on-failure
cmake_minimum_required(VERSION 3.14)
project(awn_media_tests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(AWN_MEDIA_PACKAGE "${CMAKE_CURRENT_SOURCE_DIR}/../../..")
set(AWN_CORE_PACKAGE "${AWN_MEDIA_PACKAGE}/../awesome_notifications")
include("${AWN_CORE_PACKAGE}/desktop/awn_core/awn_core.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/../awn_media.cmake")

add_executable(awn_media_tests
  ${AWN_CORE_SOURCES}
  ${AWN_MEDIA_SOURCES}
  "${AWN_MEDIA_PACKAGE}/linux/src/mpris_mapping.cc"
  "${AWN_MEDIA_PACKAGE}/windows/smtc_mapping.cpp"
  media_tests.cpp
)
target_include_directories(awn_media_tests PRIVATE
  "${AWN_CORE_INCLUDE_DIR}"
  "${AWN_CORE_DIR}/tests"
  "${AWN_MEDIA_INCLUDE_DIR}"
  "${AWN_MEDIA_PACKAGE}/linux/src"
  "${AWN_MEDIA_PACKAGE}/windows")
if(MSVC)
  target_compile_options(awn_media_tests PRIVATE /W4 /WX /wd4100 /wd4251 /utf-8 /EHsc)
else()
  target_compile_options(awn_media_tests PRIVATE -Wall -Wextra -Werror)
endif()

enable_testing()
add_test(NAME awn_media_tests COMMAND awn_media_tests)
