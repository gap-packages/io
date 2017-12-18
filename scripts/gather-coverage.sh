#!/usr/bin/env bash
set -ex

# If we don't care about code coverage, do nothing
if [[ -n $NO_COVERAGE ]]; then
    exit 0
fi

GAP="$GAPROOT/bin/gap.sh -l $PWD; --quitonbreak -q"

# generate library coverage reports
$GAP -a 500M -m 500M -q <<GAPInput
if LoadPackage("profiling") <> true then
    Print("ERROR: could not load profiling package");
    FORCE_QUIT_GAP(1);
fi;
d := Directory("$COVDIR");;
covs := [];;
for f in DirectoryContents(d) do
    if f in [".", ".."] then continue; fi;
    Add(covs, Filename(d, f));
od;
Print("Merging coverage results from ", covs, "\n");
r := MergeLineByLineProfiles(covs);;
Print("Outputting JSON\n");
OutputJsonCoverage(r, "gap-coverage.json");;
QUIT_GAP(0);
GAPInput

# generate source coverage reports by running gcov
gcov -o . src/*.c*
