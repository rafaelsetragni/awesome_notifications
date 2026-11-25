# Standalone unit tests of the platform-independent media session (no Flutter,
# no Windows needed), built against the core sources (monorepo layout: the core
# package is a sibling).
#   cmake -S windows/test -B build/awn_media_tests
#   cmake --build build/awn_media_tests --config Debug
#   ctest --test-dir build/awn_media_tests -C Debug --output-on-failure
cmake_minimum_required(VERSION 3.14)
project(awn_media_tests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(AWN_CORE_PACKAGE "${CMAKE_CURRENT_SOURCE_DIR}/../../../awesome_notifications")
include("${AWN_CORE_PACKAGE}/desktop/awn_core/awn_core.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/../media_core/awn_media.cmake")

add_executable(awn_media_tests
  ${AWN_CORE_SOURCES}
  ${AWN_MEDIA_SOURCES}
  media_tests.cpp
)
target_include_directories(awn_media_tests PRIVATE
  "${AWN_CORE_INCLUDE_DIR}"
  "${AWN_CORE_DIR}/tests"
  "${AWN_MEDIA_INCLUDE_DIR}")
if(MSVC)
  target_compile_options(awn_media_tests PRIVATE /W4 /WX /wd4100 /wd4251 /utf-8 /EHsc)
else()
  target_compile_options(awn_media_tests PRIVATE -Wall -Wextra -Werror)
endif()

enable_testing()
add_test(NAME awn_media_tests COMMAND awn_media_tests)
