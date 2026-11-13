# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "awesome_notifications_schedules")
project(${PROJECT_NAME} LANGUAGES CXX)

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "awesome_notifications_schedules_plugin")

# The portable scheduling decorator (shared with Linux).
include("${CMAKE_CURRENT_SOURCE_DIR}/../desktop/awn_schedules/awn_schedules.cmake")

list(APPEND PLUGIN_SOURCES
  "awesome_notifications_schedules_plugin.cpp"
  "awesome_notifications_schedules_plugin.h"
  ${AWN_SCHEDULES_SOURCES}
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  "include/awesome_notifications_schedules/awesome_notifications_schedules_plugin_c_api.h"
  "awesome_notifications_schedules_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Linking the core plugin
# target brings the core headers and imports its registries (AWN_USING_CORE).
target_include_directories(${PLUGIN_NAME}
  INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include"
  PRIVATE "${AWN_SCHEDULES_INCLUDE_DIR}")
target_link_libraries(${PLUGIN_NAME}
  PRIVATE flutter flutter_wrapper_plugin awesome_notifications_plugin)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(awesome_notifications_schedules_bundled_libraries
  ""
  PARENT_SCOPE
)
