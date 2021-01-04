#!/usr/bin/env bash

set -e

# Compiler specs
GCC_SPEC="gcc"
CLANG_SPEC="clang"

# Package specs
MPICH_SPEC="mpich@3.3.2~fortran"
OPENMPI_SPEC="openmpi@4.0.5"
CMAKE_SPEC="cmake@3.18.4"
FMT_SPEC="fmt@6.0.0"
TINYXML2_SPEC="tinyxml2@7.0.0"
HDF5_SPEC="hdf5@1.10.7~cxx~fortran+hl~mpi"
PHDF5_SPEC="hdf5@1.10.7~cxx~fortran+hl+mpi"
GTEST_SPEC="googletest@1.10.0+gmock"
LCOV_SPEC="lcov@1.14"

# ROCm
ROCM_VERSION="3.10.0"
HIP_SPEC="hip@${ROCM_VERSION}"
ROCPRIM_SPEC="rocprim@${ROCM_VERSION}"
ROCTHRUST_SPEC="rocthrust@${ROCM_VERSION}"

# Compilers
compilers=("$GCC_SPEC" "$CLANG_SPEC")

# MPI implementations
mpis=("$MPICH_SPEC" "$OPENMPI_SPEC")

# Packages to be installed with various compilers
packages=(
    "$FMT_SPEC"
    "$TINYXML2_SPEC"
    "$HDF5_SPEC"
    "$GTEST_SPEC"
)

# Packages to be installed with various compilers and MPI implementations
packages_with_mpi=("$PHDF5_SPEC")

# Tools to be installed only once
packages_once=(
    "$CMAKE_SPEC"
    "$LCOV_SPEC"
    "$HIP_SPEC"
    "$ROCPRIM_SPEC"
    "$ROCTHRUST_SPEC"
)

dir_spack_mirror="/opt/mirror"
cmd_spack_mirror="spack mirror create -D -d $dir_spack_mirror"
cmd_spack_install="spack install --fail-fast -ny"
for i in "${packages_once[@]}"; do
    $cmd_spack_mirror  $i
    $cmd_spack_install  $i %$GCC_SPEC
done

for c in "${compilers[@]}"; do
    for i in "${packages[@]}"; do
        $cmd_spack_mirror $i
        $cmd_spack_install $i %$c
    done

    for m in "${mpis[@]}"; do
        for i in "${packages_with_mpi[@]}"; do
            $cmd_spack_mirror $i
            $cmd_spack_install $i %$c ^$m
        done
    done
done

# Cleanup
spack gc -y
spack clean -a
