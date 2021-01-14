#!/usr/bin/env bash

set -euo pipefail

srcdir="${PWD}"
builddir="${PWD}/build"

rm -r "${builddir}"
cmake -GNinja -S "${srcdir}" -B "${builddir}"
(
    cd "${builddir}"
    ninja
    ./tr1.x
    ./normal.x
)
