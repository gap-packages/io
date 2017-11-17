LoadPackage("IO");
d := DirectoriesPackageLibrary("IO", "tst");
Test(Filename(d, "bugfix.tst"));
Test(Filename(d, "children.tst"));
Read(Filename(d, "testgap.g"));
