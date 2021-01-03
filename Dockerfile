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

RUN set -e; \
    mkdir -p $CONFIG_DIR; \
    mkdir -p $INSTALL_DIR; \
    echo "config:" > $CONFIG_DIR/config.yaml; \
    echo "  install_tree:" >> $CONFIG_DIR/config.yaml; \
    echo "    root: $INSTALL_DIR" >> $CONFIG_DIR/config.yaml

#-------------------------------------------------------------------------------
# Find or install compilers
#-------------------------------------------------------------------------------
# find system gcc
ARG EXTRA_SPECS="target=x86_64"
ARG GCC_SPEC="gcc"
RUN spack compiler add; \
    spack compilers

# install llvm
ARG LLVM_SPEC="llvm@9.0.1"
ARG CLANG_SPEC="clang@9.0.1"

RUN set -eu; \
    \
    spack install ${LLVM_SPEC} %${GCC_SPEC}; \
    spack load ${LLVM_SPEC}; \
    spack compiler add; \
    spack compilers

# copy the configuration file to the system path
RUN spack config get compilers > ${CONFIG_DIR}/compilers.yaml

#-------------------------------------------------------------------------------
# Install MPI implementations
#-------------------------------------------------------------------------------
ARG MPICH_SPEC="mpich@3.3.2"
ARG OPENMPI_SPEC="openmpi@4.0.5"

RUN set -e; \
    \
    mpis=("$MPICH_SPEC" "$OPENMPI_SPEC"); \
    for i in "${mpis[@]}"; do \
        spack install --fail-fast -ny $i %$GCC_SPEC; \
    done

#-------------------------------------------------------------------------------
# Install other packages
#-------------------------------------------------------------------------------
ARG CMAKE_SPEC="cmake@3.18.4"
ARG FMT_SPEC="fmt@6.0.0"
ARG TINYXML2_SPEC="tinyxml2@7.0.0"
ARG HDF5_SPEC="hdf5@1.10.7~cxx~fortran+hl~mpi"
ARG PHDF5_SPEC="hdf5@1.10.7~cxx~fortran+hl+mpi"
ARG GTEST_SPEC="googletest@1.10.0+gmock"
ARG LCOV_SPEC="lcov@1.14"

RUN set -e; \
    \
    compilers=("$GCC_SPEC"); \
    mpis=("$MPICH_SPEC" "$OPENMPI_SPEC"); \
    packages=( \
        "$FMT_SPEC" \
        "$TINYXML2_SPEC" \
        "$HDF5_SPEC" \
        "$GTEST_SPEC" \
    ); \
    packages_once=( \
        "$CMAKE_SPEC" \
        "$LCOV_SPEC" \
    ); \
    packages_with_mpi=( \
        "$PHDF5_SPEC" \
    ); \
    \
    for i in "${packages_once[@]}"; do \
        spack install --fail-fast -ny $i %$GCC_SPEC; \
    done; \
    \
    for c in "${compilers[@]}"; do \
        for i in "${packages[@]}"; do \
            spack install --fail-fast -ny $i %$c; \
        done; \
        \
        for m in "${mpis[@]}"; do \
            for i in "${packages_with_mpi[@]}"; do \
                spack install --fail-fast -ny $i %$c ^$m; \
            done; \
        done; \
    done; \
    spack gc -y; \
    spack clean -a

# cleanup
RUN set -e; \
    spack gc -y; \
    spack clean -a


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
    echo "#!/bin/env bash" > $ENV_FILE; \
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
