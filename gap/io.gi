#############################################################################
##
#W  io.gi               GAP 4 package `IO'                    Max Neunhoeffer
##
#Y  Copyright (C)  2005,  Lehrstuhl D fuer Mathematik,  RWTH Aachen,  Germany
##
##  This file contains functions mid level IO providing buffering and
##  easier access from the GAP level. 
##

################################
# First look after our C part: #
################################

# load kernel function if it is installed:
if (not IsBound(IO)) and ("io" in SHOW_STAT()) then
  # try static module
  LoadStaticModule("io");
fi;
if (not IsBound(IO)) and
   (Filename(DirectoriesPackagePrograms("io"), "io.so") <> fail) then
  LoadDynamicModule(Filename(DirectoriesPackagePrograms("io"), "io.so"));
fi;

#####################################
# Then some technical preparations: #
#####################################

# The family:

BindGlobal( "FileFamily", NewFamily("FileFamily", IsFile) );

# The type:
InstallValue( FileType,
  NewType(FileFamily, IsFile and IsAttributeStoringRep));


# one can now create objects by doing:
# r := rec( ... )
# Objectify(FileType,r);

IO.LineEndChars := "\n";
IO.LineEndChar := '\n';
if ARCH_IS_MAC() then
    IO.LineEndChars := "\r";
    IO.LineEndChar := '\r';
elif ARCH_IS_WINDOWS() then
    IO.LineEndChars := "\r\n";
fi;

###########################################################################
# Now the functions to create and work with objects in the filter IsFile: #
###########################################################################

IO.WrapFD := function(fd,rbuf,wbuf)
  # fd: a small integer (a file descriptor).
  # rbuf: either false (for unbuffered) or a size for the read buffer size
  # wbuf: either false (for unbuffered) or a size for the write buffer size
  # rbuf can also be a string in which case fd must be -1 and we get
  # a File object that reads from that string.
  # wbuf can also be a string in which case fd must be -1 and we get
  # a File object that writes to that string by appending.
  local f;
  f := rec(fd := fd, 
           rbufsize := rbuf, 
           wbufsize := wbuf,
           closed := false);
  if f.rbufsize <> false then
      if IsInt(f.rbufsize) then
          f.rbuf := "";  # this can grow up to r.bufsize
          f.rpos := 1;
          f.rdata := 0;  # nothing in the buffer up to now
      else
          f.fd := -1;
          f.rbuf := f.rbufsize;
          f.rbufsize := Length(f.rbuf);
          f.rpos := 1;
          f.rdata := Length(f.rbuf);
      fi;
  fi;
  if f.wbufsize <> false then
      if IsInt(f.wbufsize) then
          f.wbuf := "";
          f.wdata := 0;  # nothing in the buffer up to now
      else
          f.fd := -1;
          f.wbuf := f.wbufsize;
          f.wbufsize := infinity;
          f.wdata := Length(f.wbuf);
      fi;
  fi;
  return Objectify(FileType,f);
end;

IO.DefaultBufSize := 65536;

# A convenience function for files on disk:
IO.File := function( arg )
  # arguments: filename [,mode]
  # filename is a string and mode can be:
  #   "r" : open for reading only (default)
  #   "w" : open for writing only, possibly creating/truncating
  #   "a" : open for appending
  local fd,filename,mode;
  if Length(arg) = 1 then
      filename := arg[1];
      mode := "r";
  elif Length(arg) = 2 then
      filename := arg[1];
      mode := arg[2];
  else
      Error("IO: Usage: IO.File( filename [,mode] ) with IsString(filename)");
  fi;
  if not(IsString(filename)) and not(IsString(mode)) then
      Error("IO: Usage: IO.File( filename [,mode] ) with IsString(filename)");
  fi;
  if mode = "r" then
      fd := IO.open(filename,IO.O_RDONLY,0);
      if fd = fail then return fail; fi;
      return IO.WrapFD(fd,IO.DefaultBufSize,false);
  elif mode = "w" then
      fd := IO.open(filename,IO.O_CREAT+IO.O_WRONLY+IO.O_TRUNC,
                    IO.S_IRUSR+IO.S_IWUSR+IO.S_IRGRP+IO.S_IWGRP+
                    IO.S_IROTH+IO.S_IWOTH);
      if fd = fail then return fail; fi;
      return IO.WrapFD(fd,false,IO.DefaultBufSize);
  elif mode = "a" then
      fd := IO.open(filename,IO.O_APPEND+IO.O_WRONLY,0);
      if fd = fail then return fail; fi;
      return IO.WrapFD(fd,false,IO.DefaultBufSize);
  else
      Error("IO: Mode not supported!");
  fi;
