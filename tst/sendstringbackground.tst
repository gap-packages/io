gap> f := IO_File("/dev/null", "w");;
gap> IsBound(HPCGAP) or ForAll([1..3000], x -> IO_SendStringBackground(f, "cheese"));
true
gap> IO_Close(f);
true
