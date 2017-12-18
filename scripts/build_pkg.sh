#!/usr/bin/env bash
set -ex

# ensure coverage is turned on
export CFLAGS="$CFLAGS -fprofile-arcs -ftest-coverage"
export LDFLAGS="$LDFLAGS -fprofile-arcs"

if [[ $ABI = 32 ]]; then
    export CFLAGS="$CFLAGS -m32"
    export LDFLAGS="$LDFLAGS -m32"
fi

# build this package
if [[ -x autogen.sh ]]; then
    ./autogen.sh
    ./configure --with-gaproot=$GAPROOT
    make -j4 V=1
elif [[ -x configure ]]; then
    ./configure $GAPROOT
    make -j4
fi

# trick to allow the package directory to be used as a GAP root dir
ln -s . pkg
