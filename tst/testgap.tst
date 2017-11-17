# List the tests we want to run
gap> d := DirectoriesPackageLibrary("IO", "tst");;
gap> files := ["buffered.g", "compression.g", "http.g", "pickle.g"];;

# We do this 50 times to catch issues with too many files / processes being created

# 1-5
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;

# 6-10
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;

# 11-15
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;

# 16-20
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;

# 21-25
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;

# 26-30
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;

# 31-35
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;

# 36-40
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;

# 41-45
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;

# 46-50
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;
gap> for f in files do Read(Filename(d[1], f)); od;

#
gap> Read(Filename(d[1], "exitcheck.g"));
trying to exit...

#
