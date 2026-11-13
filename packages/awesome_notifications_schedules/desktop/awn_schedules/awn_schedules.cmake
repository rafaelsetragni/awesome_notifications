# The portable desktop scheduling decorator (Windows + Linux). Platform plugins
# include this file and compile AWN_SCHEDULES_SOURCES; they get the core
# headers by linking the core plugin target.

set(AWN_SCHEDULES_DIR "${CMAKE_CURRENT_LIST_DIR}")
set(AWN_SCHEDULES_INCLUDE_DIR "${AWN_SCHEDULES_DIR}/include")
set(AWN_SCHEDULES_SOURCES
  "${AWN_SCHEDULES_DIR}/src/schedule_math.cpp"
  "${AWN_SCHEDULES_DIR}/src/schedules.cpp"
)
