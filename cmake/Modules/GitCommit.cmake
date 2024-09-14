function(get_commit_hash output)
  execute_process(
    COMMAND "git" "rev-parse" "--short" "HEAD"
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    OUTPUT_VARIABLE ${output}
    OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET
  )
endfunction()
