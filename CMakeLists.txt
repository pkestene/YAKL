project(YAKL C CXX Fortran)
cmake_minimum_required(VERSION 3.0)

if ("${YAKL_ARCH}" STREQUAL "CUDA")
  enable_language(CUDA)
endif()

set(YAKL_CXX_SOURCE src/YAKL.cpp)
set(YAKL_F90_SOURCE src/YAKL_gator_mod.F90)
set(YAKL_SOURCE ${YAKL_CXX_SOURCE} ${YAKL_F90_SOURCE})

if ("${YAKL_ARCH}" STREQUAL "CUDA")
  message(STATUS "** Building YAKL for a CUDA backend **")
elseif ("${YAKL_ARCH}" STREQUAL "HIP")
  message(STATUS "** Building YAKL for a HIP backend **")
elseif ("${YAKL_ARCH}" STREQUAL "OPENMP")
  message(STATUS "** Building YAKL for a CPU OPENMP threading backend **")
elseif ("${YAKL_ARCH}" STREQUAL "OPENMP45")
  message(STATUS "** Building YAKL for an OPENMP offload backend **")
elseif ("${YAKL_ARCH}" STREQUAL "SYCL")
  message(STATUS "** Building YAKL for an SYCL offload backend **")
elseif ("${YAKL_ARCH}" STREQUAL "")
  message(STATUS "** YAKL_ARCH not set. Building YAKL for a serial CPU backend **")
else()
  message(FATAL_ERROR "** YAKL_ARCH set to an invalid backend target: ${YAKL_ARCH} **")
endif()

include(yakl_utils.cmake)

yakl_process_cxx_source_files("${YAKL_CXX_SOURCE}")
message(STATUS "** YAKL is using the following C++ flags: ${YAKL_COMPILER_FLAGS} **")

set_source_files_properties(${YAKL_F90_SOURCE} PROPERTIES COMPILE_FLAGS "${YAKL_F90_FLAGS}")

add_library(yakl STATIC ${YAKL_SOURCE})
set_property(TARGET yakl PROPERTY CXX_STANDARD 17)

target_include_directories(yakl PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/external>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
  $<INSTALL_INTERFACE:include>)

target_include_directories(yakl PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/extensions>
  $<INSTALL_INTERFACE:include/extensions>)

if ("${YAKL_ARCH}" STREQUAL "CUDA")
  set_target_properties(yakl PROPERTIES LINKER_LANGUAGE CUDA CUDA_SEPARABLE_COMPILATION OFF CUDA_RESOLVE_DEVICE_SYMBOLS ON)
  target_link_libraries(yakl)
  if(${CMAKE_VERSION} VERSION_GREATER_EQUAL 3.22.0 )
    message("Using CUDAToolkit macros")
    find_package(CUDAToolkit REQUIRED)
    target_link_libraries(yakl CUDA::cufft)
  else()
    target_link_libraries(yakl cufft)
  endif()
  if (${CMAKE_VERSION} VERSION_GREATER_EQUAL 3.18)
    set_property(TARGET yakl PROPERTY CUDA_ARCHITECTURES OFF)
  endif()
endif()

if ("${YAKL_ARCH}" STREQUAL "HIP")
  target_link_libraries(yakl roctx64 rocfft)
endif()

if ("${YAKL_ARCH}" STREQUAL "SYCL")
  target_link_libraries(yakl "${YAKL_COMPILER_FLAGS}")
endif()

if ("${YAKL_ARCH}" STREQUAL "OPENMP45")
  target_link_libraries(yakl "${YAKL_OPENMP45_FLAGS}")
endif()

if ("${YAKL_ARCH}" STREQUAL "OPENMP")
  target_link_libraries(yakl "${YAKL_OPENMP_FLAGS}")
endif()

install(TARGETS yakl)
install(DIRECTORY src/ external/ DESTINATION include FILES_MATCHING PATTERN "*.h")
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/gator_mod.mod DESTINATION include)
install(CODE "file(WRITE ${CMAKE_INSTALL_PREFIX}/yakl_variables.cmake \"set(YAKL_COMPILER_FLAGS \\\"${YAKL_COMPILER_FLAGS}\\\")\nset(YAKL_ARCH \\\"${YAKL_ARCH}\\\")\n\")" )
install(CODE "file(WRITE ${CMAKE_INSTALL_PREFIX}/yakl_variables.make \"YAKL_COMPILER_FLAGS := ${YAKL_COMPILER_FLAGS}\nYAKL_ARCH := ${YAKL_ARCH}\n\")" )
