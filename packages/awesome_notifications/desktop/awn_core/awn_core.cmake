# The portable desktop core (Windows + Linux): a Flutter-free C++17 engine.
# Platform plugins include this file and compile AWN_CORE_SOURCES into their
# shared library, so every decorator plugin links the same registries.

set(AWN_CORE_DIR "${CMAKE_CURRENT_LIST_DIR}")
set(AWN_CORE_INCLUDE_DIR "${AWN_CORE_DIR}/include")
set(AWN_CORE_SOURCES
  "${AWN_CORE_DIR}/src/awesome_notifications.cpp"
  "${AWN_CORE_DIR}/src/date_utils.cpp"
  "${AWN_CORE_DIR}/src/displayed_tracker.cpp"
  "${AWN_CORE_DIR}/src/json.cpp"
  "${AWN_CORE_DIR}/src/launch_args.cpp"
  "${AWN_CORE_DIR}/src/method_router.cpp"
  "${AWN_CORE_DIR}/src/notification_builder.cpp"
  "${AWN_CORE_DIR}/src/notification_store.cpp"
  "${AWN_CORE_DIR}/src/registries.cpp"
  "${AWN_CORE_DIR}/src/toast_xml.cpp"
  "${AWN_CORE_DIR}/src/value.cpp"
)
