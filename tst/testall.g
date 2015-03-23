LoadPackage("IO");
d := DirectoriesPackageLibrary("IO", "tst");
Test(Filename(d, "bugfix.tst"));
Read("testgap.g");