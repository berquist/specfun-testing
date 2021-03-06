#!/usr/bin/env bash

set -euo pipefail
#set -v

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOST=$(hostname)

srcdir="${SCRIPTDIR}"
builddir="${srcdir}/build"

outputfile="${srcdir}"/results_"${HOST}".log
if [[ -f "${outputfile}" ]]; then
    rm "${outputfile}"
fi

standards=(98 11 17)

if [[ "$HOST" == "dellman4" ]]; then
    modules=(intel/17.0.5 gnu/5.4.0 gnu/7.2.0 gnu/7.4.0 gnu/9.1.0 gnu/10.1.0)
elif [[ "$HOST" == "coreman4" ]]; then
    modules=(llvm-7.1.0-gcc-9.3.0-lutt6le llvm-9.0.1-gcc-9.3.0-5f5oyzd llvm-10.0.1-gcc-9.3.0-e64v527 llvm-11.0.0-gcc-7.5.0-lix6xtm intel-oneapi-compilers-2021.1.0-gcc-9.3.0-4zfjnvr)
elif [[ "$HOST" == "osmium" ]]; then
    modules=(gcc-5.5.0-gcc-10.2.0-b2izpgj gcc-9.2.0-gcc-8.4.0-fvtn24p gcc-9.3.0-gcc-10.1.0-vptvs3i llvm-11.0.1-gcc-10.2.0-hbzie7q aocc-2.3.0-gcc-10.2.0-3y5aifd)
else
    modules=()
fi

cmakemod="cmake-3.19.2-gcc-5.5.0-pemyvhq"

for module in ${modules[@]}; do
    module load ${module}

    if [[ "$HOST" == "osmium" ]] && [[ "$module" =~ "gcc-5" ]]; then
        module load "$cmakemod"
    fi

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

    for std in ${standards[@]}; do
        if [[ -d "${builddir}" ]]; then
            rm -r "${builddir}"
        fi
        mkdir -p "${builddir}"
        cd "${builddir}"

        cmake \
            -B "${builddir}" \
            -DCMAKE_CXX_COMPILER="${CXX}" \
            -DCMAKE_CXX_FLAGS="-std=c++${std}" \
            "${srcdir}"
        echo "hostname: ${HOST} module: ${module} std: ${std} which: $(command -v $CXX)" >> "${outputfile}"
        set +e
        make -k
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

    if [[ "$HOST" == "osmium" ]] && [[ "$module" =~ "gcc-5" ]]; then
        module unload "$cmakemod"
    fi

    module unload ${module}
done

#set +v