end;

# A nice View method:
InstallMethod( ViewObj, "for IsFile objects", [IsFile],
  function(f)
    if f!.closed then
        Print("<closed file fd=");
    else
        Print("<file fd=");
    fi;
    Print(f!.fd);
    if f!.rbufsize <> false then
        Print(" rbufsize=",f!.rbufsize," rpos=",f!.rpos," rdata=",f!.rdata);
    fi;
    if f!.wbufsize <> false then
        Print(" wbufsize=",f!.wbufsize," wdata=",f!.wdata);
    fi;
    Print(">");
  end);

# Now a convenience function for closing:
IO.Close := function( f )
  # f must be an object of type IsFile
  if not(IsFile(f)) or f!.closed then
      return fail;
  fi;
  # First flush if necessary:
  if f!.wbufsize <> false and f!.wdata <> 0 then
      IO.Flush( f );
  fi;
  f!.closed := true;
  f!.rbufsize := false;
  f!.wbufsize := false;
  # to free the memory for the buffer
  f!.rbuf := fail;
  f!.wbuf := fail;
  if f!.fd <> -1 then
      return IO.close(f!.fd);
  else
      return true;
  fi;
end;

# The buffered read functionality:
IO.Read := function( arg )
  # arguments: f [,length]
  # f must be an object of type IsFile
  # length is a maximal length
  # Reads up to length bytes or until end of file if length is not specified.
  local amount,bytes,f,len,res;
  if Length(arg) = 1 then
      f := arg[1];
      len := -1;
  elif Length(arg) = 2 then
      f := arg[1];
      len := arg[2];
  else
      Error("Usage: IO.Read( f [,len] ) with IsFile(f) and IsInt(len)");
  fi;
  if not(IsFile(f)) or not(IsInt(len)) then
      Error("Usage: IO.Read( f [,len] ) with IsFile(f) and IsInt(len)");
  fi;
  if f!.closed then
      Error("Tried to read from closed file.");
  fi;
  if len = -1 then   
      # Read until end of file:
      if f!.rbufsize <> false and f!.rdata <> 0 then   # we read buffered:
          # First empty the buffer:
          res := f!.rbuf{[f!.rpos..f!.rpos+f!.rdata-1]};
          f!.rpos := 1;
          f!.rdata := 0;
      else
          res := "";
      fi;   
      # Now read on:
      if f!.fd = -1 then
          return res;
      fi;
      repeat
          bytes := IO.read(f!.fd,res,Length(res),f!.rbufsize);
          if bytes = fail then return fail; fi;
      until bytes = 0;
      return res;
  else   
      res := "";
      # First the case of no buffer:
      if f!.rbufsize = false then
          while Length(res) < len do
              bytes := IO.read(f!.fd,res,Length(res),len - Length(res));
              if bytes = fail then
                  return fail;
              fi;
              if bytes = 0 then
                  return res;
              fi;
          od;
          return res;
      fi;
      # read up to len bytes, using our buffer:     
      while Length(res) < len do
          # First empty the buffer:
          if f!.rdata > len - Length(res) then   # more data available
              amount := len - Length(res);
              Append(res,f!.rbuf{[f!.rpos..f!.rpos+amount-1]});
              f!.rpos := f!.rpos + amount;
              f!.rdata := f!.rdata - amount;
              return res;
          else
              Append(res,f!.rbuf{[f!.rpos..f!.rpos+f!.rdata-1]});
              f!.rpos := 1;
              f!.rdata := 0;
          fi;
          if f!.fd = -1 then
              return res;
          fi;
          if len - Length(res) > f!.rbufsize then   
              # In this case we read the whole thing:
              bytes := IO.read(f!.fd,res,Length(res),len - Length(res));
              if bytes = fail then 
                  return fail;
              elif bytes = 0 then 
                  return res;
              fi;
          fi; 
          # Now the buffer is empty, so refill it:
          bytes := IO.read(f!.fd,f!.rbuf,0,f!.rbufsize);
          if bytes = fail then
              return fail;
          elif bytes = 0 then
              return res;
          fi;
          f!.rdata := bytes;
      od;
      return res;
  fi;
