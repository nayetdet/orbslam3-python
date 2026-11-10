include(FetchContent)

set(ORB_SLAM3_GIT_REPOSITORY "https://github.com/nayetdet/ORB_SLAM3.git" CACHE STRING "ORB_SLAM3 source repository")
set(ORB_SLAM3_GIT_TAG "8f8a41b690aa9b6bf2f94e5ba9bd8566e484a5ac" CACHE STRING "Pinned ORB_SLAM3 revision")

FetchContent_Declare(orbslam3_source
  GIT_REPOSITORY "${ORB_SLAM3_GIT_REPOSITORY}"
  GIT_TAG "${ORB_SLAM3_GIT_TAG}")
FetchContent_GetProperties(orbslam3_source)
if(NOT orbslam3_source_POPULATED)
  FetchContent_Populate(orbslam3_source)
endif()

set(ORB_SLAM3_SOURCE_DIR "${orbslam3_source_SOURCE_DIR}")

set(_g2o_cmake "${ORB_SLAM3_SOURCE_DIR}/Thirdparty/g2o/CMakeLists.txt")
file(READ "${_g2o_cmake}" _g2o_contents)
string(REPLACE "FIND_PACKAGE(Eigen3 3.1.0 REQUIRED)" "FIND_PACKAGE(Eigen3 REQUIRED)"
  _g2o_contents "${_g2o_contents}")
file(WRITE "${_g2o_cmake}" "${_g2o_contents}")

file(GLOB_RECURSE _g2o_sources "${ORB_SLAM3_SOURCE_DIR}/Thirdparty/g2o/g2o/*.h"
  "${ORB_SLAM3_SOURCE_DIR}/Thirdparty/g2o/g2o/*.hpp"
  "${ORB_SLAM3_SOURCE_DIR}/Thirdparty/g2o/g2o/*.cpp")
foreach(_source IN LISTS _g2o_sources)
  file(READ "${_source}" _contents)
  string(REPLACE "<tr1/unordered_map>" "<unordered_map>" _contents "${_contents}")
  string(REPLACE "<tr1/unordered_set>" "<unordered_set>" _contents "${_contents}")
  string(REPLACE "<tr1/memory>" "<memory>" _contents "${_contents}")
  string(REPLACE "std::tr1::" "std::" _contents "${_contents}")
  file(WRITE "${_source}" "${_contents}")
endforeach()

set(_dbow2_cmake "${ORB_SLAM3_SOURCE_DIR}/Thirdparty/DBoW2/CMakeLists.txt")
file(READ "${_dbow2_cmake}" _dbow2_contents)
string(REPLACE "find_package(OpenCV 4 QUIET)" "find_package(OpenCV 4.4 REQUIRED)"
  _dbow2_contents "${_dbow2_contents}")
file(WRITE "${_dbow2_cmake}" "${_dbow2_contents}")

set(_dbow2_forb "${ORB_SLAM3_SOURCE_DIR}/Thirdparty/DBoW2/DBoW2/FORB.cpp")
file(READ "${_dbow2_forb}" _dbow2_forb_contents)
string(REPLACE "<stdint-gcc.h>" "<stdint.h>" _dbow2_forb_contents "${_dbow2_forb_contents}")
file(WRITE "${_dbow2_forb}" "${_dbow2_forb_contents}")

set(_orb_matcher "${ORB_SLAM3_SOURCE_DIR}/src/ORBmatcher.cc")
file(READ "${_orb_matcher}" _orb_matcher_contents)
string(REPLACE "<stdint-gcc.h>" "<stdint.h>" _orb_matcher_contents "${_orb_matcher_contents}")
file(WRITE "${_orb_matcher}" "${_orb_matcher_contents}")

