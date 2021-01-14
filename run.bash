#!/usr/bin/env bash

set -euo pipefail

set -v

# module load ninja

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

srcdir="${SCRIPTDIR}"
builddir="${srcdir}/build"

outputfile="${srcdir}"/results_"${HOSTNAME}".log
if [[ -f "${outputfile}" ]]; then
    rm "${outputfile}"
fi

if [[ "$HOSTNAME" == "dellman4" ]]; then
    modules=(intel/17.0.5 gnu/5.4.0 gnu/7.2.0 gnu/7.4.0 gnu/9.1.0 gnu/10.1.0)
elif [[ "$HOSTNAME" == "coreman4" ]]; then
    module=(llvm-11.0.0-gcc-7.5.0-lix6xtm intel-oneapi-compilers-2021.1.0-gcc-9.3.0-4zfjnvr)
else
    module=()
fi

for module in ${modules[@]}; do
    module load ${module}
    for std in 98 11 17; do
        if [[ -d "${builddir}" ]]; then
            rm -r "${builddir}"
        fi
        mkdir -p "${builddir}"
        cd "${builddir}"

        if test "$(command -v icpc)"; then
            CXX=icpc
        elif test "$(command -v icpx)"; then
            CXX=icpx
        elif test "$(command -v clang++)"; then
            CXX=clang++
        else
            CXX=g++
        fi

        cmake \
            -B "${builddir}" \
            -DCMAKE_CXX_COMPILER="${CXX}" \
            -DCMAKE_CXX_FLAGS="-std=c++${std}" \
            "${srcdir}"
        #     -GNinja \
            # ninja
        echo "hostname: ${HOSTNAME} module: ${module} std: ${std}" >> "${outputfile}"
        set +e
        VERBOSE=1 make
        md5sum "${builddir}"/tr1.x >> "${outputfile}"
        md5sum "${builddir}"/normal.x >> "${outputfile}"
        "${builddir}"/tr1.x >> "${outputfile}"
        "${builddir}"/normal.x >> "${outputfile}"
        set -e
        echo "" >> "${outputfile}"
        cd "${srcdir}"
        if [[ -d "${builddir}" ]]; then
            rm -r "${builddir}"
        fi
    done
    module unload ${module}
done

# module unload ninja
set +v