end;

IO.ReadLine := function( f )
  # f must be an object of type IsFile
  # The IO.LineEndChars are not removed at the end
  local bytes,pos,res;
  if not(IsFile(f)) then
      Error("Usage: IO.ReadLine( f ) with IsFile(f)");
  fi;
  if f!.closed then
      Error("Tried to read from closed file.");
  fi;
  if f!.rbufsize = false then
      Error("IO: Readline not possible for unbuffered files.");
  fi;
  res := "";
  while true do
      # First try to find a line end within the buffer:
      pos := Position(f!.rbuf,IO.LineEndChar,f!.rpos-1);
      if pos <> fail and pos < f!.rpos + f!.rdata then
          # The line is completely within the buffer
          Append(res,f!.rbuf{[f!.rpos..pos]});
          f!.rdata := f!.rdata - (pos + 1 - f!.rpos);
          f!.rpos := pos + 1;
          return res;
      else
          Append(res,f!.rbuf{[f!.rpos..f!.rpos + f!.rdata - 1]});
          f!.rpos := 1;
          f!.rdata := 0;
          if f!.fd = -1 then
              return res;
          fi;
          # Now read more data into buffer:
          bytes := IO.read(f!.fd,f!.rbuf,0,f!.rbufsize);
          if bytes = fail then
              return fail;
          fi;
          if bytes = 0 then   # we are at end of file
              return res;
          fi;
          f!.rdata := bytes;
      fi;
  od;
end;

IO.ReadLines := function (arg)
  # arguments: f [,maxlines]
  # f must be an object of type IsFile
  # maxlines is the maximal number of lines read
  # Reads lines (max. maxlines or until end of file) and returns a list
  # of strings, which are the lines.
  local f,l,li,max;
  if Length(arg) = 1 then
      f := arg[1];
      max := infinity;
  elif Length(arg) = 2 then
      f := arg[1];
      max := arg[2];
  else
      Error("Usage: IO.ReadLines( f [,max] ) with IsFile(f) and IsInt(max)");
  fi;
  if not(IsFile(f)) or not(IsInt(max) or max = infinity) then
      Error("Usage: IO.ReadLines( f [,max] ) with IsFile(f) and IsInt(max)");
  fi;
  if f!.closed then
      Error("Tried to read from closed file.");
  fi;
  li := [];
  while Length(li) < max do
      l := IO.ReadLine(f);
      if l = fail then 
          return fail;
      fi;
      if Length(l) = 0 then
          return li;
      fi;
      Add(li,l);
  od;
  return li;
end;

# The buffered write functionality:
IO.Write := function( arg )
  # arguments: f {,things ... }
  # f must be an object of type IsFile
  # all other arguments: either they are strings, in which case they are
  # written directly, otherwise they are converted to strings with "String"
  # and the result is being written.
  local bytes,f,i,pos,pos2,st,sumbytes;
  if Length(arg) < 2 or not(IsFile(arg[1])) then
      Error("Usage: IO.Write( f ,things ... ) with IsFile(f)");
  fi;
  f := arg[1];
  if f!.closed then
      Error("Tried to write on closed file.");
  fi;
  if Length(arg) = 2 and IsString(arg[2]) then
      # This is the main buffered Write functionality, all else delegates here:
      st := arg[2];
      # Do we buffer?
      if f!.wbufsize = false then
          pos := 0;
          while pos < Length(st) do
              bytes := IO.write(f!.fd,st,pos,Length(st));
              if bytes = fail then
                  return fail;
              fi;
              pos := pos + bytes;
          od;
          return Length(st);   # this indicates success
      else   # we do buffering:
          pos := 0;
          while pos < Length(st) do
              # First fill the buffer:
              if Length(st) - pos + f!.wdata < f!.wbufsize then
                  f!.wbuf{[f!.wdata+1..f!.wdata+Length(st)-pos]} := 
                          st{[pos+1..Length(st)]};
                  f!.wdata := f!.wdata + Length(st) - pos;
                  return Length(st);
              else
                  f!.wbuf{[f!.wdata+1..f!.wbufsize]} := 
                          st{[pos+1..pos+f!.wbufsize-f!.wdata]};
                  pos := pos + f!.wbufsize - f!.wdata;
                  f!.wdata := f!.wbufsize;
                  # Now the buffer is full and pos is still < Length(st)!
              fi;
              # Write out the buffer:
              pos2 := 0;
              while pos2 < f!.wbufsize do
                  bytes := IO.write(f!.fd,f!.wbuf,pos2,f!.wbufsize-pos2);
                  if bytes = fail then
                      return fail;
                  fi;
                  pos2 := pos2 + bytes;
              od;
              f!.wdata := 0;
              # Perhaps we can write a big chunk:
              if Length(st)-pos > f!.wbufsize then
                  bytes := IO.write(f!.fd,st,pos,Length(st)-pos);
                  if bytes = fail then
                      return fail;
                  fi;
                  pos := pos + bytes;
              fi;
          od;
          return Length(st);
      fi;
  fi;
  sumbytes := 0;
  for i in [2..Length(arg)] do
      if IsString(arg[i]) then
          st := arg[i];
      else
          st := String(arg[i]);
      fi;
      bytes := IO.Write(f,st);   # delegate to above
      if bytes = fail then
          return fail;
      fi;
      sumbytes := sumbytes + bytes;
  od;
  return sumbytes;
