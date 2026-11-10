#include <System.h>
#include <pybind11/eigen.h>
#include <pybind11/numpy.h>
#include <pybind11/pybind11.h>
#include <pybind11/stl.h>

#include <cstdint>
#include <map>
#include <opencv2/core.hpp>
#include <stdexcept>
#include <string>
#include <vector>

namespace py = pybind11;
using namespace py::literals;

namespace {

int cv_depth(const py::array& array) {
  static const std::map<std::string, int> depths{
      {py::format_descriptor<std::uint8_t>::format(), CV_8U},
      {py::format_descriptor<std::int8_t>::format(), CV_8S},
      {py::format_descriptor<std::uint16_t>::format(), CV_16U},
      {py::format_descriptor<std::int16_t>::format(), CV_16S},
      {py::format_descriptor<std::int32_t>::format(), CV_32S},
      {py::format_descriptor<float>::format(), CV_32F},
      {py::format_descriptor<double>::format(), CV_64F},
  };
  const auto it = depths.find(std::string(1, array.dtype().char_()));
  if (it == depths.end()) throw std::invalid_argument("unsupported numpy dtype");
  return it->second;
}

cv::Mat as_mat(py::array& array) {
  if (!(array.flags() & py::array::c_style))
    throw std::invalid_argument("image must be C-contiguous");
  if (array.ndim() != 2 && array.ndim() != 3)
    throw std::invalid_argument("image must have two or three dimensions");
  const int channels = array.ndim() == 3 ? static_cast<int>(array.shape(2)) : 1;
  if (channels < 1 || channels > CV_CN_MAX)
    throw std::invalid_argument("invalid image channel count");
  return {static_cast<int>(array.shape(0)), static_cast<int>(array.shape(1)),
          CV_MAKETYPE(cv_depth(array), channels), array.mutable_data(),
          static_cast<size_t>(array.strides(0))};
}

std::vector<ORB_SLAM3::IMU::Point> as_imu(py::array_t<double>& array) {
  if (array.size() == 0) return {};
  if (array.ndim() != 2 || array.shape(1) != 7)
    throw std::invalid_argument("IMU measurements must have shape (N, 7)");
  std::vector<ORB_SLAM3::IMU::Point> points;
  points.reserve(array.shape(0));
  const auto values = array.unchecked<2>();
  for (py::ssize_t row = 0; row < values.shape(0); ++row)
    points.emplace_back(static_cast<float>(values(row, 0)), static_cast<float>(values(row, 1)),
                        static_cast<float>(values(row, 2)), static_cast<float>(values(row, 3)),
                        static_cast<float>(values(row, 4)), static_cast<float>(values(row, 5)),
                        values(row, 6));
  return points;
}

}  // namespace

PYBIND11_MODULE(orbslam3_pybind, module) {
  using ORB_SLAM3::System;
  py::class_<System> system(module, "_System");
  system
      .def(py::init<const std::string&, const std::string&, System::eSensor, bool, int,
                    const std::string&>(),
           "vocabulary"_a, "settings"_a, "sensor"_a, "use_viewer"_a = true, "initial_frame"_a = 0,
           "sequence"_a = "")
      .def("_ActivateLocalizationMode", &System::ActivateLocalizationMode)
      .def("_DeactivateLocalizationMode", &System::DeactivateLocalizationMode)
      .def("_GetImageScale", &System::GetImageScale)
      .def("_MapChanged", &System::MapChanged)
      .def("_Reset", &System::Reset)
      .def("_ResetActiveMap", &System::ResetActiveMap)
      .def("_SaveKeyFrameTrajectoryEuRoC",
           [](System& self, const std::string& filename) {
             self.SaveKeyFrameTrajectoryEuRoC(filename);
           })
      .def("_SaveTrajectoryEuRoC",
           [](System& self, const std::string& filename) { self.SaveTrajectoryEuRoC(filename); })
      .def("_SaveKeyFrameTrajectoryTUM", &System::SaveKeyFrameTrajectoryTUM)
      .def("_SaveTrajectoryKITTI", &System::SaveTrajectoryKITTI)
      .def("_SaveTrajectoryTUM", &System::SaveTrajectoryTUM)
      .def("_Shutdown", &System::Shutdown)
      .def("_isFinished", &System::isFinished)
      .def("_isLost", &System::isLost)
      .def("_isShutDown", &System::isShutDown)
      .def(
          "_TrackMonocular",
          [](System& self, py::array image, double timestamp, py::array_t<double> imu,
             const std::string& filename) {
            auto mat = as_mat(image);
            auto points = as_imu(imu);
            py::gil_scoped_release release;
            return self.TrackMonocular(mat, timestamp, points, filename).matrix();
          },
          "image"_a, "timestamp"_a, "vImuMeas"_a = py::array_t<double>(), "filename"_a = "")
      .def(
          "_TrackRGBD",
          [](System& self, py::array image, py::array depth, double timestamp,
             py::array_t<double> imu, const std::string& filename) {
            auto color = as_mat(image);
            auto depth_map = as_mat(depth);
            auto points = as_imu(imu);
            py::gil_scoped_release release;
            return self.TrackRGBD(color, depth_map, timestamp, points, filename).matrix();
          },
          "image"_a, "depthmap"_a, "timestamp"_a, "vImuMeas"_a = py::array_t<double>(),
          "filename"_a = "")
      .def(
          "_TrackStereo",
          [](System& self, py::array left, py::array right, double timestamp,
             py::array_t<double> imu, const std::string& filename) {
            auto left_mat = as_mat(left);
            auto right_mat = as_mat(right);
            auto points = as_imu(imu);
            py::gil_scoped_release release;
            return self.TrackStereo(left_mat, right_mat, timestamp, points, filename).matrix();
          },
          "imLeft"_a, "imRight"_a, "timestamp"_a, "vImuMeas"_a = py::array_t<double>(),
          "filename"_a = "");

  py::enum_<System::eSensor>(system, "eSensor")
      .value("MONOCULAR", System::MONOCULAR)
      .value("STEREO", System::STEREO)
      .value("RGBD", System::RGBD)
      .value("IMU_MONOCULAR", System::IMU_MONOCULAR)
      .value("IMU_STEREO", System::IMU_STEREO)
      .value("IMU_RGBD", System::IMU_RGBD);
}
