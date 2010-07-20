#############################################################################
##
##  background.gi               GAP 4 package IO
##                                                           Max Neunhoeffer
##
##  Copyright (C) 2006-2010 by Max Neunhoeffer
##
##  This file is free software, see license information at the end.
##
##  This file contains the implementations for background jobs using fork.
##

InstallMethod(BackgroundJobByFork, "for a function and a list",
  [IsFunction, IsList],
  function(fun, args)
    return BackgroundJobByFork(fun, args, rec());
  end );

InstallValue(BackgroundJobByForkOptions,
  rec(
    TerminateImmediately := false,
    BufferSize := 8192,
  ));

InstallMethod(BackgroundJobByFork, "for a function, a list and a record",
  [IsFunction, IsList, IsRecord],
  function(fun, args, opt)
    local j, n;
    IO_InstallSIGCHLDHandler();
    for n in RecNames(BackgroundJobByForkOptions) do
        if not(IsBound(opt.(n))) then 
            opt.(n) := BackgroundJobByForkOptions.(n);
        fi;
    od;
    j := rec( );
    j.childtoparent := IO_pipe();
    if j.childtoparent = fail then
        Info(InfoIO, 1, "Could not create pipe.");
        return fail;
    fi;
    if opt.TerminateImmediately then
        j.parenttochild := false;
    else
        j.parenttochild := IO_pipe();
        if j.parenttochild = fail then
            IO_close(j.childtoparent.toread);
            IO_close(j.childtoparent.towrite);
            Info(InfoIO, 1, "Could not create pipe.");
            return fail;
        fi;
    fi;
    j.pid := IO_fork();
    if j.pid = 0 then
        # we are in the child:
        IO_close(j.childtoparent.toread);
        j.childtoparent := IO_WrapFD(j.childtoparent.towrite,
                                     false, opt.BufferSize);
        if j.parenttochild <> false then
            IO_close(j.parenttochild.towrite);
            j.parenttochild := IO_WrapFD(j.parenttochild.toread,
                                         opt.BufferSize, false);
        fi;
        BackgroundJobByForkChild(j, fun, args);
        IO_exit(0);  # just in case
    fi;
    # Here we are in the parent:
    IO_close(j.childtoparent.towrite);
    j.childtoparent := IO_WrapFD(j.childtoparent.toread,
                                 opt.BufferSize, false);
    if j.parenttochild <> false then
        IO_close(j.parenttochild.toread);
        j.parenttochild := IO_WrapFD(j.parenttochild.towrite,
                                     false, opt.BufferSize);
    fi;
    j.idle := false;
    j.terminated := false;
    j.result := false;
    Objectify(BGJobByForkType, j);
    return j;
  end );

InstallGlobalFunction(BackgroundJobByForkChild,
  function(j, fun, args)
    local ret;
    while true do   # will be left by break
        ret := CallFuncList(fun, args);
        IO_Pickle(j.childtoparent, ret);
        IO_Flush(j.childtoparent);
        if j.parenttochild = false then break; fi;
        args := IO_Unpickle(j.parenttochild);
        if not(IsList(args)) then break; fi;
    od;
    IO_Close(j.childtoparent);
    if j.parenttochild <> false then
        IO_Close(j.parenttochild);
    fi;
    IO_exit(0);
  end);

InstallMethod(IsIdle, "for a background job by fork",
  [IsBackgroundJobByFork],
  function(j)
    if j!.terminated then return fail; fi;
    if j!.idle = true or j!.idle = fail then return j!.idle; fi;
    if IO_HasData(j!.childtoparent) then
        j!.result := IO_Unpickle(j!.childtoparent);
        if j!.result = IO_Nothing or j!.result = IO_Error then
            j!.result := fail;
            j!.terminated := true;
            j!.idle := fail;
            IO_Close(j!.childtoparent);
            IO_WaitPid(j!.pid,true);
            return fail;
        fi;
        j!.idle := true;
        return true;
    fi;
    return false;
  end);

InstallMethod(HasTerminated, "for a background job by fork",
  [IsBackgroundJobByFork],
  function(j)
    if j!.terminated then return true; fi;
    if j!.idle = true then return false; fi;
    if not(IO_HasData(j!.childtoparent)) then
        return false;
    fi;
    j!.result := IO_Unpickle(j!.childtoparent);
    if j!.result = IO_Nothing or j!.result = IO_Error then
        j!.result := fail;
        j!.terminated := true;
        j!.idle := fail;
        IO_Close(j!.childtoparent);
        IO_WaitPid(j!.pid,true);
        return true;
    fi;
    j!.idle := true;
    return false;
  end);

InstallMethod(WaitUntilIdle, "for a background job by fork",
  [IsBackgroundJobByFork],
  function(j)
    local fd,idle,l;
    idle := IsIdle(j);
    if idle = true then return j!.result; fi;
    if idle = fail then return fail; fi;
    fd := IO_GetFD(j!.childtoparent);
    l := [fd];
    IO_select(l,[],[],false,false);
    j!.result := IO_Unpickle(j!.childtoparent);
    if j!.result = IO_Nothing or j!.result = IO_Error then
        j!.result := fail;
        j!.terminated := true;
        j!.idle := fail;
        IO_Close(j!.childtoparent);
        IO_WaitPid(j!.pid,true);
        return fail;
    fi;
    j!.idle := true;
    return j!.result;
  end);
 
InstallMethod(Kill, "for a background job by fork",
  [IsBackgroundJobByFork],
  function(j)
    if j!.terminated then return; fi;
    IO_kill(j!.pid,IO.SIGTERM);
    IO_WaitPid(j!.pid,true);
    j!.idle := fail;
    j!.terminated := true;
    j!.result := fail;
  end);

InstallMethod(ViewObj, "for a background job by fork",
  [IsBackgroundJobByFork],
  function(j)
    local idle;
    Print("<background job by fork pid=",j!.pid);
    idle := IsIdle(j);
    if idle = true then 
        Print(" currently idle>"); 
    elif idle = fail then
        Print(" already terminated>");
    else
        Print(" busy>");
    fi;
  end);

InstallMethod(GetResult, "for a background job by fork",
  [IsBackgroundJobByFork],
  function(j)
    return WaitUntilIdle(j);
  end);

InstallMethod(SendArguments, "for a background job by fork and an object",
  [IsBackgroundJobByFork, IsObject],
  function(j,o)
    local idle,res;
    if j!.parenttochild = false then
        Error("job terminated immediately after finishing computation");
        return fail;
    fi;
    idle := IsIdle(j);
    if idle = false then
        Error("job must be idle to send the next argument list");
        return fail;
    elif idle = fail then
        Error("job has already terminated");
        return fail;
    fi;
    res := IO_Pickle(j!.parenttochild,o);
    if res <> IO_OK then
        Info(InfoIO, 1, "problems sending argument list", res);
        return fail;
    fi;
    IO_Flush(j!.parenttochild);
    j!.idle := false;
    return true;
  end);

f := function(n,k)
  local i;
  for i in [1..n] do
    Sleep(k);
    Print("Hallo ",i,"/",n,"\n");
  od;
  return true;
end;

InstallMethod(ParTakeFirstResultByFork, "for two lists and a record",
  [IsList, IsList, IsRecord],
  function(jobs, args, opt)

  end);


##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; version 2 of the License.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
##