end;

IO.WriteLine := function( arg )
  # The same as IO.write, except that a line end is written in the end
  # and the buffer is flushed afterwards.
  local res;
  Add(arg,IO.LineEndChars);
  res := CallFuncList( IO.Write, arg );
  if res = fail then
      return fail;
  fi;
  if IO.Flush(arg[1]) = fail then
      return fail;
  else
      return res;
  fi;
end;

IO.WriteLines := function( f, l )
  # f must be an object of type IsFile
  # l must be a list. Calls IO.Write( f, o, IO.LineEndChars ) for all o in l.
  local o,res,written;
  if not(IsFile(f)) or not(IsList(l)) then
      Error("Usage: IO.WriteLines( f, l ) with IsFile(f) and IsList(l)");
  fi;
  written := 0;
  for o in l do
      res := IO.Write(f, o, IO.LineEndChars);
      if res = fail then
          return fail;
      fi;
      written := written + res;
  od;
  if IO.Flush(f) = fail then
      return fail;
  else
      return written;
  fi;
end;

IO.Flush := function( f )
  local res;
  if not(IsFile(f)) then
      Error("Usage: IO.Flush( f ) with IsFile(f)");
  fi;
  if f!.fd = -1 then  # Nothing to do for string Files
      return true;
  fi;
  while f!.wbufsize <> false and f!.wdata <> 0 do
      res := IO.write( f!.fd, f!.wbuf, 0, f!.wdata );
      if res = fail then
          return fail;
      fi;
      f!.wdata := f!.wdata - res;
  od;
  return true;
end;
 
# Allow access to the file descriptor:
IO.GetFD := function(f)
  if not(IsFile(f)) then
      Error("Usage: IO.GetFD( f ) with IsFile(f)");
  fi;
  return f!.fd;
end;

# Allow access to the buffers:
IO.GetWBuf := function(f)
  if not(IsFile(f)) then
      Error("Usage IO.GetWBuf( f ) with IsFile(f)");
  fi;
  return f!.wbuf;
end;

# Read a full directory:
IO.ListDir := function( dirname )
  local f,l,res;
  l := [];
  res := IO.opendir( dirname );
  if res = fail then
      return fail;
  fi;
  repeat
      f := IO.readdir();
      if IsString(f) then
          Add(l,f);
      fi;
  until f = false or f = fail;
  IO.closedir();
  return l;
end;

# A helper to make pairs IP address and port for TCP and UDP transfer:
IO.MakeIPAddressPort := function(ip,port)
  local i,l,nr,res;
  l := SplitString(ip,".");
  if Length(l) <> 4 then
      Error("IPv4 adresses must have 4 numbers seperated by dots");
  fi;
  res := "    ";
  for i in [1..4] do
      nr := Int(l[i]);
      if nr < 0 or nr > 255 then
          Error("IPv4 addresses must contain numbers between 0 and 255");
      fi;
      res[i] := CHAR_INT(nr);
  od;
  if port < 0 or port > 65535 then
      Error("IPv4 port numbers must be between 0 and 65535");
  fi;
  return IO.make_sockaddr_in(res,port);
end;


