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


# install cmake
RUN set -e; \
    spack install --show-log-on-error -y cmake; \
    spack load cmake

# install lcov
ARG LCOV_VERSION="1.14"
ENV LCOV_VERSION=${LCOV_VERSION}

RUN set -e; \
    spack install --show-log-on-error -y lcov@${LCOV_VERSION}; \
    spack load lcov@${LCOV_VERSION}


#-----------------------------------------------------------------------
# Build-time metadata as defined at http://label-schema.org
#-----------------------------------------------------------------------
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
LABEL org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.name="Docker image for ANT-MOC CI" \
      org.label-schema.description="Provides tools for testing and code coverage (no pre-installed dependencies)" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url=${VCS_URL} \
      org.label-schema.schema-version="1.0"
