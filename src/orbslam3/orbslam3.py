from pathlib import Path
from typing import Optional

import numpy as np

from . import orbslam3_pybind as _orb


class ORB_SLAM3:
    _SENSORS = {
        "MONOCULAR": _orb._System.eSensor.MONOCULAR,
        "STEREO": _orb._System.eSensor.STEREO,
        "RGBD": _orb._System.eSensor.RGBD,
        "IMU_MONOCULAR": _orb._System.eSensor.IMU_MONOCULAR,
        "IMU_STEREO": _orb._System.eSensor.IMU_STEREO,
        "IMU_RGBD": _orb._System.eSensor.IMU_RGBD,
    }

    def __init__(self, vocabulary: str, config: str, sensor: str, visualize: bool = False):
        try:
            sensor_type = self._SENSORS[sensor.upper()]
        except KeyError as exc:
            raise ValueError(
                f"unsupported sensor {sensor!r}; choose from {tuple(self._SENSORS)}"
            ) from exc
        for label, filename in (("vocabulary", vocabulary), ("config", config)):
            if not Path(filename).is_file():
                raise FileNotFoundError(f"{label} file does not exist: {filename}")
        self._system = _orb._System(vocabulary, config, sensor_type, visualize)

    @staticmethod
    def _image(value: np.ndarray, name: str) -> np.ndarray:
        if not isinstance(value, np.ndarray):
            raise TypeError(f"{name} must be a numpy array")
        if value.ndim not in (2, 3) or value.size == 0:
            raise ValueError(f"{name} must be a non-empty 2D or 3D image")
        return np.ascontiguousarray(value)

    @staticmethod
    def _imu(value: Optional[np.ndarray]) -> np.ndarray:
        if value is None:
            return np.empty((0, 7), dtype=np.float64)
        value = np.ascontiguousarray(value, dtype=np.float64)
        if value.ndim != 2 or value.shape[1] != 7:
            raise ValueError("vImuMeas must have shape (N, 7): ax, ay, az, gx, gy, gz, timestamp")
        return value

    def TrackMonocular(
        self,
        image: np.ndarray,
        timestamp: float,
        vImuMeas: Optional[np.ndarray] = None,
        filename: str = "",
    ):
        return self._system._TrackMonocular(
            self._image(image, "image"), float(timestamp), self._imu(vImuMeas), filename
        )

    def TrackStereo(
        self,
        imLeft: np.ndarray,
        imRight: np.ndarray,
        timestamp: float,
        vImuMeas: Optional[np.ndarray] = None,
        filename: str = "",
    ):
        return self._system._TrackStereo(
            self._image(imLeft, "imLeft"),
            self._image(imRight, "imRight"),
            float(timestamp),
            self._imu(vImuMeas),
            filename,
        )

    def TrackRGBD(
        self,
        image: np.ndarray,
        depthmap: np.ndarray,
        timestamp: float,
        vImuMeas: Optional[np.ndarray] = None,
        filename: str = "",
    ):
        return self._system._TrackRGBD(
            self._image(image, "image"),
            self._image(depthmap, "depthmap"),
            float(timestamp),
            self._imu(vImuMeas),
            filename,
        )

    def Shutdown(self):
        self._system._Shutdown()

    def Reset(self):
        self._system._Reset()

    def ResetActiveMap(self):
        self._system._ResetActiveMap()

    def ActivateLocalizationMode(self):
        self._system._ActivateLocalizationMode()

    def DeactivateLocalizationMode(self):
        self._system._DeactivateLocalizationMode()

    def MapChanged(self):
        return self._system._MapChanged()

    def GetImageScale(self):
        return self._system._GetImageScale()

    def isFinished(self):
        return self._system._isFinished()

    def isLost(self):
        return self._system._isLost()

    def isShutDown(self):
        return self._system._isShutDown()

    def SaveTrajectoryTUM(self, filename: str):
        self._system._SaveTrajectoryTUM(filename)

    def SaveTrajectoryKITTI(self, filename: str):
        self._system._SaveTrajectoryKITTI(filename)

    def SaveTrajectoryEuRoC(self, filename: str):
        self._system._SaveTrajectoryEuRoC(filename)

    def SaveKeyFrameTrajectoryTUM(self, filename: str):
        self._system._SaveKeyFrameTrajectoryTUM(filename)

    def SaveKeyFrameTrajectoryEuRoC(self, filename: str):
        self._system._SaveKeyFrameTrajectoryEuRoC(filename)
