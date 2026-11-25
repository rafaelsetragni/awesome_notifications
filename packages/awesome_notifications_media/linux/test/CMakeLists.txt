# Standalone unit tests of the portable media logic (src/media_model.*), built
# against the desktop core sources (monorepo layout: the core package is a
# sibling).
#   cmake -S linux/test -B build/awn_media_tests
#   cmake --build build/awn_media_tests
#   ctest --test-dir build/awn_media_tests --output-on-failure
cmake_minimum_required(VERSION 3.14)
project(awn_media_tests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(AWN_CORE_PACKAGE "${CMAKE_CURRENT_SOURCE_DIR}/../../../awesome_notifications")
include("${AWN_CORE_PACKAGE}/desktop/awn_core/awn_core.cmake")

add_executable(awn_media_tests
  ${AWN_CORE_SOURCES}
  "${CMAKE_CURRENT_SOURCE_DIR}/../src/media_model.cc"
  media_tests.cpp
)
target_include_directories(awn_media_tests PRIVATE
  "${AWN_CORE_INCLUDE_DIR}"
  "${AWN_CORE_DIR}/tests"
  "${CMAKE_CURRENT_SOURCE_DIR}/../src")
target_compile_options(awn_media_tests PRIVATE -Wall -Wextra -Werror)

enable_testing()
add_test(NAME awn_media_tests COMMAND awn_media_tests)
