[![Layers](https://images.microbadger.com/badges/image/leavesask/antmoc-ci.svg)](https://microbadger.com/images/leavesask/antmoc-ci)
[![Version](https://images.microbadger.com/badges/version/leavesask/antmoc-ci.svg)](https://hub.docker.com/repository/docker/leavesask/antmoc-ci)
[![Commit](https://images.microbadger.com/badges/commit/leavesask/antmoc-ci.svg)](https://github.com/K-Wone/docker-antmoc-ci)
[![Docker Pulls](https://img.shields.io/docker/pulls/leavesask/antmoc-ci?color=informational)](https://hub.docker.com/repository/docker/leavesask/antmoc-ci)
[![Automated Build](https://img.shields.io/docker/automated/leavesask/antmoc-ci)](https://hub.docker.com/repository/docker/leavesask/antmoc-ci)

# Supported tags

- `coverage-gcc`
- `coverage-clang`

# How to use

1. [Install docker engine](https://docs.docker.com/install/)

2. Pull the image
  ```bash
  docker pull leavesask/antmoc-ci:<tag>
  ```

3. Run the image interactively
  ```bash
  docker run -it --rm leavesask/antmoc-ci:<tag>
  ```

# How to build

## make

There are a bunch of build-time arguments you can use to build the image.

It is hightly recommended that you build the image with `make`.

```bash
# Build an image for code coverage
make

# Build and publish the image
make release
```

Check `Makefile` for more options.

## docker build

As an alternative, you can build the image with `docker build` command.

```bash
docker build \
        --build-arg BASE_IMAGE="leavesask/hdf5" \
        --build-arg BASE_TAG="1.10.5-gcc" \
        --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
        --build-arg VCS_REF=`git rev-parse --short HEAD` \
        -t my-repo/antmoc-ci:latest .
```

Arguments and their defaults are listed below.

- `BASE_IMAGE`: value (default=`leavesask/hdf5`)
  - This is the base image for all of the stages.
  - It is supposed to be a toolchain containing compilers and dependencies.

- `BASE_TAG`: value (default=`latest`)
