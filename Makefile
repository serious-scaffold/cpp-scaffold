.PHONY: clean prerequisites pre-commit cmake-configure cmake-build cmake-test cmake-install cmake-uninstall test-build test-build-memcheck test-build-test test-build-test-install test-build-test-install-ccov test-coverage test-valgrind test-sanitizer-address test-sanitizer-leak test-sanitizer-memory test-sanitizer-undefined test-sanitizer test-cppcheck test-clang-tidy test-export-mode docs-requirements docs docs-check docs-linkcheck template-watch template-build

########################################################################################
# Variables
########################################################################################

# Extra arguments to pass to pre-commit.
PRE_COMMIT_EXTRA_ARGS ?=

# Preset to use for CMake.
PRESET ?= default

# Extra arguments to pass to CMake when configuring.
CONFIGURE ?=

########################################################################################
# Development Environment Management
########################################################################################

# Remove common intermediate files.
clean:
	-rm -rf \
		out \
		docs/_build

# Install standalone tools
prerequisites:
	pipx install --force copier==9.3.1
	pipx install --force pre-commit==3.7.1
	pipx install --force watchfiles==0.22.0

########################################################################################
# Lint
########################################################################################

# Run pre-commit with autofix against all files.
pre-commit:
	pre-commit run --all-files $(PRE_COMMIT_EXTRA_ARGS)

########################################################################################
# CMake build and test
########################################################################################

_PRESET_ARGS = --preset $(PRESET)

cmake-configure:
	cmake -S . $(_PRESET_ARGS) $(CONFIGURE) $(if $(FRESH_CMAKE_CACHE),--fresh)

cmake-build-%:
	cmake --build $(_PRESET_ARGS) --target $*

cmake-build: cmake-build-all

cmake-test:
	ctest $(_PRESET_ARGS)

cmake-install:
	cmake --build $(_PRESET_ARGS) --target install

cmake-uninstall:
	cmake --build $(_PRESET_ARGS) --target uninstall

test-build: cmake-configure cmake-build

test-build-memcheck: test-build cmake-build-ExperimentalMemCheck

test-build-test: test-build cmake-test

test-build-test-install: test-build-test cmake-install cmake-uninstall

test-build-test-install-ccov: test-build-test-install cmake-build-ccov-all

test-coverage:
	$(MAKE) test-build-test-install-ccov CONFIGURE+="-DCMAKE_BUILD_TYPE=Debug -DCODE_COVERAGE=ON -DBUILD_TESTING=ON" FRESH_CMAKE_CACHE=1

test-valgrind:
	$(MAKE) test-build-memcheck CONFIGURE+="-DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DUSE_VALGRIND=ON" FRESH_CMAKE_CACHE=1

test-sanitizer-template-%:
	$(MAKE) test-build-test CONFIGURE+="-DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DUSE_SANITIZER=$*" FRESH_CMAKE_CACHE=1

test-sanitizer-address: test-sanitizer-template-address

test-sanitizer-leak: test-sanitizer-template-leak

test-sanitizer-memory: test-sanitizer-template-memory

test-sanitizer-undefined: test-sanitizer-template-undefined

test-sanitizer: test-sanitizer-template-address test-sanitizer-template-leak test-sanitizer-template-memory test-sanitizer-template-undefined

test-cppcheck:
	$(MAKE) test-build CONFIGURE+="-DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DUSE_CPPCHECK=ON" FRESH_CMAKE_CACHE=1

test-clang-tidy:
	$(MAKE) test-build CONFIGURE+="-DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DUSE_CLANGTIDY=ON" FRESH_CMAKE_CACHE=1

test-export-mode:
	$(MAKE) test-build-test-install CONFIGURE+="-DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DVCPKG_EXPORT_MODE=ON" FRESH_CMAKE_CACHE=1

########################################################################################
# Documentation
########################################################################################

docs-requirements:
	pip install -r docs/requirements.txt

docs: docs-requirements
	$(MAKE) cmake-build-ss-cpp-docs

docs-%: docs-requirements
	$(MAKE) cmake-build-ss-cpp-docs-$*

docs-check:
	$(MAKE) cmake-build-ss-cpp-docs-check

docs-linkcheck:
	$(MAKE) cmake-build-ss-cpp-docs-linkcheck

########################################################################################
# Template
########################################################################################

template-watch:
	watchfiles "make template-build" template includes copier.yml

template-build:
	find . -maxdepth 1 | grep -vE '(\.|\.git|template|includes|copier\.yml)$$' | xargs -I {} rm -r {}
	copier copy -r HEAD --data-file includes/copier-answers-sample.yml -f . .
	rm -rf .copier-answers.yml
