#===============================================================================
# Default User Options
#===============================================================================

# Build-time arguments
SPACK_IMAGE       ?= "spack/ubuntu-bionic"
SPACK_VERSION     ?= "latest"

# Packages
EXTRA_SPECS       ?= "target=x86_64"
LLVM_SPEC         ?= "llvm@9.0.1"
MPICH_SPEC        ?= "mpich@3.3.2"
OPENMPI_SPEC      ?= "openmpi@4.0.5"
CMAKE_SPEC        ?= "cmake@3.18.4"
FMT_SPEC          ?= "fmt@6.0.0"
TINYXML2_SPEC     ?= "tinyxml2@7.0.0"
HDF5_SPEC         ?= "hdf5@1.10.7~cxx~fortran+hl~mpi"
PHDF5_SPEC        ?= "hdf5@1.10.7~cxx~fortran+hl+mpi"
GTEST_SPEC        ?= "googletest@1.10.0+gmock"
LCOV_SPEC         ?= "lcov@1.14"
ROCM_VERSION      ?= "3.10.0"

# Image name
DOCKER_IMAGE ?= leavesask/antmoc-ci
DOCKER_TAG   := 0.1.15

# Default user
USER_NAME    ?= hpcer

#===============================================================================
# Variables and objects
#===============================================================================

BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
VCS_URL=$(shell git config --get remote.origin.url)

# Get the latest commit
GIT_COMMIT = $(strip $(shell git rev-parse --short HEAD))

#===============================================================================
# Targets to Build
#===============================================================================

.PHONY : docker_build docker_push output

default: build
build: docker_build output
release: docker_build docker_push output

docker_build:
	# Build Docker image
	docker build \
                 --build-arg SPACK_IMAGE=$(SPACK_IMAGE) \
                 --build-arg SPACK_VERSION=$(SPACK_VERSION) \
                 --build-arg EXTRA_SPECS=$(EXTRA_SPECS) \
                 --build-arg LLVM_SPEC=$(LLVM_SPEC) \
                 --build-arg MPICH_SPEC=$(MPICH_SPEC) \
                 --build-arg OPENMPI_SPEC=$(OPENMPI_SPEC) \
                 --build-arg CMAKE_SPEC=$(CMAKE_SPEC) \
                 --build-arg FMT_SPEC=$(FMT_SPEC) \
                 --build-arg TINYXML2_SPEC=$(TINYXML2_SPEC) \
                 --build-arg HDF5_SPEC=$(HDF5_SPEC) \
                 --build-arg PHDF5_SPEC=$(PHDF5_SPEC) \
                 --build-arg GTEST_SPEC=$(GTEST_SPEC) \
                 --build-arg LCOV_SPEC=$(LCOV_SPEC) \
                 --build-arg ROCM_VERSION=$(ROCM_VERSION) \
                 --build-arg BUILD_DATE=$(BUILD_DATE) \
                 --build-arg VCS_URL=$(VCS_URL) \
                 --build-arg VCS_REF=$(GIT_COMMIT) \
                 -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

docker_push:
	# Tag image as latest
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_IMAGE):latest

	# Push to DockerHub
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)
	docker push $(DOCKER_IMAGE):latest

output:
	@echo Docker Image: $(DOCKER_IMAGE):$(DOCKER_TAG)
