#!/bin/sh
#
# Regenerate configure from configure.ac. Requires GNU autoconf.
set -ex
mkdir -p gen
autoconf -Wall -f
autoheader -Wall -f
