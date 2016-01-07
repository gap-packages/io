LoadPackage("IO");
d := DirectoriesPackageLibrary("IO", "tst");

# Too many things in this directory, we'll just list the tests we want to run
files := ["buffered.g", "compression.g", "http.g", "pickle.g"];

# We do this 50 times to catch issues with too many files / processes being created
for i in [1..50] do
  Print("Iteration #", i, "\n");
  for f in files do
     Read(Filename(d[1], f));
  od;
od;

Read(Filename(d[1], "exitcheck.g"));
