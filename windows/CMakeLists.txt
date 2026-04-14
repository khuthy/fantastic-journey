cmake_minimum_required(VERSION 3.14)
project(protea_glen_gate LANGUAGES CXX)

set(BINARY_NAME "protea_glen_gate")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Configure build options
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /SUBSYSTEM:WINDOWS")

add_subdirectory(flutter)
add_subdirectory(runner)

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)