#############################################################################
# Two helper functions to access and change the environment:                #
#############################################################################

IO.Environment := function()
  # Returns a record with the components corresponding to the set
  # environment variables.
  local l,ll,p,r,v;
  l := IO.environ();
  r := rec();
  for v in l do
    p := Position(v,'=');
    if p <> fail then
      r.(v{[1..p-1]}) := v{[p+1..Length(v)]};
    fi;
  od;
  return r;
end;
  
IO.MakeEnvList := function(r)
  # Returns a list of strings for usage with execve made from the 
  # components of r in the form "key=value".
  local k,l;
  l := [];
  for k in RecFields(r) do
    Add(l,Concatenation(k,"=",r.(k)));
  od;
  return l;
end;

IO.MaxFDToClose := 64;

IO.CloseAllFDs := function(exceptions)
  local i;
  exceptions := Set(exceptions);
  for i in [0..IO.MaxFDToClose] do
    if not(i in exceptions) then
      IO.close(i);
    fi;
  od;
  return;
end;

IO.Popen := function(path,argv,mode)
  # mode can be "w" or "r". In the first case, the standard input of the
  # new process will be a pipe, the writing end is returned as a File object.
  # In the second case, the standard output of the new process will be a
  # pipe, the reading end is returned as a File object.
  # The other (standard out or in resp.) is identical to the one of the
  # calling GAP process.
  # Returns fail if an error occurred.
  # The process will usually die, when the pipe is closed. It lies in the
  # responsability of the caller to WaitPid for it, if our SIGCHLD handler
  # has been activated.
  # The File object will have the Attribute "ProcessID" set to the process ID.
  local fil,pid,pipe;
  if not(IsExecutableFile(path)) then
      Error("Popen: <path> must refer to an executable file.");
  fi;
  if mode = "r" then
      pipe := IO.pipe(); if pipe = fail then return fail; fi;
      pid := IO.fork(); 
      if pid < 0 then 
        IO.close(pipe.toread);
        IO.close(pipe.towrite);
        return fail; 
      fi;
      if pid = 0 then   # the child
          # First close all files
          IO.CloseAllFDs([0,2,pipe.towrite]);
          IO.dup2(pipe.towrite,1);
          IO.close(pipe.towrite);
          IO.execv(path,argv);
          # The following should not happen:
          IO.exit(-1);
      fi;
      # Now the parent:
      IO.close(pipe.towrite);
      fil := IO.WrapFD(pipe.toread,IO.DefaultBufSize,false);
      SetProcessID(fil,pid);
      return fil;
  elif mode = "w" then
      pipe := IO.pipe(); if pipe = fail then return fail; fi;
      pid := IO.fork(); 
      if pid < 0 then 
        IO.close(pipe.toread);
        IO.close(pipe.towrite);
        return fail; 
      fi;
      if pid = 0 then   # the child
          # First close all files
          IO.CloseAllFDs([1,2,pipe.toread]);
          IO.dup2(pipe.toread,0);
          IO.close(pipe.toread);
          IO.execv(path,argv);
          # The following should not happen:
          IO.exit(-1);
      fi;
      # Now the parent:
      IO.close(pipe.toread);
      fil := IO.WrapFD(pipe.towrite,false,IO.DefaultBufSize);
      SetProcessID(fil,pid);
      return fil;
  else
      Error("mode must be \"r\" or \"w\".");
  fi;
end;

