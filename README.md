[![Build Status](https://github.com/gap-packages/io/workflows/CI/badge.svg?branch=master)](https://github.com/gap-packages/io/actions?query=workflow%3ACI+branch%3Amaster)
[![Code Coverage](https://codecov.io/github/gap-packages/io/coverage.svg?branch=master&token=)](https://codecov.io/gh/gap-packages/io)

# README file for the IO GAP4 package

To get the newest version of this GAP 4 package download the
archive file

    io-x.x.tar.gz

and unpack it using

    gunzip io-x.x.tar.gz; tar xvf io-x.x.tar

Do this in a directory called `pkg`, preferably (but not necessarily)
in the `pkg` subdirectory of your GAP 4 installation. It creates a
subdirectory called `io`.

To install this package do

    cd io
    ./configure

If you installed io in another directory than the usual `pkg`
subdirectory, do

    ./configure --with-gaproot=path

where `path` is a path to the main GAP root directory.
See

    ./configure --help

for further options.

Afterwards call `make` to compile a binary file.

The package willnot work without this step.

If you installed the package in another `pkg` directory than the standard
`pkg` directory in your GAP 4 installation, then you have to add the path
to the directory containing your `pkg` directory to GAP's list of directories.
This can be done by starting GAP with the `-l` command line option
followed by the name of the directory and a semicolon. Then your directory
is prepended to the list of directories searched. Otherwise the package
is not found by GAP. Of course, you can add this option to your GAP
startup script.

----------------------------------------------------------------------------

Recompiling the documentation is possible by the command `gap makedoc.g`
in the IO directory. But this should not be necessary.

For bug reports, feature requests and suggestions, please refer to

   <https://github.com/gap-packages/io/issues>
