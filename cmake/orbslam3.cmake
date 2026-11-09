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

find_package(OpenCV 4.4 REQUIRED)
find_package(Eigen3 3.1 REQUIRED)
find_package(Pangolin REQUIRED)
find_package(Boost REQUIRED COMPONENTS serialization)
find_package(OpenSSL REQUIRED)

add_subdirectory("${ORB_SLAM3_SOURCE_DIR}/Thirdparty/g2o" "${CMAKE_BINARY_DIR}/thirdparty/g2o")
add_subdirectory("${ORB_SLAM3_SOURCE_DIR}/Thirdparty/DBoW2" "${CMAKE_BINARY_DIR}/thirdparty/DBoW2")

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
