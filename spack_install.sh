#!/usr/bin/env bash

set -e

# Compiler specs
GCC_SPEC="gcc"
CLANG_SPEC="clang"

# MPI specs
MPICH_SPEC="mpich@3.3.2"
OPENMPI_SPEC="openmpi@4.0.5"

packages=(
    # developer tools
    "cmake %$GCC_SPEC"
    "lcov@1.14 %$GCC_SPEC"
    # with clang
    "antmoc ~mpi~hip %$CLANG_SPEC"
    # with hip
    "antmoc ~mpi+hip %$GCC_SPEC"
    "antmoc +mpi+hip %$GCC_SPEC ^$MPICH_SPEC"
    # with gcc
    "antmoc ~mpi~hip %$GCC_SPEC"
    "antmoc +mpi~hip %$GCC_SPEC ^$MPICH_SPEC"
    "antmoc +mpi~hip %$GCC_SPEC ^$OPENMPI_SPEC"
)

dir_spack_mirror="/opt/mirror"
cmd_spack_mirror="spack mirror create -D -d $dir_spack_mirror"
cmd_spack_install="spack install --fail-fast -ny"

for i in "${packages[@]}"; do
    echo "==> installing spec $i"
    $cmd_spack_mirror  $i
    $cmd_spack_install $i
done

# Workaround missing llvm-amdgpu
spack mark -a -e llvm-amdgpu

# Cleanup
spack gc -y
spack clean -a

