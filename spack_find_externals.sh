#!/usr/bin/env bash

externals=(
    gcc
    llvm
    autoconf
    automake
    libtool
    perl
)

for i in "${externals[@]}"; do
    spack external find --scope system --not-buildable $i
done

