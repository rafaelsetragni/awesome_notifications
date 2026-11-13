# Standalone unit tests of the portable desktop core (no Flutter needed):
#   cmake -S desktop/awn_core/tests -B build/awn_core_tests
#   cmake --build build/awn_core_tests --config Debug
#   ctest --test-dir build/awn_core_tests -C Debug --output-on-failure
cmake_minimum_required(VERSION 3.14)
project(awn_core_tests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include("${CMAKE_CURRENT_SOURCE_DIR}/../awn_core.cmake")

add_executable(awn_core_tests
  ${AWN_CORE_SOURCES}
  core_tests.cpp
  engine_tests.cpp
)
target_include_directories(awn_core_tests PRIVATE "${AWN_CORE_INCLUDE_DIR}")
if(MSVC)
  # Same strictness as Flutter's plugin builds (apply_standard_settings).
  target_compile_options(awn_core_tests PRIVATE /W4 /WX /wd4100 /wd4251 /utf-8 /EHsc)
else()
  target_compile_options(awn_core_tests PRIVATE -Wall -Wextra -Werror)
endif()

enable_testing()
add_test(NAME awn_core_tests COMMAND awn_core_tests)
