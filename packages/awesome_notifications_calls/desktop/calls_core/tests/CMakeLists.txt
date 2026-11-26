# Standalone unit tests of the desktop call logic, portable C++17, built against
# the desktop core sources (monorepo layout: the core package is a sibling).
# No Flutter, GLib or Windows needed.
#   cmake -S desktop/calls_core/tests -B build/awn_calls_tests
#   cmake --build build/awn_calls_tests --config Debug
#   ctest --test-dir build/awn_calls_tests -C Debug --output-on-failure
cmake_minimum_required(VERSION 3.14)
project(awn_calls_tests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(AWN_CALLS_PACKAGE "${CMAKE_CURRENT_SOURCE_DIR}/../../..")
set(AWN_CORE_PACKAGE "${AWN_CALLS_PACKAGE}/../awesome_notifications")
include("${AWN_CORE_PACKAGE}/desktop/awn_core/awn_core.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/../awn_calls.cmake")

add_executable(awn_calls_tests
  ${AWN_CORE_SOURCES}
  ${AWN_CALLS_SOURCES}
  calls_tests.cpp
)
target_include_directories(awn_calls_tests PRIVATE
  "${AWN_CORE_INCLUDE_DIR}"
  "${AWN_CORE_DIR}/tests"
  "${AWN_CALLS_INCLUDE_DIR}")
if(MSVC)
  target_compile_options(awn_calls_tests PRIVATE /W4 /WX /wd4100 /wd4251 /utf-8 /EHsc)
else()
  target_compile_options(awn_calls_tests PRIVATE -Wall -Wextra -Werror)
endif()

enable_testing()
add_test(NAME awn_calls_tests COMMAND awn_calls_tests)
