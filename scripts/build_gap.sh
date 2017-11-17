#!/usr/bin/env bash
set -ex

# clone GAP into a subdirectory
git clone --depth=2 -b ${GAPBRANCH:-master} https://github.com/gap-system/gap.git $GAPROOT
pushd $GAPROOT

# for HPC-GAP we need to install ward
if [[ $HPCGAP = yes ]]
then
  git clone https://github.com/gap-system/ward
  cd ward
  CFLAGS= LDFLAGS= ./build.sh
  cd ..
  GAP_CONFIGFLAGS="$GAP_CONFIGFLAGS --enable-hpcgap"
fi

# build GAP
if [[ x$GAPBRANCH = xstable-4.8 ]]
then
    ./configure --with-gmp=system
else
    ./autogen.sh
    ./configure $GAP_CONFIGFLAGS
fi
# download packages; instruct wget to retry several times if the
# connection is refused, to work around intermittent failures
make bootstrap-pkg-full WGET="wget -N --no-check-certificate --tries=5 --waitretry=5 --retry-connrefused"

make -j4 V=1

if [[ $HPCGAP = yes ]]
then
  # HACK until GAP and package build systems are improved:
  # Add flags so that Boehm GC and libatomic headers are found
  CPPFLAGS="-I$GAPROOT/extern/install/gc/include -I$GAPROOT/extern/install/libatomic_ops/include $CPPFLAGS"
  export CPPFLAGS
fi

# build some packages...
PKG_CONFIGFLAGS=
if [[ $ABI == 32 ]]
then
    PKG_CONFIGFLAGS="CFLAGS=-m32 LDFLAGS=-m32 LOPTS=-m32 CXXFLAGS=-m32"
fi
cd pkg

# remove bundled IO -- we are testing the IO package, after all
rm -rf io*

# install latest version of profiling
rm -rf profiling*
git clone https://github.com/gap-packages/profiling
cd profiling
./autogen.sh
# HACK to workaround problems when building with clang
if [[ $CC = clang ]]
then
    export CXX=clang++
fi
./configure $PKG_CONFIGFLAGS
make -j4 V=1
cd ..

# link our package into the pkg dir
ln -s $TRAVIS_BUILD_DIR $GAPROOT/pkg/
