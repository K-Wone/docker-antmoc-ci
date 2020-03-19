ARG BASE_IMAGE="gcc"
ARG BASE_TAG="latest"
FROM ${BASE_IMAGE}:${BASE_TAG}

LABEL maintainer="Wang An <wangan.cs@gmail.com>"

USER root

WORKDIR /tmp

# install basic tools
RUN set -ex; \
      \
      apt-get update; \
      apt-get install -y \
              cmake \
              make \
              python3 \
              python3-pip \
              python3-lxml

# install gcovr
RUN pip3 install gcovr

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
