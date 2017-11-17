# the check.pl script only exists in GAP 4.9 and later
gap> d := DirectoryCurrent();;
gap> scriptdir := DirectoriesLibrary( "tst/teststandard/processes/" );;
gap> if scriptdir <> fail then
>   checkpl := Filename(scriptdir, "check.pl");
> else
>   checkpl := fail;
> fi;

#
gap> runChild := function(ms, ignoresignals, useio)
>    local signal;
>    if ignoresignals then signal := "1"; else signal := "0"; fi;
>    if useio then
>      return IO_Popen(checkpl, [String(time), signal], "r");
>    else
>      return InputOutputLocalProcess(d, checkpl, [ String(time), signal]);
>    fi;
>  end;;

# if checkpl exists, GAP is also up-to-date enough to support
# this test!
gap> if checkpl <> fail then
>   for i in [1..200] do
>     args := List([1..20], x -> [Random([1..2000]), Random([false,true]), Random([false,true])]);
>     children := List(args, x -> CallFuncList(runChild, x) );
>     if ForAny(children, x -> x=fail) then Print("Failed producing child\n"); fi;
>     for c in children do
>       if IsFile(c) then
>           IO_Close(c);
>       else
>           CloseStream(c);
>       fi;
>     od;
>   od;
> fi;
