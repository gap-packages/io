#!/bin/bash

# This script sleeps, so we can check that GAP exits even if children
# are still running

# We need to close stdin, stdout and stderr so they don't keep open
# GAP's stdin, stdout and stderr.

exec 0>&- # close stdin
exec 1>&- # close stdout
exec 2>&- # close stderr

sleep 3600
