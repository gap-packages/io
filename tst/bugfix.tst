gap> s := List([1..2^18], x->CharInt(Random([63..126])));;
gap> s2 := String(s);; ConvertToStringRep(s2);
gap> cygwinAdjust := Length(IO.LineEndChars) - 1;;
gap> f := IO_File("/dev/null", "w", 65536);;
gap> IO_WriteLine(f, s{[1..30]}) - cygwinAdjust;
31
gap> IO_WriteLine(f, s) - cygwinAdjust;
262145
gap> IO_WriteLine(f, s{[1..2^17]}) - cygwinAdjust;
131073
gap> IO_WriteLine(f, s{[1..2^17+1]}) - cygwinAdjust;
131074
gap> IO_WriteLine(f, s2{[1..30]}) - cygwinAdjust;
31
gap> IO_WriteLine(f, s2) - cygwinAdjust;
262145
gap> IO_WriteLine(f, s2{[1..2^17]}) - cygwinAdjust;
131073
gap> IO_WriteLine(f, s2{[1..2^17+1]}) - cygwinAdjust;
131074
gap> IO_WriteNonBlocking(f, s, 1, 2^10);
Error, Usage: IO_WriteNonBlocking( f, st, pos )
gap> IO_WriteNonBlocking(f, s2, 1, 2^10);
1024
gap> IO_WriteNonBlocking(f, s2, 1, 2^10+1);
1025
gap> IO_Close(f);
true
gap> 
gap> # Without buffering
gap> 
gap> f := IO_File("/dev/null", "w", false);;
gap> IO_WriteLine(f, s{[1..30]}) - cygwinAdjust;
31
gap> IO_WriteLine(f, s) - cygwinAdjust;
262145
gap> IO_WriteLine(f, s{[1..2^17]}) - cygwinAdjust;
131073
gap> IO_WriteLine(f, s{[1..2^17+1]}) - cygwinAdjust;
131074
gap> IO_WriteNonBlocking(f, s, 1, 2^10);
Error, Usage: IO_WriteNonBlocking( f, st, pos )
gap> IO_WriteNonBlocking(f, s2, 1, 2^17);
131072
gap> IO_WriteNonBlocking(f, s2, 1, 2^17+1);
131073
gap> IO_Close(f);
true

# Using ChangeDirectoryCurrent on invalid path should
# return fail, not trigger an internal error
gap> IO_chdir("/foo/bar/this_dir_hopefuly does not EXIST");
fail
gap> ChangeDirectoryCurrent("/foo/bar/this_dir_hopefuly does not EXIST");
fail
