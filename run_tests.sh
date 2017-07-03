#!/usr/bin/env bash

set -e

mkdir tmp
cd tmp

# configure and make GAP
git clone --depth=1 https://github.com/gap-system/gap.git gap
cd gap
GAPROOT=`pwd`
./autogen.sh

if [[ $1 == hpcgap ]]
then
    # for HPC-GAP we install ward
    git clone https://github.com/gap-system/ward
    cd ward
    CFLAGS= LDFLAGS= ./build.sh
    cd ..
    CONFIGFLAGS="$CONFIGFLAGS --enable-hpcgap"
fi

# configure and make GAP
./configure $CONFIGFLAGS
make -j4

# download packages; instruct wget to retry several times if the
# connection is refused, to work around intermittent failures
make bootstrap-pkg-full WGET="wget -N --no-check-certificate --tries=5 --waitretry=5 --retry-connrefused"

if [[ $1 == hpcgap ]]
then
  # FIXME/HACK: Add flags so that Boehm GC and libatomic headers are found
  CPPFLAGS="-I$GAPROOT/extern/install/gc/include -I$GAPROOT/extern/install/libatomic_ops/include $CPPFLAGS"
  export CPPFLAGS
fi


# Build this package (IO)
cd pkg
rm -rf io*
ln -s ../../.. io
cd io
sh autogen.sh
./configure
make
cd ../..

# Run actual tests
echo "Read(\"pkg/io/tst/testall.g\"); QUIT_GAP(0);" | sh bin/gap.sh --quitonbreak -q