find_package(OpenCV 4.4 REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(Pangolin REQUIRED)
find_package(Boost REQUIRED COMPONENTS serialization)
find_package(OpenSSL REQUIRED)

if(MSVC)
  set(_map_point "${ORB_SLAM3_SOURCE_DIR}/src/MapPoint.cc")
  file(READ "${_map_point}" _map_point_contents)
  string(REPLACE "float Distances[N][N];" "vector<vector<float>> Distances(N, vector<float>(N));"
    _map_point_contents "${_map_point_contents}")
  string(REPLACE "vector<int> vDists(Distances[i],Distances[i]+N);"
    "vector<int> vDists(Distances[i].begin(), Distances[i].end());"
    _map_point_contents "${_map_point_contents}")
  file(WRITE "${_map_point}" "${_map_point_contents}")

  set(_windows_compat "${ORB_SLAM3_SOURCE_DIR}/include/WindowsCompat.h")
  file(WRITE "${_windows_compat}" [=[
#pragma once
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
inline int usleep(unsigned int microseconds) { Sleep((microseconds + 999) / 1000); return 0; }
]=])

  set(_windows_unistd_compat [=[
#ifdef _WIN32
#include "WindowsCompat.h"
#else
#include <unistd.h>
#endif
]=])

  foreach(_header Config.h Settings.h System.h)
    set(_header_path "${ORB_SLAM3_SOURCE_DIR}/include/${_header}")
    file(READ "${_header_path}" _header_contents)
    string(REPLACE "#include <unistd.h>" "${_windows_unistd_compat}"
      _header_contents "${_header_contents}")
    file(WRITE "${_header_path}" "${_header_contents}")
  endforeach()

  set(_g2o_cmake "${ORB_SLAM3_SOURCE_DIR}/Thirdparty/g2o/CMakeLists.txt")
  file(READ "${_g2o_cmake}" _g2o_contents)
  string(REPLACE " -O3 -march=native" ""
    _g2o_contents "${_g2o_contents}")
  string(REPLACE " -Wall -W" " /W3"
    _g2o_contents "${_g2o_contents}")
  string(REPLACE "SET (G2O_LIB_TYPE SHARED)" "SET (G2O_LIB_TYPE STATIC)"
    _g2o_contents "${_g2o_contents}")
  file(WRITE "${_g2o_cmake}" "${_g2o_contents}")

  set(_dbow2_cmake "${ORB_SLAM3_SOURCE_DIR}/Thirdparty/DBoW2/CMakeLists.txt")
  file(READ "${_dbow2_cmake}" _dbow2_contents)
  string(REPLACE "-Wall  -O3 -march=native" "/W3 /O2"
    _dbow2_contents "${_dbow2_contents}")
  string(REPLACE "add_library(DBoW2 SHARED" "add_library(DBoW2 STATIC"
    _dbow2_contents "${_dbow2_contents}")
  file(WRITE "${_dbow2_cmake}" "${_dbow2_contents}")
endif()

add_subdirectory("${ORB_SLAM3_SOURCE_DIR}/Thirdparty/g2o" "${CMAKE_BINARY_DIR}/thirdparty/g2o")
add_subdirectory("${ORB_SLAM3_SOURCE_DIR}/Thirdparty/DBoW2" "${CMAKE_BINARY_DIR}/thirdparty/DBoW2")
if(MSVC)
  foreach(_target g2o DBoW2)
    get_target_property(_target_type ${_target} TYPE)
    if(NOT _target_type STREQUAL "STATIC_LIBRARY")
      message(FATAL_ERROR "${_target} must be built as a static library with MSVC")
    endif()
  endforeach()
endif()
target_link_libraries(g2o PUBLIC Eigen3::Eigen)
target_link_libraries(DBoW2 Boost::serialization)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang|AppleClang")
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64|ARM64)$")
    if(APPLE)
      set(ORB_SLAM3_CPU_BASELINE -mcpu=apple-m1)
    else()
      set(ORB_SLAM3_CPU_BASELINE -march=armv8-a -mtune=generic)
    endif()
  else()
    set(ORB_SLAM3_CPU_BASELINE -march=x86-64 -mtune=generic)
  endif()

  target_compile_options(DBoW2 PRIVATE ${ORB_SLAM3_CPU_BASELINE})
  target_compile_options(g2o PRIVATE ${ORB_SLAM3_CPU_BASELINE})
