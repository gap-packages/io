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
