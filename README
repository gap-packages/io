
     =========================================================
      README file for the `IO' GAP4 package (Max Neunhoeffer)
     =========================================================

To get the newest version of this GAP 4 package download the
archive file
    io-x.x.tar.gz
or
    io-x.x.tar.bz2
or
    io-x.x.zip
and unpack it using
    gunzip io-x.x.tar.gz; tar xvf io-x.x.tar
or
    bzip2 -d io-x.x.tar.bz2; tar xvf io-x.x.tar
or
    unzip -x io-x.x.zip
respectively.

Do this in a directory called 'pkg', preferably (but not necessarily)
in the 'pkg' subdirectory of your GAP 4 installation. It creates a
subdirectory called 'io'.

To install this package do

    cd io
    ./configure

If you installed io in another directory than the usual 'pkg'
subdirectory, do
    ./configure --with-gaproot=path
where 'path' is a path to the main GAP root directory.
See
    ./configure --help
for further options.

Afterwards call 'make' to compile a binary file.

The package  will not work without  this  step.

If you installed the package in another 'pkg' directory than the standard
'pkg' directory in your GAP 4 installation, then you have to add the path
to the directory containing your 'pkg' directory to GAP's list of directories.
This can be done by starting GAP with the '-l' command line option
followed by the name of the directory and a semicolon. Then your directory
is prepended to the list of directories searched. Otherwise the package
is not found by GAP. Of course, you can add this option to your GAP
startup script.

If you installed GAP on several architectures, you must execute the
configure/make step for each of the architectures. You can either
do this immediately after configuring and compiling GAP itself on
this architecture, or alternatively (when using version 4.5 of GAP or
newer) set the environment variable "CONFIGNAME" to the name of the
configuration you used when compiling GAP before running "./configure".
Note however that your compiler choice and flags (environment variables
"CC" and "CFLAGS" need to be chosen to match the setup of the original
GAP compilation. For example you have to specify 32-bit or 64-bit mode
correctly!

----------------------------------------------------------------------------

Recompiling the documentation is possible by the command `gap makedoc.g'
in the IO directory. But this should not be necessary.

For bug reports, feature requests and suggestions, please refer to

   https://github.com/neunhoef/io/issues
