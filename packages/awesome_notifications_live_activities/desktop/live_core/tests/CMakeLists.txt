# Standalone unit tests of the desktop live activity logic, portable C++17, built against
# the desktop core sources (monorepo layout: the core package is a sibling).
# No Flutter, GLib or Windows needed.
#   cmake -S desktop/live_core/tests -B build/awn_live_tests
#   cmake --build build/awn_live_tests --config Debug
#   ctest --test-dir build/awn_live_tests -C Debug --output-on-failure
cmake_minimum_required(VERSION 3.14)
project(awn_live_tests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(AWN_LIVE_PACKAGE "${CMAKE_CURRENT_SOURCE_DIR}/../../..")
set(AWN_CORE_PACKAGE "${AWN_LIVE_PACKAGE}/../awesome_notifications")
include("${AWN_CORE_PACKAGE}/desktop/awn_core/awn_core.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/../awn_live.cmake")

add_executable(awn_live_tests
  ${AWN_CORE_SOURCES}
  ${AWN_LIVE_SOURCES}
  live_tests.cpp
)
target_include_directories(awn_live_tests PRIVATE
  "${AWN_CORE_INCLUDE_DIR}"
  "${AWN_CORE_DIR}/tests"
  "${AWN_LIVE_INCLUDE_DIR}")
if(MSVC)
  target_compile_options(awn_live_tests PRIVATE /W4 /WX /wd4100 /wd4251 /utf-8 /EHsc)
else()
  target_compile_options(awn_live_tests PRIVATE -Wall -Wextra -Werror)
endif()

enable_testing()
add_test(NAME awn_live_tests COMMAND awn_live_tests)
