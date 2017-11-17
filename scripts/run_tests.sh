#!/usr/bin/env bash
set -ex

GAP="$GAPROOT/bin/gap.sh --quitonbreak"

mkdir $COVDIR
$GAP --cover $COVDIR/test.coverage tst/testall.g
