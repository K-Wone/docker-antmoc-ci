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
              make \
              sudo

# transfer control to the default user
ARG USER_NAME=one
ENV USER_HOME="/home/${USER_NAME}"

# create the first user
RUN set -eu; \
      \
      if ! id -u ${USER_NAME} > /dev/null 2>&1; then \
      useradd -m ${USER_NAME}; \
      echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
      cp -r ~/.spack $USER_HOME; \
      chown -R ${USER_NAME}: ${USER_HOME}/.spack; \
      fi

USER $USER_NAME
WORKDIR $USER_HOME

# initialize spack environment
ENV SPACK_ROOT=/opt/spack
ENV PATH=${SPACK_ROOT}/bin:$PATH
RUN set -e; \
    sudo chown -R ${USER_NAME}: $SPACK_ROOT; \
    source ${SPACK_ROOT}/share/spack/setup-env.sh


# install fmt
ARG FMT_VERSION="6.0.0"
ENV FMT_VERSION=${FMT_VERSION}

RUN spack install --show-log-on-error --no-checksum -y fmt@${FMT_VERSION}

# install hdf5
ARG HDF5_VERSION="1.10.5"
ENV HDF5_VERSION=${HDF5_VERSION}
ARG HDF5_VARIANTS="~cxx~fortran~hl~mpi"
ENV HDF5_VARIANTS=${HDF5_VARIANTS}

RUN spack install --show-log-on-error -y hdf5@${HDF5_VERSION} ${HDF5_VARIANTS}

# install googletest
ARG GTEST_VERSION="1.10.0"
ENV GTEST_VERSION=${GTEST_VERSION}
ARG GTEST_VARIANTS="+gmock"
ENV GTEST_VARIANTS=${GTEST_VARIANTS}

RUN spack install --show-log-on-error -y googletest@${GTEST_VERSION} ${GTEST_VARIANTS}

# install cmake
RUN spack install --show-log-on-error -y cmake@3.16.2

# install lcov
ARG LCOV_VERSION="1.14"
ENV LCOV_VERSION=${LCOV_VERSION}

RUN spack install --show-log-on-error -y lcov@${LCOV_VERSION}

RUN set -e; \
      \
      echo "spack load cmake@3.16.2" >> ~/.bashrc; \
      echo "spack load -r hdf5@${HDF5_VERSION}" >> ~/.bashrc; \
      echo "spack load fmt@${FMT_VERSION}" >> ~/.bashrc; \
      echo "spack load googletest@${GTEST_VERSION}" >> ~/.bashrc; \
      echo "spack load lcov@${LCOV_VERSION}" >> ~/.bashrc


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

#-----------------------------------------------------------------------
# Setup entrypoint
#-----------------------------------------------------------------------
ENTRYPOINT ["/bin/bash"]
CMD ["spack find --loaded"]
