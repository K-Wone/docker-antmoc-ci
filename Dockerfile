#-------------------------------------------------------------------------------
# Stage 1: build packages
#-------------------------------------------------------------------------------
ARG SPACK_IMAGE="spack/ubuntu-bionic"
ARG SPACK_VERSION="latest"
FROM ${SPACK_IMAGE}:${SPACK_VERSION} AS builder

#-------------------------------------------------------------------------------
# Set up environments
#-------------------------------------------------------------------------------
USER root
WORKDIR /tmp

# set Spack paths which should be shared between docker stages
ARG SPACK_ROOT=/opt/spack
ARG CONFIG_DIR=/etc/spack
ARG INSTALL_DIR=/opt/software
ARG MIRROR_DIR=/opt/mirror
ARG REPO_DIR=/opt/repo

# copy files from the context to the image
#COPY mirror/ $MIRROR_DIR/
COPY repo/ $REPO_DIR/
COPY spack_find_externals.sh .
COPY spack_install.sh .

# create directories for Spack
RUN set -e; \
    mkdir -p $CONFIG_DIR; \
    mkdir -p $INSTALL_DIR; \
    mkdir -p $MIRROR_DIR

# set the arch for packages
ARG TARGET="x86_64"

# generate configurations
RUN (echo "config:" \
&&   echo "  install_tree:" \
&&   echo "    root: $INSTALL_DIR") > $CONFIG_DIR/config.yaml

RUN (echo "mirrors:" \
&&   echo "  local: file://$MIRROR_DIR") > $CONFIG_DIR/mirrors.yaml

RUN (echo "repos:" \
&&   echo "  - $REPO_DIR") > $CONFIG_DIR/repos.yaml

RUN (echo "packages:" \
&&   echo "  all:" \
&&   echo "    target: [$TARGET]") > $CONFIG_DIR/packages.yaml

#-------------------------------------------------------------------------------
# Find or install compilers
#-------------------------------------------------------------------------------
# install LLVM
RUN apt-get update && apt-get install -y \
        llvm-9 \
        clang-9 \
&&  rm -rf /var/lib/apt/lists/*

# find external packages
RUN set -e; \
    chmod u+x ./spack_find_externals.sh; \
    ./spack_find_externals.sh

# find system gcc and clang
RUN spack compiler find; \
    spack config get compilers > $CONFIG_DIR/compilers.yaml; \
    spack compilers

#-------------------------------------------------------------------------------
# Install dependencies for antmoc
#-------------------------------------------------------------------------------
RUN set -e; \
    chmod u+x ./spack_install.sh; \
    ./spack_install.sh


#-------------------------------------------------------------------------------
# Stage 2: build the runtime environment
#-------------------------------------------------------------------------------
ARG SPACK_IMAGE
ARG SPACK_VERSION
FROM ${SPACK_IMAGE}:${SPACK_VERSION}

LABEL maintainer="An Wang <wangan.cs@gmail.com>"

#-------------------------------------------------------------------------------
# Copy artifacts from stage 1 to stage 2
#-------------------------------------------------------------------------------
ARG CONFIG_DIR=/etc/spack
ARG INSTALL_DIR=/opt/software
ARG REPO_DIR=/opt/repo

COPY --from=builder $CONFIG_DIR $CONFIG_DIR
COPY --from=builder $INSTALL_DIR $INSTALL_DIR
COPY --from=builder $REPO_DIR $REPO_DIR

# install LLVM
RUN apt-get update && apt-get install -y \
        clang-9 \
        llvm-9 \
        kmod \
        sudo \
        wget \
&&  rm -f /usr/bin/clang /usr/bin/clang++ \
&&  ln -s /usr/bin/clang-9 /usr/bin/clang \
&&  ln -s /usr/bin/clang++-9 /usr/bin/clang++

# install ROCm
RUN wget -q -O - https://repo.radeon.com/rocm/rocm.gpg.key | \
    apt-key add - \
&&  echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/debian/ xenial main' | \
    tee /etc/apt/sources.list.d/rocm.list \
&&  apt-get update && apt-get install -y \
        rocm-dev \
        rocthrust \
&&  rm -rf /var/lib/apt/lists/*

#-------------------------------------------------------------------------------
# Add a user
#-------------------------------------------------------------------------------
# set user name
ARG USER_NAME=hpcer

# create the first user
RUN set -e; \
    \
    if ! id -u $USER_NAME > /dev/null 2>&1; then \
        useradd -m $USER_NAME; \
        echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
    fi

# transfer control to the default user
USER $USER_NAME
WORKDIR /home/$USER_NAME

# generate a script for Spack
RUN (echo "#!/usr/bin/env bash" \
&&   echo "export PATH=\$PATH:/opt/rocm/bin:/opt/rocm/rocprofiler/bin:/opt/rocm/opencl/bin" \
&&   echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/opt/rocm/lib:/opt/rocm/hip/lib:/opt/rocm/llvm/lib:/opt/rocm/opencl/lib" \
&&   echo "export INCLUDE=\$INCLUDE:/opt/rocm/include:/opt/rocm/hip/include:/opt/rocm/llvm/include" \
&&   echo "export C_INCLUDE_PATH=\$C_INCLUDE_PATH:/opt/rocm/include:/opt/rocm/hip/include:/opt/rocm/llvm/include" \
&&   echo "export CPLUS_INCLUDE_PATH=\$CPLUS_INCLUDE_PATH:/opt/rocm/include:/opt/rocm/hip/include:/opt/rocm/llvm/include" \
&&   echo "export SPACK_ROOT=$SPACK_ROOT" \
&&   echo ". $SPACK_ROOT/share/spack/setup-env.sh" \
&&   echo "") > ~/setup-env.sh \
&&   chmod u+x ~/setup-env.sh

#-------------------------------------------------------------------------------
# Reset the entrypoint
#-------------------------------------------------------------------------------
ENTRYPOINT []
CMD ["/bin/bash"]


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
