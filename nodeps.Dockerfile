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
RUN set -eu; \
      \
      spack install --show-log-on-error -y cmake; \
      spack load cmake

# install lcov
ARG LCOV_VERSION="1.14"
ENV LCOV_VERSION=${LCOV_VERSION}

RUN set -eu; \
      \
      spack install --show-log-on-error -y lcov@${LCOV_VERSION}; \
      spack load lcov@${LCOV_VERSION}


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
