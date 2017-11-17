#!/usr/bin/env bash
set -ex

# ensure coverage is turned on
export CFLAGS="$CFLAGS -fprofile-arcs -ftest-coverage"
export LDFLAGS="$LDFLAGS -fprofile-arcs"

if [[ $ABI = 32 ]]
then
    export CFLAGS="$CFLAGS -m32"
    export LDFLAGS="$LDFLAGS -m32"
fi

if [[ $HPCGAP = yes ]]
then
  # HACK until GAP and package build systems are improved:
  # Add flags so that Boehm GC and libatomic headers are found
  CPPFLAGS="-I$GAPROOT/extern/install/gc/include -I$GAPROOT/extern/install/libatomic_ops/include $CPPFLAGS"
  export CPPFLAGS
fi


# build this package
if [[ -x autogen.sh ]]
then
    ./autogen.sh
    ./configure --with-gaproot=$GAPROOT
    make -j4 V=1
fi
