#
gap> dir:=IO_getcwd();;
gap> IsStringRep(dir);
true
gap> IO_chdir("/");
true
gap> IO_getcwd();
"/"
gap> IO_chdir(dir);
true
gap> IO_getcwd() = dir;
true
gap> IO_chdir(fail);
fail

#
gap> IO_stat(fail);
fail
gap> r:=IO_stat(".");; IsRecord(r); Set(RecNames(r));
true
[ "atime", "blksize", "blocks", "ctime", "dev", "gid", "ino", "mode", 
  "mtime", "nlink", "rdev", "size", "uid" ]

#
gap> IO_fstat(fail);
fail
gap> r:=IO_fstat(0);; IsRecord(r); Set(RecNames(r));
true
[ "atime", "blksize", "blocks", "ctime", "dev", "gid", "ino", "mode", 
  "mtime", "nlink", "rdev", "size", "uid" ]

#
gap> IO_lstat(fail);
fail
gap> r:=IO_lstat(".");; IsRecord(r); Set(RecNames(r));
true
[ "atime", "blksize", "blocks", "ctime", "dev", "gid", "ino", "mode", 
  "mtime", "nlink", "rdev", "size", "uid" ]

#
gap> env:=RecNames(GAPInfo.SystemEnvironment)[1];;
gap> IO_getenv(env) = GAPInfo.SystemEnvironment.(env);
true

# find an environment variable name hopefully not yet set
gap> env := Concatenation("GAP_IO_TEST_VAR_", String(Random(10^15,10^16-1)));;
gap> IO_getenv(env);
fail
gap> IO_setenv(env, "A", true);
true
gap> IO_getenv(env);
"A"
gap> IO_setenv(env, "B", false);
true
gap> IO_getenv(env);
"A"
gap> IO_setenv(env, "B", true);
true
gap> IO_getenv(env);
"B"
gap> IO_unsetenv(env);
true
gap> IO_getenv(env);
fail
