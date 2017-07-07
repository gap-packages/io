gap> START_TEST("waitpid.tst");
gap> LoadPackage("IO", false);;
gap> returnval := function(val)
> local ret, pid;
> pid := IO_fork();
> if pid > 0 then
>   return IO_WaitPid(pid, true);
> else
>   FORCE_QUIT_GAP(val);
> fi;
> end;;
gap> ret := returnval(1);;
gap> [ret.WEXITSTATUS, ret.WIFEXITED];
[ 1, 1 ]
gap> ret := returnval(0);;
gap> [ret.WEXITSTATUS, ret.WIFEXITED];
[ 0, 1 ]
gap> ret := returnval(200);;
gap> [ret.WEXITSTATUS, ret.WIFEXITED];
[ 200, 1 ]
gap> STOP_TEST( "waitpid.tst", 1);
