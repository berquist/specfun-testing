#!/usr/bin/env bash

set -euo pipefail
set -v

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOST=$(hostname)

srcdir="${SCRIPTDIR}"
builddir="${srcdir}/build"

outputfile="${srcdir}"/results_"${HOST}".log
if [[ -f "${outputfile}" ]]; then
    rm "${outputfile}"
fi

if [[ "$HOST" == "dellman4" ]]; then
    modules=(intel/17.0.5 gnu/5.4.0 gnu/7.2.0 gnu/7.4.0 gnu/9.1.0 gnu/10.1.0)
elif [[ "$HOST" == "coreman4" ]]; then
    modules=(llvm-11.0.0-gcc-7.5.0-lix6xtm intel-oneapi-compilers-2021.1.0-gcc-9.3.0-4zfjnvr)
elif [[ "$HOST" == "osmium" ]]; then
    modules=(gcc-9.2.0-gcc-8.4.0-fvtn24p gcc-9.3.0-gcc-10.1.0-vptvs3i llvm-11.0.1-gcc-10.2.0-hbzie7q aocc-2.3.0-gcc-10.2.0-3y5aifd)
else
    modules=()
fi

for module in ${modules[@]}; do
    module load ${module}
    for std in 98 11 17; do
        if [[ -d "${builddir}" ]]; then
            rm -r "${builddir}"
        fi
        mkdir -p "${builddir}"
        cd "${builddir}"

        if [[ "$module" =~ "intel-oneapi" ]]; then
            CXX=icpx
        elif [[ "$module" =~ "intel" ]]; then
            CXX=icpc
        elif [[ "$module" =~ "llvm" ]] || [[ "$module" =~ "aocc" ]]; then
            CXX=clang++
        elif [[ "$module" =~ "gcc" ]] || [[ "$module" =~ "gnu" ]]; then
            CXX=g++
        else
            exit 99
        fi

        cmake \
            -B "${builddir}" \
            -DCMAKE_CXX_COMPILER="${CXX}" \
            -DCMAKE_CXX_FLAGS="-std=c++${std}" \
            "${srcdir}"
        echo "hostname: ${HOST} module: ${module} std: ${std} which: $(command -v $CXX)" >> "${outputfile}"
        set +e
        make
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

set +v
