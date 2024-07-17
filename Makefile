.PHONY: clean pre-commit prerequisites test cmake-configure cmake-build cmake-test cmake-install cmake-uninstall template-watch template-build

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

cmake-build:
	$(MAKE) cmake-build-all

cmake-test:
	ctest $(_PRESET_ARGS)

cmake-install:
	cmake --build $(_PRESET_ARGS) --target install

cmake-uninstall:
	cmake --build $(_PRESET_ARGS) --target uninstall

test: cmake-configure cmake-build cmake-test cmake-install cmake-uninstall

test-coverage:
	$(MAKE) cmake-configure CONFIGURE+="-DCMAKE_BUILD_TYPE=Debug -DCODE_COVERAGE=ON -DBUILD_TESTING=ON" FRESH_CMAKE_CACHE=1
	$(MAKE) cmake-build-all cmake-build-ccov-all

test-valgrind:
	$(MAKE) cmake-configure CONFIGURE+="-DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DUSE_VALGRIND=ON" FRESH_CMAKE_CACHE=1
	$(MAKE) cmake-build-all cmake-build-ExperimentalMemCheck

test-sanitizer-template-%:
	$(MAKE) cmake-configure CONFIGURE+="-DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DUSE_SANITIZER=$*" FRESH_CMAKE_CACHE=1
	$(MAKE) cmake-build-all cmake-test

test-sanitizer-address:
	$(MAKE) test-sanitizer-template-address

test-sanitizer-leak:
	$(MAKE) test-sanitizer-template-leak

test-sanitizer-memory:
	$(MAKE) test-sanitizer-template-memory

test-sanitizer-undefined:
	$(MAKE) test-sanitizer-template-undefined

test-sanitizer: test-sanitizer-template-address test-sanitizer-template-leak test-sanitizer-template-memory test-sanitizer-template-undefined

test-cppcheck:
	$(MAKE) cmake-configure CONFIGURE+="-DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DUSE_CPPCHECK=ON" FRESH_CMAKE_CACHE=1
	$(MAKE) cmake-build-all

test-clang-tidy:
	$(MAKE) cmake-configure CONFIGURE+="-DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DUSE_CLANGTIDY=ON" FRESH_CMAKE_CACHE=1
	$(MAKE) cmake-build-all

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