IO.Popen2 := function(path,argv)
  # A new child process is started. The standard in and out of it are
  # pipes. The writing end of the input pipe and the reading end of the
  # output pipe are returned as File objects bound to two components
  # "stdin" and "stdout" of the returned record. This means, you have to
  # *write* to "stdin" and read from "stdout". The stderr will be the same
  # as the one of the calling GAP process.
  # Returns fail if an error occurred.
  # The process will usually die, when one of the pipes is closed. It
  # lies in the responsability of the caller to WaitPid for it, if our
  # SIGCHLD handler has been activated.
  local pid,pipe,pipe2,stdin,stdout;
  if not(IsExecutableFile(path)) then
      Error("Popen: <path> must refer to an executable file.");
  fi;
  pipe := IO.pipe(); if pipe = fail then return fail; fi;
  pipe2 := IO.pipe(); 
  if pipe2 = fail then
    IO.close(pipe.toread);
    IO.close(pipe.towrite);
    return fail;
  fi;
  pid := IO.fork(); 
  if pid < 0 then 
    IO.close(pipe.toread);
    IO.close(pipe.towrite);
    IO.close(pipe2.toread);
    IO.close(pipe2.towrite);
    return fail; 
  fi;
  if pid = 0 then   # the child
      # First close all files
      IO.CloseAllFDs([2,pipe.toread,pipe2.towrite]);
      IO.dup2(pipe.toread,0);
      IO.close(pipe.toread);
      IO.dup2(pipe2.towrite,1);
      IO.close(pipe2.towrite);
      IO.execv(path,argv);
      # The following should not happen:
      IO.exit(-1);
  fi;
  # Now the parent:
  IO.close(pipe.toread);
  IO.close(pipe2.towrite);
  stdin := IO.WrapFD(pipe.towrite,false,IO.DefaultBufSize);
  stdout := IO.WrapFD(pipe2.toread,IO.DefaultBufSize,false);
  SetProcessID(stdin,pid);
  SetProcessID(stdout,pid);
  return rec(stdin := stdin, stdout := stdout, pid := pid);
end;

IO.Popen3 := function(path,argv)
  # A new child process is started. The standard in and out and error are
  # pipes. All three "other" ends of the pipes are returned as File
  # objectes bound to the three components "stdin", "stdout", and "stderr"
  # of the returned record. This means, you have to *write* to "stdin"
  # and read from "stdout" and "stderr".
  # Returns fail if an error occurred.
  local pid,pipe,pipe2,pipe3,stderr,stdin,stdout;
  if not(IsExecutableFile(path)) then
      Error("Popen: <path> must refer to an executable file.");
  fi;
  pipe := IO.pipe(); if pipe = fail then return fail; fi;
  pipe2 := IO.pipe(); 
  if pipe2 = fail then
    IO.close(pipe.toread);
    IO.close(pipe.towrite);
    return fail;
  fi;
  pipe3 := IO.pipe(); 
  if pipe3 = fail then
    IO.close(pipe.toread);
    IO.close(pipe.towrite);
    IO.close(pipe2.toread);
    IO.close(pipe2.towrite);
    return fail;
  fi;
  pid := IO.fork(); 
  if pid < 0 then 
    IO.close(pipe.toread);
    IO.close(pipe.towrite);
    IO.close(pipe2.toread);
    IO.close(pipe2.towrite);
    IO.close(pipe3.toread);
    IO.close(pipe3.towrite);
    return fail; 
  fi;
  if pid = 0 then   # the child
      # First close all files
      IO.CloseAllFDs([pipe.toread,pipe2.towrite,pipe3.towrite]);
      IO.dup2(pipe.toread,0);
      IO.close(pipe.toread);
      IO.dup2(pipe2.towrite,1);
      IO.close(pipe2.towrite);
      IO.dup2(pipe3.towrite,2);
      IO.close(pipe3.towrite);
      IO.execv(path,argv);
      # The following should not happen:
      IO.exit(-1);
  fi;
  # Now the parent:
  IO.close(pipe.toread);
  IO.close(pipe2.towrite);
  IO.close(pipe3.towrite);
  stdin := IO.WrapFD(pipe.towrite,false,IO.DefaultBufSize);
  stdout := IO.WrapFD(pipe2.toread,IO.DefaultBufSize,false);
  stderr := IO.WrapFD(pipe3.toread,IO.DefaultBufSize,false);
  SetProcessID(stdin,pid);
  SetProcessID(stdout,pid);
  SetProcessID(stderr,pid);
  return rec(stdin := stdin, stdout := stdout, stderr := stderr, pid := pid);
end;

IO.SendStringBackground := function(f,st)
  # The whole string st is send to the File object f but in the background.
  # This works by forking off a child process which sends away the string
  # such that the parent can go on and can already read from the other end.
  # This is especially useful for piping large amounts of data through
  # a program that has been started with Popen2 or Popen3.
  # The component pid will be bound to the process id of the child process.
  # Returns fail if an error occurred.
  local pid,len;
  pid := IO.fork();
  if pid = -1 then
      return fail;
  fi;
  if pid = 0 then   # the child
      len := IO.Write(f,st);
      IO.Flush(f);
      IO.Close(f);
      IO.exit(0);
  fi;
  return true;
end;

