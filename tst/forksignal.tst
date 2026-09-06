gap> START_TEST("forksignal.tst");
gap> LoadPackage("IO", false);;

# A child created by IO_fork must be terminable via SIGTERM even if the
# hosting process blocks signals (e.g. julia embedding GAP via GAP.jl):
# IO_fork resets the child's signal mask. Poll with a bounded timeout so
# a regression fails instead of hanging.
gap> p := IO_pipe();;
gap> pid := IO_fork();;
gap> if pid = 0 then
>   # child: close the inherited line-by-line profile/coverage output (GAP
>   # opens a per-child file; killed by a signal it would stay truncated),
>   # tell the parent we are ready, then sleep, and exit in case the
>   # SIGTERM below never arrives
>   if IsLineByLineProfileActive() then UnprofileLineByLine(); fi;
>   IO_write(p.towrite, "r", 0, 1);
>   IO_select([], [], [], 60, 0);
>   IO_exit(0);
> fi;
gap> pid > 0;
true
gap> ready := "";;
gap> IO_read(p.toread, ready, 0, 1);
1
gap> IO_kill(pid, IO.SIGTERM);
true
gap> ret := false;;
gap> for i in [1..100] do
>   ret := IO_WaitPid(pid, false);
>   if ret <> false then break; fi;
>   IO_select([], [], [], 0, 100000);
> od;

# ret = false means the child survived SIGTERM for 10 seconds
gap> IsRecord(ret) and ret.pid = pid;
true
gap> if ret = false then IO_kill(pid, IO.SIGKILL); IO_WaitPid(pid, true); fi;
gap> IO_close(p.toread);;
gap> IO_close(p.towrite);;
gap> STOP_TEST("forksignal.tst", 1);
