LoadPackage("IO");
Print("A!\n");
d := DirectoriesPackageLibrary("IO", "tst");
Print("B!\n");
Test(Filename(d, "bugfix.tst"));
Print("C!\n");
Read(Filename(d, "testgap.g"));
Print("D!\n");
