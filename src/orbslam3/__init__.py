from importlib.metadata import version

from .orbslam3 import ORB_SLAM3

__all__ = ["ORB_SLAM3"]
__version__ = version("orbslam3")
