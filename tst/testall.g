LoadPackage("IO");
IO_InstallSIGCHLDHandler();
d := DirectoriesPackageLibrary("IO", "tst");
Test(Filename(d, "bugfix.tst"));
Read(Filename(d, "testgap.g"));
