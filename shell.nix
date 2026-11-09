{ pkgs ? import <nixpkgs> {} }:
let
  pangolin = pkgs.stdenv.mkDerivation {
    pname = "pangolin";
    version = "0.9.2";
    src = pkgs.fetchFromGitHub {
      owner = "stevenlovegrove";
      repo = "Pangolin";
      rev = "v0.9.2";
      hash = "sha256-rRR/+PdVcnOiv0X7OGBmTQe5l1XQ94nzyy02Tf95AWQ=";
    };

    nativeBuildInputs = with pkgs; [ cmake pkg-config ];
    buildInputs = with pkgs; [
      eigen
      libGL
      libepoxy
      libx11
      libxcursor
      libxext
      libxfixes
      libxi
      libxinerama
      libxrandr
    ];

    cmakeFlags = [
      "-DBUILD_EXAMPLES=OFF"
      "-DBUILD_TOOLS=OFF"
      "-DBUILD_TESTS=OFF"
      "-DBUILD_PANGOLIN_PYTHON=OFF"
    ];
  };
in
pkgs.mkShell {
  packages = with pkgs; [
    boost
    ccache
    clang-tools
    cmake
    eigen
    gcc
    git
    glew
    gnumake
    libGL
    libGLU
    libepoxy
    libx11
    libxcursor
    libxext
    libxfixes
    libxi
    libxinerama
    libxkbcommon
    libxrandr
    mesa
    ninja
    octomap
    openssl
    opencv4
    pangolin
    pcl
    pkg-config
    ruff
    (python3.withPackages (ps: with ps; [
      numpy
      pip
      pybind11
      scikit-build-core
      setuptools
      wheel
    ]))
  ];
}
