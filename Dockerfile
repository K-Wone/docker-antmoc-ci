# the latest HDF5 image compiled with GCC
ARG BASE_IMAGE="leavesask/hdf5"
ARG BASE_TAG="1.10.5-gcc"
FROM ${BASE_IMAGE}:${BASE_TAG}

LABEL maintainer="Wang An <wangan.cs@gmail.com>"

USER root

WORKDIR /tmp

# install basic tools
RUN set -ex; \
      \
      sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' \
             /etc/apk/repositories; \
      apk add --no-cache \
              make \
              python3 \
              py3-lxml

# install gcovr
RUN pip3 install gcovr


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
