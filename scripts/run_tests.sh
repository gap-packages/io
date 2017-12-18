#!/usr/bin/env bash
set -ex

GAP="$GAPROOT/bin/gap.sh -l $PWD; --quitonbreak"

# unless explicitly turned off, we collect coverage data
if [[ -z $NO_COVERAGE ]]; then
    mkdir $COVDIR
    GAP="$GAP --cover $COVDIR/test.coverage"
fi

$GAP tst/testall.g
