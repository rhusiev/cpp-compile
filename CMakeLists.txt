cmake_minimum_required(VERSION 3.15)

# Pipeline
set(PROJECT executable_name)
set(ENABLE_PVS_STUDIO OFF)
set(ENABLE_UBSan OFF)
set(ENABLE_ASAN OFF)
set(ENABLE_TSan OFF)
set(ENABLE_MSAN OFF)
##set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=*")


#! Check every comment after the "#!"

project(${PROJECT} C CXX) # project(${PROJECT} C CXX ASM)
set(CMAKE_CXX_STANDARD 20)

set(WARNINGS_AS_ERRORS OFF)

if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif ()

include(cmake/CompilerWarnings.cmake)

#! Export compile_commands.json for lsps
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

#! Project main executable source compilation
add_executable(${PROJECT} main.cpp
        myprogram.cpp myprogram.hpp)

#! Put path to your project headers
target_include_directories(${PROJECT} PRIVATE include)

#! Add external packages
# options_parser requires boost::program_options library
# find_package(Boost 1.71.0 COMPONENTS program_options system REQUIRED)
# target_include_directories(${PROJECT} PRIVATE ${Boost_INCLUDE_DIR})
# target_link_libraries(${PROJECT} Boost::program_options Boost::system)

##########################################################
# Fixed CMakeLists.txt part
##########################################################

INSTALL(PROGRAMS
    $<TARGET_FILE:${PROJECT}> # ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}
        DESTINATION bin)

# Define ALL_TARGETS variable to use in PVS and Sanitizers
set(ALL_TARGETS ${PROJECT})

# Include CMake setup
include(cmake/main-config.cmake)
