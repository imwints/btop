function(add_bundled_rocm)
  add_library(${PROJECT_SOURCE_DIR}/lib/rocm_smi_lib EXCLUDE_FROM_ALL SYSTEM)

  add_library(rocm::rocm INTERFACE)
  target_compile_definitions(rocm::rocm INTERFACE RSMI_STATIC)
  target_include_directories(rocm::rocm INTERFACE ${PROJECT_SOURCE_DIR}/lib/rocm_smi_lib/include)
  target_link_libraries(rocm::rocm INTERFACE rocm_smi64)
endfunction()
