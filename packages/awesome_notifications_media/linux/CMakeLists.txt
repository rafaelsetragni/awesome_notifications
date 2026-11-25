# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "awesome_notifications_media")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "awesome_notifications_media_plugin")

# The portable media logic shared with Windows (unit-tested in
# desktop/media_core/tests, with the MPRIS mapping of src/mpris_mapping.*).
include("${CMAKE_CURRENT_SOURCE_DIR}/../desktop/media_core/awn_media.cmake")

list(APPEND PLUGIN_SOURCES
  "awesome_notifications_media_plugin.cc"
  "src/mpris_mapping.cc"
  "src/mpris_player.cc"
  ${AWN_MEDIA_SOURCES}
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
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

# Linking the core plugin target brings the core headers and its registries
# (AWN_USING_CORE); the core library is found next to this one when bundled.
# MPRIS goes through GDBus (GIO, part of GTK's dependencies); libcurl, for
# https artwork, is loaded at run time (dlopen).
target_include_directories(${PLUGIN_NAME}
  INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}" "${AWN_MEDIA_INCLUDE_DIR}")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter awesome_notifications_plugin)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK ${CMAKE_DL_LIBS})
set_target_properties(${PLUGIN_NAME} PROPERTIES INSTALL_RPATH "$ORIGIN")

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(awesome_notifications_media_bundled_libraries
  ""
  PARENT_SCOPE
)

# Unit tests of the portable media logic (no Flutter, GLib or D-Bus) are a
# standalone build: see ../desktop/media_core/tests/CMakeLists.txt.
