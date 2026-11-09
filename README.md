# ORB-SLAM3 Python

Python bindings for the [`nayetdet/ORB_SLAM3`](https://github.com/nayetdet/ORB_SLAM3) fork, including its dense reconstruction extension.

## Install

Install the package after setting up the native ORB-SLAM3 dependencies:

```bash
make install
```

PCL and OctoMap enable the fork's dense reconstruction support.

## Example

```python
import orbslam3

slam = orbslam3.ORB_SLAM3("Vocabulary/ORBvoc.txt", "camera.yaml", "rgbd")
pose = slam.TrackRGBD(color, depth, timestamp)
slam.Shutdown()
slam.SaveTrajectoryTUM("trajectory.txt")
```

The API supports monocular, stereo, RGB-D, and IMU inputs. IMU measurements use an `(N, 7)` NumPy array: `ax, ay, az, gx, gy, gz, timestamp`.

ORB-SLAM3 is licensed under GPL-3.0.
