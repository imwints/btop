# SPDX-License-Identifier: Apache-2.0
#
# CMake configuration for btop
#

cmake_minimum_required(VERSION 3.25)

# Require builds in dedicated build directory to preserve btop's Makefile
if("${CMAKE_CURRENT_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_BINARY_DIR}")
  message(FATAL_ERROR "In-source builds are not allowed")
endif()

project(
  btop
  DESCRIPTION "A monitor of resources"
  HOMEPAGE_URL "https://github.com/aristocratos/btop"
  LANGUAGES CXX
)

set(CMAKE_COLOR_DIAGNOSTICS ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules/")

include(CMakeDependentOption)
include(CheckIPOSupported)
include(CheckIPOSupported)
include(CheckIncludeFileCXX)
include(CheckTypeSize)
include(GNUInstallDirs)
include(HandleFlags)
include(ROCm)

option(BTOP_FORTIFY "Harden certain libc functions with _FORTIFY_SOURCE=3" ON)
option(BTOP_ENABLE_LTO "Enable compilation with link time optimization" ON)
option(BTOP_ENABLE_WERROR "Enable compilation with -Werror" OFF)

if(NOT APPLE)
  option(BTOP_STATIC "Create a static executable" OFF)
endif()

if(LINUX)
  option(BTOP_ENABLE_GPU "Enable GPU support" ON)
  cmake_dependent_option(
    BTOP_ENABLE_STATIC_RSMI "Build vendored ROCm and statically link it to btop" OFF "BTOP_ENABLE_GPU" OFF
  )
endif()

if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE
      "Release"
      CACHE STRING "" FORCE
  )
endif()

add_subdirectory(src)

install(FILES "btop.desktop" DESTINATION "${DATAROOTDIR}/applications")
install(
  FILES "Img/icon.png"
  DESTINATION "${DATAROOTDIR}/icons/hicolor/48x48/apps"
  RENAME "btop.png"
)
install(
  FILES "Img/icon.svg"
  DESTINATION "${DATAROOTDIR}/icons/hicolor/scalable/apps"
  RENAME "btop.svg"
)
install(DIRECTORY "themes" DESTINATION "${DATAROOTDIR}/btop")
