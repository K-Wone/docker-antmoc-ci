# stage 1
ARG BASE_IMAGE="gcc"
ARG BASE_TAG="8.3.0"
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

# install lcov
ARG LCOV_VERSION="1.14"
ENV LCOV_VERSION=${LCOV_VERSION}
ENV LCOV_TARBALL="lcov-${LCOV_VERSION}.tar.gz"
RUN set -ex; \
    wget https://github.com/linux-test-project/lcov/releases/download/v${LCOV_VERSION}/${LCOV_TARBALL}; \
    tar zxf ${LCOV_TARBALL}

WORKDIR /tmp/lcov-${LCOV_VERSION}
RUN set -ex; \
    make install

# install cmake
WORKDIR /tmp
ARG CMAKE_VERSION="3.15.7"
ENV CMAKE_VERSION=${CMAKE_VERSION}
ENV CMAKE_TARBALL="cmake-${CMAKE_VERSION}.tar.gz"

RUN set -ex; \
    wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${CMAKE_TARBALL}; \
    tar zxf ${CMAKE_TARBALL}

WORKDIR /tmp/cmake-${CMAKE_VERSION}
RUN set -ex; \
    ./configure; \
    make -j "$(nproc)"; \
    make install

# clean sources
WORKDIR /tmp
RUN rm -r cmake-${CMAKE_VERSION} ${CMAKE_TARBALL} lcov-${LCOV_VERSION} ${LCOV_TARBALL}

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
      org.label-schema.description="Provides tools for code coverage" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url=${VCS_URL} \
      org.label-schema.schema-version="1.0"
