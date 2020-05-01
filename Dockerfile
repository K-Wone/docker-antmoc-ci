ARG BASE_IMAGE="leavesask/gcc"
ARG BASE_TAG="latest"
FROM ${BASE_IMAGE}:${BASE_TAG}

LABEL maintainer="Wang An <wangan.cs@gmail.com>"

USER root

# install basic tools
WORKDIR /tmp
RUN set -ex; \
      \
      apt-get update; \
      apt-get install -y \
              git \
              make

# install cmake
ARG CMAKE_VERSION="3.15.5"
ENV CMAKE_VERSION=${CMAKE_VERSION}

RUN set -eu; \
      \
      spack install --show-log-on-error -y cmake@${CMAKE_VERSION}; \
      spack load cmake

# install hdf5
ARG HDF5_VERSION="1.10.5"
ENV HDF5_VERSION=${HDF5_VERSION}
ARG HDF5_VARIANTS="-mpi"
ENV HDF5_VARIANTS=${HDF5_VARIANTS}

RUN set -eu; \
      \
      spack install --show-log-on-error -y hdf5@${HDF5_VERSION} ${HDF5_VARIANTS}; \
      spack load hdf5@${HDF5_VERSION}

# install fmt
ARG FMT_VERSION="6.0.0"
ENV FMT_VERSION=${FMT_VERSION}

RUN set -eu; \
      \
      spack install --show-log-on-error -y fmt@${FMT_VERSION}; \
      spack load fmt@${FMT_VERSION}

# install googletest
ARG GTEST_VERSION="1.10.0"
ENV GTEST_VERSION=${GTEST_VERSION}
ARG GTEST_VARIANTS="+gmock"
ENV GTEST_VARIANTS=${GTEST_VARIANTS}

RUN set -eu; \
      \
      spack install --show-log-on-error -y googletest@${GTEST_VERSION} ${GTEST_VARIANTS}; \
      spack load googletest@{GTEST_VERSION}

# install lcov
ARG LCOV_VERSION="1.14"
ENV LCOV_VERSION=${LCOV_VERSION}

RUN set -eu; \
      \
      spack install --show-log-on-error -y lcov@${LCOV_VERSION}; \
      spack load lcov@{LCOV_VERSION}


# transfer control to the default user
ARG USER_NAME=one

# create the first user
RUN set -eu; \
      \
      if ! id -u ${USER_NAME} > /dev/null 2>&1; then \
      useradd ${USER_NAME}; \
      usermod -aG sudo ${USER_NAME}; \
      fi

USER ${USER_NAME}

WORKDIR /home/${USER_NAME}

#-----------------------------------------------------------------------
# Build-time metadata as defined at http://label-schema.org
#-----------------------------------------------------------------------
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
LABEL org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.name="Docker image for ANT-MOC CI" \
      org.label-schema.description="Provides tools for testing and code coverage" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url=${VCS_URL} \
      org.label-schema.schema-version="1.0"
