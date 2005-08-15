# An example using fork:

LoadPackage("io");
IO.InstallSIGCHLDHandler();    # install correct signal handler

pid := IO.fork();
if pid < 0 then
    Error("Cannot fork!");
fi;
if pid > 0 then   # the parent
    Print("Did fork, now waiting for child...\n");
    
    a := IO.WaitPid(pid,true);
    Print("Got ",a," as result of WaitPid.\n");
else
    # the child:
    res := IO.execv("/bin/ls",["/tmp"]);
    Print("execv did not work: ",res);
fi;

pid := IO.fork();
if pid < 0 then
    Error("Cannot fork!");
fi;
if pid > 0 then   # the parent
    repeat
        a := IO.WaitPid(pid,false);
        Print(".\c");
    until a <> false;
    Print("Got ",a," as result of WaitPid.\n");
else
    # the child:
    e := IO.Environment();
    e.myvariable := "xyz";
    res := IO.execve("/usr/bin/env",["/home/neunhoef"],IO.MakeEnvList(e));
    Print("execve did not work: ",res);
fi;

pid := IO.fork();
if pid < 0 then
    Error("Cannot fork!");
fi;
if pid > 0 then   # the parent
    repeat
        a := IO.WaitPid(pid,false);
        Print(".\c");
        Sleep(1);
    until a <> false;
    Print("Got ",a," as result of WaitPid.\n");
else
    # the child:
    res := IO.execvp("sleep",["5"]);
    Print("execvp did not work: ",res);
fi;

