find_program(LOWDOWN_EXECUTABLE lowdown QUIET)
if(LOWDOWN_EXECUTABLE)
  add_custom_target(
    btop.1 ALL
    COMMAND lowdown -s -Tman -o ${CMAKE_CURRENT_BINARY_DIR}/btop.1 manpage.md
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
  )
  install(FILES btop.1 DESTINATION "${MANDIR}/man1")
endif()
