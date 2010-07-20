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

InstallValue(BackGroundJobByForkOptions,
  rec(
    TerminateImmediatly := false,
    BufferSize := 8192,
  ));

InstallMethod(BackgroundJobByFork, "for a function, a list and a record",
  [IsFunction, IsList, IsRecord],
  function(fun, args, opt)
    local j,n;
    IO_InstallSIGCHLDHandler();
    for n in RecNames(BackgroundJobByForkOptions) do
        if not(IsBound(opt.(n))) then 
            opt.(n) := BackGroundJobByForkOptions.(n);
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
        j.childtoparent := IO_WrapFD(j.childtoparent,false,opt.BufferSize);
        if j.parenttochild <> false then
            IO_close(j.parenttochild.towrite);
            j.parenttochild := IO_WrapFD(j.parenttochild,opt.BufferSize,false);
        fi;
        BackgroundJobByForkChild(j,fun,args);
        IO_exit(0);  # just in case
    fi;
    #...
  end );

InstallGlobalFunction(BackgroundJobByForkChild,
  function(j, fun, args)
    local ret;
    while true do   # will be left by break
        ret := CallFuncList(func,args);
        IO_Pickle(j.childtoparent,ret);
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