endif()

if(MSVC)
  set(_g2o_compat "${CMAKE_BINARY_DIR}/g2o_windows_compat.h")
  file(WRITE "${_g2o_compat}" [=[
#pragma once
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
inline int vasprintf(char** output, const char* format, va_list args) {
  *output = nullptr;
  va_list copy;
  va_copy(copy, args);
  int length = _vscprintf(format, copy);
  va_end(copy);
  if (length < 0) return -1;
  *output = static_cast<char*>(malloc(static_cast<size_t>(length) + 1));
  if (!*output) return -1;
  int written = vsnprintf(*output, static_cast<size_t>(length) + 1, format, args);
  if (written < 0) { free(*output); *output = nullptr; return -1; }
  return written;
}
]=])
  target_compile_definitions(g2o PRIVATE _WINDOWS)
  target_compile_options(g2o PRIVATE "$<$<COMPILE_LANGUAGE:CXX>:/FI${_g2o_compat}>")
endif()

set(ORB_SLAM3_SOURCES
  src/System.cc src/Tracking.cc src/LocalMapping.cc src/LoopClosing.cc
  src/ORBextractor.cc src/ORBmatcher.cc src/FrameDrawer.cc src/Converter.cc
  src/MapPoint.cc src/KeyFrame.cc src/Atlas.cc src/Map.cc src/MapDrawer.cc
  src/Optimizer.cc src/Frame.cc src/KeyFrameDatabase.cc src/Sim3Solver.cc
  src/Viewer.cc src/ImuTypes.cc src/G2oTypes.cc
  src/CameraModels/Pinhole.cpp src/CameraModels/KannalaBrandt8.cpp
  src/OptimizableTypes.cpp src/MLPnPsolver.cpp src/GeometricTools.cc
  src/TwoViewReconstruction.cc src/Config.cc src/Settings.cc
  src/PointCloudMapping.cc)
list(TRANSFORM ORB_SLAM3_SOURCES PREPEND "${ORB_SLAM3_SOURCE_DIR}/")

add_library(ORB_SLAM3 STATIC ${ORB_SLAM3_SOURCES})
if(MSVC)
  target_compile_options(ORB_SLAM3 PRIVATE "/FI${ORB_SLAM3_SOURCE_DIR}/include/WindowsCompat.h")
endif()
target_include_directories(ORB_SLAM3 PUBLIC
  "${ORB_SLAM3_SOURCE_DIR}"
  "${ORB_SLAM3_SOURCE_DIR}/include"
  "${ORB_SLAM3_SOURCE_DIR}/include/CameraModels"
  "${ORB_SLAM3_SOURCE_DIR}/Thirdparty/Sophus")
target_link_libraries(ORB_SLAM3 PUBLIC
  ${OpenCV_LIBS} Eigen3::Eigen ${Pangolin_LIBRARIES} DBoW2 g2o
  Boost::serialization OpenSSL::Crypto)

if(ORB_SLAM3_DENSE_RECONSTRUCTION)
  find_package(PCL QUIET COMPONENTS common io filters kdtree)
  find_package(octomap QUIET)
  if(PCL_FOUND AND octomap_FOUND)
    target_compile_definitions(ORB_SLAM3 PRIVATE WITH_DENSE_RECONSTRUCTION)
    target_include_directories(ORB_SLAM3 PRIVATE ${PCL_INCLUDE_DIRS} ${OCTOMAP_INCLUDE_DIRS})
    target_link_directories(ORB_SLAM3 PRIVATE ${PCL_LIBRARY_DIRS})
    target_link_libraries(ORB_SLAM3 PRIVATE ${PCL_LIBRARIES} ${OCTOMAP_LIBRARIES})
    message(STATUS "Dense reconstruction enabled (PCL + OctoMap found)")
  else()
    message(STATUS "Dense reconstruction disabled: install PCL and OctoMap to enable it")
  endif()
endif()
