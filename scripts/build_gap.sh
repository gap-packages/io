#!/usr/bin/env bash
set -ex

# clone GAP into a subdirectory
git clone --depth=2 -b ${GAPBRANCH:-master} https://github.com/gap-system/gap.git $GAPROOT
cd $GAPROOT

# for HPC-GAP, install ward, add suitable flags
if [[ $HPCGAP = yes ]]; then
  git clone https://github.com/gap-system/ward
  cd ward
  CFLAGS= LDFLAGS= ./build.sh
  cd ..
  GAP_CONFIGFLAGS="$GAP_CONFIGFLAGS --enable-hpcgap"
fi

# build GAP in a subdirectory
./autogen.sh
./configure $GAP_CONFIGFLAGS
make -j4 V=1

# download packages; instruct wget to retry several times if the
# connection is refused, to work around intermittent failures
make bootstrap-pkg-full WGET="wget -N --no-check-certificate --tries=5 --waitretry=5 --retry-connrefused"

# build some packages (default is to build 'io' and 'profiling',
# in order to generate coverage results)
cd pkg
for pkg in ${GAP_PKGS_TO_BUILD-io profiling}; do
    ../bin/BuildPackages.sh --strict $pkg*
done
