.PHONY: install build check format

install:
	uv sync

build:
	uv build

check:
	ruff check src
	ruff format --check src
	clang-format --dry-run --Werror src/orbslam3/orbslam3_pybind.cpp

format:
	ruff check --fix src
	ruff format src
	clang-format -i src/orbslam3/orbslam3_pybind.cpp
