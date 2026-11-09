cmake_minimum_required(VERSION 3.25)
project(orbslam3 VERSION 0.1.15 DESCRIPTION "Python bindings for ORB-SLAM3 with dense reconstruction support" LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

option(ORB_SLAM3_DENSE_RECONSTRUCTION "Enable the PCL/OctoMap dense reconstruction backend" ON)
option(ORB_SLAM3_USE_CCACHE "Use ccache when available" ON)

if(ORB_SLAM3_USE_CCACHE)
  find_program(ORB_SLAM3_CCACHE ccache)
  if(ORB_SLAM3_CCACHE)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${ORB_SLAM3_CCACHE}")
  endif()
endif()

find_package(Python REQUIRED COMPONENTS Interpreter Development.Module)
find_package(pybind11 CONFIG REQUIRED)
include(cmake/orbslam3.cmake)
add_subdirectory(src/orbslam3/python_wrapper)
