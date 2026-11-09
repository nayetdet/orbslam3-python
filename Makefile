.PHONY: install editable wheel lint format check-format

install:
	python -m pip install .

editable:
	python -m pip install --no-build-isolation -e .

wheel:
	python -m pip wheel . --wheel-dir dist

lint:
	ruff check src
	clang-format --dry-run --Werror src/orbslam3/python_wrapper/orbslam3_pybind.cpp

format:
	ruff check --fix src
	ruff format src
	clang-format -i src/orbslam3/python_wrapper/orbslam3_pybind.cpp

check-format:
	ruff format --check src
	clang-format --dry-run --Werror src/orbslam3/python_wrapper/orbslam3_pybind.cpp
