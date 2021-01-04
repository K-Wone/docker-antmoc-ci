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

# set Spack root
ARG SPACK_ROOT=/opt/spack
ENV SPACK_ROOT=${SPACK_ROOT}

# set Spack paths which should be shared between docker stages
ARG CONFIG_DIR=/etc/spack
ARG INSTALL_DIR=/opt/software
ARG MIRROR_DIR=/opt/mirror
ARG REPO_DIR=/opt/repo

# create directories for Spack
RUN set -e; \
    mkdir -p $CONFIG_DIR; \
    mkdir -p $INSTALL_DIR; \
    mkdir -p $MIRROR_DIR; \
    spack repo create $REPO_DIR ustb

# set the arch for packages
ARG TARGET="x86_64"

RUN set -e; \
    echo "config:"                      > $CONFIG_DIR/config.yaml; \
    echo "  install_tree:"              >> $CONFIG_DIR/config.yaml; \
    echo "    root: $INSTALL_DIR"       >> $CONFIG_DIR/config.yaml; \
    echo "mirrors:"                     > $CONFIG_DIR/mirrors.yaml; \
    echo "  local: file://$MIRROR_DIR"  >> $CONFIG_DIR/mirrors.yaml; \
    echo "repos:"                       > $CONFIG_DIR/repos.yaml; \
    echo "  - $REPO_DIR"                >> $CONFIG_DIR/repos.yaml; \
    echo "packages:"                    > $CONFIG_DIR/packages.yaml; \
    echo "  all:"                       >> $CONFIG_DIR/packages.yaml; \
    echo "    target: [$TARGET]"        >> $CONFIG_DIR/packages.yaml

# copy custom package.py to the image
COPY packages/ $REPO_DIR/packages/

#-------------------------------------------------------------------------------
# Find or install compilers
#-------------------------------------------------------------------------------
# find system gcc
ARG GCC_SPEC="gcc"
RUN spack compiler add; \
    spack compilers

# find external packages
COPY spack_find_externals.sh .
RUN set -e; \
    chmod u+x ./spack_find_externals.sh; \
    ./spack_find_externals.sh

# install llvm
ARG LLVM_SPEC="llvm"

RUN set -eu; \
    \
    spack mirror create -D -d ${MIRROR_DIR} ${LLVM_SPEC}; \
    spack install --fail-fast -ny ${LLVM_SPEC} %${GCC_SPEC}; \
    spack load ${LLVM_SPEC}; \
    spack compiler add; \
    spack compilers

# copy the configuration file to the system path
RUN spack config get compilers > ${CONFIG_DIR}/compilers.yaml

#-------------------------------------------------------------------------------
# Install dependencies for antmoc
#-------------------------------------------------------------------------------
COPY spack_install.sh .
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

# set spack root
ARG SPACK_ROOT=/opt/spack
ENV SPACK_ROOT=${SPACK_ROOT}

#-------------------------------------------------------------------------------
# Copy artifacts from stage 1 to stage 2
#-------------------------------------------------------------------------------
ARG CONFIG_DIR=/etc/spack
ARG INSTALL_DIR=/opt/software

COPY --from=builder $CONFIG_DIR $CONFIG_DIR
COPY --from=builder $INSTALL_DIR $INSTALL_DIR
COPY --from=builder $REPO_DIR $REPO_DIR

#-------------------------------------------------------------------------------
# Add a user
#-------------------------------------------------------------------------------
# set user name
ARG USER_NAME=hpcer
ENV USER_HOME="/home/$USER_NAME"

# create the first user
RUN set -eu; \
      \
      if ! id -u $USER_NAME > /dev/null 2>&1; then \
          useradd -m $USER_NAME; \
          echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
          cp -r ~/.spack $USER_HOME; \
          chown -R ${USER_NAME}: $USER_HOME/.spack; \
      fi

# transfer control to the default user
USER $USER_NAME
WORKDIR $USER_HOME

#-------------------------------------------------------------------------------
# Generate a script for enabling Spack
#-------------------------------------------------------------------------------
ENV ENV_FILE="$USER_HOME/setup-env.sh"
RUN set -e; \
    \
    echo "#!/usr/bin/env bash" > $ENV_FILE; \
    echo ". $SPACK_ROOT/share/spack/setup-env.sh" >> $ENV_FILE; \
    chmod u+x $ENV_FILE

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
