#===============================================================================
# Default User Options
#===============================================================================

# Build-time arguments
BASE_IMAGE    ?= leavesask/gcc:latest

# Compiler
COMPILER_SPEC ?="gcc@9.2.0"
EXTRA_SPECS   ?="target=skylake"

# Dependencies
HDF5_VERSION      ?="1.10.5"
HDF5_VARIANTS     ?="~cxx~fortran~hl~mpi"
FMT_VERSION       ?="6.0.0"
TINYXML2_VERSION  ?="8.0.0"
GTEST_VERSION     ?="1.10.0"
LCOV_VERSION      ?="1.14"

# Image name
DOCKER_IMAGE ?= leavesask/antmoc-ci
DOCKER_TAG   := gcc

# Default user
USER_NAME    ?= root

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
                 --build-arg BASE_IMAGE=$(BASE_IMAGE) \
                 --build-arg COMPILER_SPEC=$(COMPILER_SPEC) \
                 --build-arg EXTRA_SPECS=$(EXTRA_SPECS) \
                 --build-arg HDF5_VERSION=$(HDF5_VERSION) \
                 --build-arg HDF5_VARIANTS=$(HDF5_VARIANTS) \
                 --build-arg FMT_VERSION=$(FMT_VERSION) \
                 --build-arg TINYXML2_VERSION=$(TINYXML2_VERSION) \
                 --build-arg GTEST_VERSION=$(GTEST_VERSION) \
                 --build-arg LCOV_VERSION=$(LCOV_VERSION) \
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
