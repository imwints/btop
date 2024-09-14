# SPDX-License-Identifier: Apache-2.0

add_executable(
  btop
  btop.cpp
  btop_config.cpp
  btop_draw.cpp
  btop_input.cpp
  btop_menu.cpp
  btop_shared.cpp
  btop_theme.cpp
  btop_tools.cpp
)

if(APPLE)
  target_sources(btop PRIVATE osx/btop_collect.cpp osx/sensors.cpp osx/smc.cpp)
elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
  target_sources(btop PRIVATE freebsd/btop_collect.cpp)
elseif(CMAKE_SYSTEM_NAME STREQUAL "OpenBSD")
  target_sources(btop PRIVATE openbsd/btop_collect.cpp)
elseif(CMAKE_SYSTEM_NAME STREQUAL "NetBSD")
  target_sources(btop PRIVATE netbsd/btop_collect.cpp)
elseif(LINUX)
  target_sources(btop PRIVATE linux/btop_collect.cpp)
else()
  message(FATAL_ERROR "${CMAKE_SYSTEM_NAME} is unsupported")
endif()

check_include_file_cxx(ranges CXX_HAVE_RANGES)
if(NOT CXX_HAVE_RANGES)
  message(FATAL_ERROR "The compiler doesn't support <ranges>")
endif()

# Flags
set_target_properties(
  btop
  PROPERTIES CXX_STANDARD 20
             CXX_STANDARD_REQUIRED ON
             CXX_EXTENSIONS OFF
)

add_cxx_flags_if_supported(
  btop
  -Wall
  -Wextra
  -Wpedantic
  -ftree-vectorize
  -fstack-clash-protection
  -fstack-protector
  -fcf-protection
)

check_type_size(off_t SIZEOF_OFF_T LANGUAGE CXX)
if(SIZEOF_OFF_T LESS 8)
  target_compile_definitions(btop PRIVATE _FILE_OFFSET_BITS=64)
endif()

target_compile_definitions(btop PRIVATE "$<$<AND:$<NOT:$<CONFIG:Debug>>,$<BOOL:${BTOP_FORTIFY}>>:_FORTIFY_SOURCE=3>")

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
target_link_libraries(btop Threads::Threads)

target_include_directories(btop SYSTEM PRIVATE ${PROJECT_SOURCE_DIR}/include)
target_compile_definitions(btop PRIVATE FMT_HEADER_ONLY)

if(BTOP_ENABLE_LTO)
  check_ipo_supported(RESULT ipo_supported)
  if(ipo_supported)
    set_target_properties(btop PROPERTIES INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
  endif()
endif()

if(BTOP_STATIC)
  set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
  target_compile_definitions(btop PRIVATE STATIC_BUILD)

  if(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
    find_package(elf REQUIRED)
    target_link_libraries(btop elf::elf)

    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
      # The gcc compiler wrapper doesn't add '--eh-frame-hdr' on FreeBSD
      # https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=278551
      target_link_options(btop PRIVATE LINKER:--eh-frame-hdr)
    endif()
  endif()
endif()

if(BTOP_ENABLE_WERROR)
  add_cxx_flags_if_supported(btop -Werror)
endif()

if(BTOP_ENABLE_GPU)
  target_compile_definitions(btop PRIVATE GPU_SUPPORT)
  if(BTOP_ENABLE_STATIC_RSMI)
    add_bundled_rocm()
    target_link_libraries(btop PRIVATE rocm::rocm)
  endif()
endif()

if(APPLE)
  target_link_libraries(btop PRIVATE $<LINK_LIBRARY:FRAMEWORK,CoreFoundation> $<LINK_LIBRARY:FRAMEWORK,IOKit>)
endif()

if(BSD)
  find_package(kvm REQUIRED)
  target_link_libraries(btop PRIVATE kvm::kvm)

  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_cxx_flags_if_supported(btop -static-libstdc++)
    if(NOT CXX_SUPPORTS_STATIC_LIBSTDCXX_FLAG)
      message(SEND_ERROR "Compiler doesn't support '-static-libstdc++' flag")
    endif()
  endif()
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
  find_package(devstat REQUIRED)
  target_link_libraries(btop devstat::devstat)

  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    # On FreeBSD, all GCC versions will link to the same libstdc++. Find the major version and make it's own libstdc++
    # available before the system one.
    string(REGEX MATCH "^[1-9][0-9]*" GCC_VERSION_MAJOR "${CMAKE_CXX_COMPILER_VERSION}")
    set_target_properties(
      btop PROPERTIES INSTALL_RPATH "/usr/local/lib/gcc${GCC_VERSION_MAJOR}" BUILD_WITH_INSTALL_RPATH TRUE
    )
  endif()
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "NetBSD")
  find_package(proplib REQUIRED)
  target_link_libraries(btop proplib::proplib)
endif()

include(BuildInfo)
include(Manpage)

install(TARGETS btop RUNTIME)
