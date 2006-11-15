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

InstallValue( IO_Error,
  Objectify( NewType( IO_ResultsFamily, IO_Result ), rec( val := "IO_Error" ))
);
InstallValue( IO_Nothing,
  Objectify( NewType( IO_ResultsFamily, IO_Result ), rec( val := "IO_Nothing"))
);
InstallValue( IO_OK,
  Objectify( NewType( IO_ResultsFamily, IO_Result ), rec( val := "IO_OK"))
);
InstallMethod( \=, "for two IO_Results",
  [ IO_Result, IO_Result ],
  function(a,b) return a!.val = b!.val; end );
InstallMethod( \=, "for an IO_Result and another object",
  [ IO_Result, IsObject ], ReturnFalse );
InstallMethod( \=, "for another object and an IO_Result",
  [ IsObject, IO_Result], ReturnFalse );
InstallMethod( ViewObj, "for an IO_Result",
  [ IO_Result ],
  function(r) Print(r!.val); end );
 

###########################################################################
# Now the functions to create and work with objects in the filter IsFile: #
###########################################################################

InstallGlobalFunction(IO_WrapFD,function(fd,rbuf,wbuf)
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
end );

IO.DefaultBufSize := 65536;

# A convenience function for files on disk:
InstallGlobalFunction(IO_File, function( arg )
  # arguments: filename [,mode]
  # filename is a string and mode can be:
  #   "r" : open for reading only (default)
  #   "w" : open for writing only, possibly creating/truncating
  #   "a" : open for appending
  local fd,filename,mode,bufsize;
  if Length(arg) = 1 then
      filename := arg[1];
      mode := "r";
      bufsize := IO.DefaultBufSize;
  elif Length(arg) = 2 then
      filename := arg[1];
      if IsString(arg[2]) then
          mode := arg[2];
          bufsize := IO.DefaultBufSize;
      else
          mode := "r";
          bufsize := arg[2];
      fi;
  elif Length(arg) = 3 then
      filename := arg[1];
      mode := arg[2];
      bufsize := arg[3];
  else
      Error("IO: Usage: IO_File( filename [,mode][,bufsize] )\n",
            "with IsString(filename)");
  fi;
  if not(IsString(filename)) and not(IsString(mode)) then
      Error("IO: Usage: IO_File( filename [,mode][,bufsize] )\n",
            "with IsString(filename)");
  fi;
  if mode = "r" then
      fd := IO_open(filename,IO.O_RDONLY,0);
      if fd = fail then return fail; fi;
      return IO_WrapFD(fd,bufsize,false);
  elif mode = "w" then
      fd := IO_open(filename,IO.O_CREAT+IO.O_WRONLY+IO.O_TRUNC,
                    IO.S_IRUSR+IO.S_IWUSR+IO.S_IRGRP+IO.S_IWGRP+
                    IO.S_IROTH+IO.S_IWOTH);
      if fd = fail then return fail; fi;
      return IO_WrapFD(fd,false,bufsize);
  elif mode = "a" then
      fd := IO_open(filename,IO.O_APPEND+IO.O_WRONLY,0);
      if fd = fail then return fail; fi;
      return IO_WrapFD(fd,false,bufsize);
  else
      Error("IO: Mode not supported!");
  fi;
end );

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
InstallGlobalFunction( IO_Close, function( f )
  # f must be an object of type IsFile
  local ret;
  if not(IsFile(f)) then
      Error("Usage: IO_Close( f ) with IsFile(f) and f open");
  fi;
  if f!.closed then
      Error("Cannot close closed file");
  fi;
  # First flush if necessary:
  ret := true;
  if f!.wbufsize <> false and f!.wdata <> 0 then
      if IO_Flush( f ) = fail then ret := fail; fi;
  fi;
  f!.closed := true;
  f!.rbufsize := false;
  f!.wbufsize := false;
  # to free the memory for the buffer
  f!.rbuf := fail;
  f!.wbuf := fail;
  if f!.fd <> -1 then
      if IO_close(f!.fd) = fail then ret := fail; fi;
  fi;
  return ret;
end );

InstallGlobalFunction( IO_ReadUntilEOF, function( f )
  # arguments: f
  # f must be an object of type IsFile
  # Reads until end of file. Returns either a (non-empty) string
  # or "" (if f is already at end of file) or fail if
  # an error occurs.
  local bytes,res;
  if not(IsFile(f)) then
      Error("Usage: IO_ReadUntilEOF( f ) with IsFile(f)");
  fi;
  if f!.closed then
      Error("Tried to read from closed file.");
  fi;
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
      bytes := IO_read(f!.fd,res,Length(res),f!.rbufsize);
      if bytes = fail then return fail; fi;
  until bytes = 0;
  return res;
end );

InstallGlobalFunction( IO_ReadBlock, function( f, len )
  # arguments: f ,len
  # f must be an object of type IsFile
  # len is the length to read
  # Reads length bytes. Guarantees to return length bytes or less "" 
  # indicating EOF or fail for an error. Blocks until enough data arrives.
  # This function only returns less than length bytes, if EOF is reached
  # before length bytes are read.
  local amount,bytes,res;
  if not(IsFile(f)) or not(IsInt(len)) then
      Error("Usage: IO_ReadBlock( f [,len] ) with IsFile(f) ",
            "and IsInt(len)");
  fi;
  if f!.closed then
      Error("Tried to read from closed file.");
  fi;
  res := "";
  # First the case of no buffer:
  if f!.rbufsize = false then
      while Length(res) < len do
          bytes := IO_read(f!.fd,res,Length(res),len - Length(res));
          if bytes = fail then return fail; fi;
          if bytes = 0 then return res; fi;   # this is EOF
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
      elif f!.rdata > 0 then
          Append(res,f!.rbuf{[f!.rpos..f!.rpos+f!.rdata-1]});
          f!.rpos := 1;
          f!.rdata := 0;
      fi;
      if f!.fd = -1 then
          return res;
      fi;
      if len - Length(res) > f!.rbufsize then   
          # In this case we read the whole thing:
          bytes := IO_read(f!.fd,res,Length(res),len - Length(res));
          if bytes = fail then 
              return fail;
          elif bytes = 0 then 
              return res;
          fi;
      else
          # Now the buffer is empty, so refill it:
          bytes := IO_read(f!.fd,f!.rbuf,0,f!.rbufsize);
          if bytes = fail then
              return fail;
          elif bytes = 0 then
              return res;
          fi;
          f!.rdata := bytes;
      fi;
  od;
  return res;
end );

InstallGlobalFunction( IO_ReadLine, function( f )
  # f must be an object of type IsFile
  # The IO.LineEndChars are not removed at the end
  local bytes,pos,res;
  if not(IsFile(f)) then
      Error("Usage: IO_ReadLine( f ) with IsFile(f)");
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
          bytes := IO_read(f!.fd,f!.rbuf,0,f!.rbufsize);
          if bytes = fail then return fail; fi;
          if bytes = 0 then   # we are at end of file
              return res;
          fi;
          f!.rdata := bytes;
      fi;
  od;
end );

InstallGlobalFunction( IO_ReadLines, function (arg)
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
      Error("Usage: IO_ReadLines( f [,max] ) with IsFile(f) and IsInt(max)");
  fi;
  if not(IsFile(f)) or not(IsInt(max) or max = infinity) then
      Error("Usage: IO_ReadLines( f [,max] ) with IsFile(f) and IsInt(max)");
  fi;
  if f!.closed then
      Error("Tried to read from closed file.");
  fi;
  li := [];
  while Length(li) < max do
      l := IO_ReadLine(f);
      if l = fail then return fail; fi;
      if Length(l) = 0 then
          return li;
      fi;
      Add(li,l);
  od;
  return li;
end );

InstallGlobalFunction( IO_Read, function( f, len )
  # arguments: f ,len
  # f must be an object of type IsFile
  # len is the length to read
  # Reads up to length bytes. Returns at least 1 byte or "" (for EOF)
  # or fail for an error. Blocks only if there is no data available
  # and the file is not yet at EOF (for pipes or sockets). If IO_Select
  # states that a file object is ready to read, then this function will
  # not block. The function may return less than len bytes. It is *not*
  # guaranteed that all available data is returned. This function is
  # intended to behave very similar to IO_read except for the buffering.
  local amount,bytes,res;
  if not(IsFile(f)) or not(IsInt(len)) then
      Error("Usage: IO_ReadBlock( f [,len] ) with IsFile(f) ",
            "and IsInt(len)");
  fi;
  if f!.closed then
      Error("Tried to read from closed file.");
  fi;
  res := "";
  # First the case of no buffer:
  if f!.rbufsize = false then
      bytes := IO_read(f!.fd,res,Length(res),len - Length(res));
      if bytes = fail then return fail; fi;
      return res;
  fi;
  # read up to len bytes, using our buffer:     
  # First empty the buffer:
  while true do   # will be exited
      if f!.rdata > len - Length(res) then   # more data available
          amount := len - Length(res);
          res := f!.rbuf{[f!.rpos..f!.rpos+amount-1]};
          f!.rpos := f!.rpos + amount;
          f!.rdata := f!.rdata - amount;
          return res;
      elif f!.rdata > 0 then
          res := f!.rbuf{[f!.rpos..f!.rpos+f!.rdata-1]};
          f!.rpos := 1;
          f!.rdata := 0;
          return res;
      fi;
      if f!.fd = -1 then
          return "";
      fi;
      if len - Length(res) > f!.rbufsize then   
          # In this case we read the whole thing:
          bytes := IO_read(f!.fd,res,Length(res),len - Length(res));
          if bytes = fail then 
              return fail;
          elif bytes = 0 then 
              return "";
          else
              return res;
          fi;
      else
          # Now the buffer is empty, so refill it:
          bytes := IO_read(f!.fd,f!.rbuf,0,f!.rbufsize);
          if bytes = fail then
              return fail;
          elif bytes = 0 then
              return "";
          fi;
          f!.rdata := bytes;
          # The next loop will do it
      fi;
  od;
end );

InstallGlobalFunction( IO_HasData,
  # Returns true or false. True means, that IO_Read will not block, i.e.,
  # it will either produce data or indicate end of file. Note that for a
  # file at end of file this function returns true.
  function(f)
    local l,nr;
    if not(IsFile(f)) then
        Error("Usage: IO_HasData( f ) with IsFile(f)");
    fi;
    if f!.closed then
        Error("Tried to check for data on closed file.");
    fi;
    if f!.rbufsize <> false and f!.rdata <> 0 then
        return true;
    fi;
    if f!.fd = -1 then return false; fi;
    # Now use select:
    l := [f!.fd];
    nr := IO_select(l,[],[],0,0);
    if nr = 0 then return false; fi;
    return true;
  end );

# The buffered write functionality:
InstallGlobalFunction( IO_Write, function( arg )
  # arguments: f {,things ... }
  # f must be an object of type IsFile
  # all other arguments: either they are strings, in which case they are
  # written directly, otherwise they are converted to strings with "String"
  # and the result is being written. The result is either the number of
  # bytes written or fail to indicate an error. This functions blocks
  # until everything is either written to the buffer or to the actual
  # file descriptor. Note that you can never be sure that this function
  # returns immediately, even if IO_Select returned a certain file to
  # be writable. Use IO_WriteNonBlocking for that purpose.
  local bytes,f,i,pos,pos2,st,sumbytes;
  if Length(arg) < 2 or not(IsFile(arg[1])) then
      Error("Usage: IO_Write( f ,things ... ) with IsFile(f)");
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
          # Non-buffered I/O:
          pos := 0;
          while pos < Length(st) do
              bytes := IO_write(f!.fd,st,pos,Length(st));
              if bytes = fail then return fail; fi;
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
                  bytes := IO_write(f!.fd,f!.wbuf,pos2,f!.wbufsize-pos2);
                  if bytes = fail then return fail; fi;
                  pos2 := pos2 + bytes;
              od;
              f!.wdata := 0;
              # Perhaps we can write a big chunk:
              if Length(st)-pos > f!.wbufsize then
                  bytes := IO_write(f!.fd,st,pos,Length(st)-pos);
                  if bytes = fail then return fail; fi;
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
      bytes := IO_Write(f,st);   # delegate to above
      if bytes = fail then return fail; fi;
      sumbytes := sumbytes + bytes;
  od;
  return sumbytes;
end );

InstallGlobalFunction( IO_WriteLine, function( arg )
  # The same as IO_write, except that a line end is written in the end
  # and the buffer is flushed afterwards.
  local res;
  Add(arg,IO.LineEndChars);
  res := CallFuncList( IO_Write, arg );
  if res = fail then return fail; fi;
  if IO_Flush(arg[1]) = fail then return fail; else
      return res;
  fi;
end );

InstallGlobalFunction( IO_WriteLines, function( f, l )
  # f must be an object of type IsFile
  # l must be a list. Calls IO_Write( f, o, IO.LineEndChars ) for all o in l.
  local o,res,written;
  if not(IsFile(f)) or not(IsList(l)) then
      Error("Usage: IO_WriteLines( f, l ) with IsFile(f) and IsList(l)");
  fi;
  written := 0;
  for o in l do
      res := IO_Write(f, o, IO.LineEndChars);
      if res = fail then return fail; fi;
      written := written + res;
  od;
  if IO_Flush(f) = fail then
      return fail;
  else
      return written;
  fi;
end );

InstallGlobalFunction( IO_WriteNonBlocking,
  function( f, st, pos, len )
    # This function tries to write data of len bytes in the string st beginning 
    # at position pos+1 to f. It is guaranteed that this function does not
    # block, if IO_ReadyForWrite(f) returned true or IO_Select indicated
    # possibility to write. Therefore, it might write fewer characters
    # than requested! The function returns the number of bytes written
    # or fail in case of an error. The function can block, if the 
    # buffer is full and the file descriptor is not ready to write.
    local bytes,pos2;
    if not(IsFile(f)) or not(IsString(st)) or not(IsInt(pos)) then
        Error("Usage: IO_WriteNonBlocking( f, st, pos )");
    fi;
    if f!.closed then
        Error("Tried to write on closed file.");
    fi;
    # Do we buffer?
    if f!.wbufsize = false then
        # Non-buffered I/O:
        bytes := IO_write(f!.fd,st,pos,len);
        if bytes = fail then return fail; fi;
        return bytes;   # this indicates success
    else   # we do buffering:
        while true do   # will be left by return and run at most twice!
            # First fill the buffer:
            if f!.wdata < f!.wbufsize then  # buffer not full
                if len + f!.wdata < f!.wbufsize then
                    f!.wbuf{[f!.wdata+1..f!.wdata+len]} := 
                            st{[pos+1..pos+len]};
                    f!.wdata := f!.wdata + len;
                    return len;
                else
                    f!.wbuf{[f!.wdata+1..f!.wbufsize]} := 
                            st{[pos+1..pos+f!.wbufsize-f!.wdata]};
                    bytes := f!.wbufsize - f!.wdata;
                    f!.wdata := f!.wbufsize;
                    # Now the buffer is full and pos is still < Length(st)!
                    return bytes;
                fi;
            fi;
            # Write out the buffer:
            pos2 := 0;
            bytes := IO_write(f!.fd,f!.wbuf,0,Minimum(IO.PIPE_BUF,f!.wbufsize));
            if bytes = fail then return fail; fi;
            if bytes = f!.wbufsize then
                f!.wdata := 0;
            else
                f!.wbuf{[1..f!.wbufsize-bytes]} 
                   := f!.wbuf{[bytes+1..f!.wbufsize]};
                f!.wdata := f!.wdata - bytes;
            fi;
            # Now there is again space in the buffer and the next loop
            # will succeed to write at least something.
        od;
    fi;
  end );

InstallGlobalFunction( IO_Flush, function( f )
  local res;
  if not(IsFile(f)) then
      Error("Usage: IO_Flush( f ) with IsFile(f)");
  fi;
  if f!.fd = -1 then  # Nothing to do for string Files
      return true;
  fi;
  while f!.wbufsize <> false and f!.wdata <> 0 do
      res := IO_write( f!.fd, f!.wbuf, 0, f!.wdata );
      if res = fail then return fail; fi;
      f!.wdata := f!.wdata - res;
  od;
  return true;
end );
 
InstallGlobalFunction( IO_FlushNonBlocking, function( f )
  # This function is guaranteed to make some progress but also not to
  # block if IO_ReadyForWrite or IO_Select returned f to be ready for
  # writing. It returns true if the buffers have been flushed and false
  # otherwise. An error is signalled by fail.
  local res;
  if not(IsFile(f)) then
      Error("Usage: IO_FlushNonBlocking( f ) with IsFile(f)");
  fi;
  if f!.fd = -1 or    # Nothing to do for string Files
     f!.wbufsize = false or
     (f!.wbufsize <> false and f!.wdata = 0) then    # or if buffer empty
      return true;
  fi;
  res := IO_write( f!.fd, f!.wbuf, 0, f!.wdata );
  if res = fail then return fail; fi;
  if res < f!.wdata then
      f!.wbuf{[1..f!.wdata-res]} := f!.wbuf{[res+1..f!.wdata]};
      f!.wdata := f!.wdata - res;
      return false;
  else
      f!.wdata := 0;
      return true;
  fi;
  end );

InstallGlobalFunction( IO_WriteFlush,
  function(arg)
    local bytes;
    bytes := CallFuncList(IO_Write,arg);
    if bytes = fail then return fail; fi;
    if IO_Flush(arg[1]) = fail then return fail; fi;
    return bytes;
  end );

InstallGlobalFunction( IO_ReadyForWrite,
  # Returns true or false. True means, that the next IO_WriteNonBlocking
  # will not block, false means, that the next IO_WriteNonBlocking might
  # block.
  function(f)
    local l,nr;
    if not(IsFile(f)) then
        Error("Usage: IO_ReadyForWrite( f ) with IsFile(f)");
    fi;
    if f!.closed then
        Error("Tried to check for write on closed file.");
    fi;
    if f!.wbufsize <> false and f!.wdata < f!.wbufsize then
        return true;
    fi;
    if f!.fd = -1 then return true; fi;
    # Now use select:
    l := [f!.fd];
    nr := IO_select([],l,[],0,0);
    if nr = 0 then return false; fi;
    return true;
  end );

InstallGlobalFunction( IO_ReadyForFlush,
  # Returns true or false. True means, that the next IO_FlushNonBlocking
  # will not block, false means, that the next IO_FlushNonBlocking might
  # block.
  function(f)
    local l,nr;
    if not(IsFile(f)) then
        Error("Usage: IO_ReadyForFlush( f ) with IsFile(f)");
    fi;
    if f!.closed then
        Error("Tried to check for flush on closed file.");
    fi;
    if f!.wbufsize = false or f!.wdata = 0 then
        return true;
    fi;
    if f!.fd = -1 then return true; fi;
    # Now use select:
    l := [f!.fd];
    nr := IO_select([],l,[],0,0);
    if nr = 0 then return false; fi;
    return true;
  end );

  
InstallGlobalFunction( IO_Select, function( r, w, f, e, t1, t2 )
  # Provides select functionality for file descriptors and IsFile objects.
  # The list f is for a test for flushability.
  local ep,ee,i,nr,nrfinal,rp,rr,wp,ww;
  nrfinal := 0;
  rr := [];
  rp := [];
  for i in [1..Length(r)] do
      if IsInt(r[i]) then    # A file descriptor
          Add(rr,r[i]);
          Add(rp,i);
      elif IsFile(r[i]) then
          if r[i]!.rbufsize <> false and r[i]!.rdata > 0 then
              nrfinal := nrfinal + 1;
          else
              Add(rr,r[i]!.fd);
              Add(rp,i);
          fi;
      else
          r[i] := fail;
      fi;
  od;
  ww := [];
  wp := [];
  for i in [1..Length(w)] do
      if IsInt(w[i]) then    # A file descriptor
          Add(ww,w[i]);
          Add(wp,i);
      elif IsFile(w[i]) then
          if w[i]!.wbufsize <> false and w[i]!.wdata < w[i]!.wbufsize then
              nrfinal := nrfinal + 1;
          else
              Add(ww,w[i]!.fd);
              Add(wp,i);
          fi;
      else
          w[i] := fail;
      fi;
  od;
  for i in [1..Length(f)] do
      if IsInt(f[i]) then    # A file descriptor
          Add(ww,f[i]);
          Add(wp,-i);
      elif IsFile(f[i]) then
          Add(ww,f[i]!.fd);
          Add(wp,-i);
      else
          f[i] := fail;
      fi;
  od;
  ee := [];
  ep := [];
  for i in [1..Length(e)] do
      if IsInt(e[i]) then    # A file descriptor
          Add(ee,e[i]);
          Add(ep,i);
      elif IsFile(e[i]) then
          Add(ee,e[i]!.fd);
          Add(ep,i);
      else
          e[i] := fail;
      fi;
  od;
  if Length(rr) > 0 or Length(ww) > 0 or Length(ee) > 0 then
      # we have to investigate further:
      if nrfinal > 0 then
          t1 := 0;   # set timeout to 0 because we know we have buffers ready
          t2 := 0;
      fi;
      # Now do the select:
      nr := IO_select(rr,ww,ee,t1,t2);
      if nr = fail then
          # An error, bits and timeout are undefined
          return fail;
      fi;
      nrfinal := nrfinal + nr;
      # Now look for results:
      for i in [1..Length(rr)] do
          if rr[i] = fail then r[rp[i]] := fail; fi;
      od;
      for i in [1..Length(ww)] do
          if ww[i] = fail then
              if wp[i] > 0 then w[wp[i]] := fail;
                           else f[-wp[i]] := fail; fi;
          fi;
      od;
      for i in [1..Length(ee)] do
          if ee[i] = fail then e[ep[i]] := fail; fi;
      od;
  fi;
  return nrfinal;
end );
      


# Allow access to the file descriptor:
InstallGlobalFunction( IO_GetFD, function(f)
  if not(IsFile(f)) then
      Error("Usage: IO_GetFD( f ) with IsFile(f)");
  fi;
  return f!.fd;
end );

# Allow access to the buffers:
InstallGlobalFunction( IO_GetWBuf, function(f)
  if not(IsFile(f)) then
      Error("Usage IO_GetWBuf( f ) with IsFile(f)");
  fi;
  return f!.wbuf;
end );

# Read a full directory:
InstallGlobalFunction( IO_ListDir, function( dirname )
  local f,l,res;
  l := [];
  res := IO_opendir( dirname );
  if res = fail then
      return fail;
  fi;
  repeat
      f := IO_readdir();
      if IsString(f) then
          Add(l,f);
      fi;
  until f = false or f = fail;
  IO_closedir();
  return l;
end );

# A helper to make pairs IP address and port for TCP and UDP transfer:
InstallGlobalFunction( IO_MakeIPAddressPort, function(ip,port)
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
  return IO_make_sockaddr_in(res,port);
end );


#############################################################################
# Two helper functions to access and change the environment:                #
#############################################################################

InstallGlobalFunction( IO_Environment, function()
  # Returns a record with the components corresponding to the set
  # environment variables.
  local l,ll,p,r,v;
  l := IO_environ();
  r := rec();
  for v in l do
    p := Position(v,'=');
    if p <> fail then
      r.(v{[1..p-1]}) := v{[p+1..Length(v)]};
    fi;
  od;
  return r;
end );
  
InstallGlobalFunction( IO_MakeEnvList, function(r)
  # Returns a list of strings for usage with execve made from the 
  # components of r in the form "key=value".
  local k,l;
  l := [];
  for k in RecFields(r) do
    Add(l,Concatenation(k,"=",r.(k)));
  od;
  return l;
end );

IO.MaxFDToClose := 64;

InstallGlobalFunction( IO_CloseAllFDs, function(exceptions)
  local i;
  exceptions := Set(exceptions);
  for i in [0..IO.MaxFDToClose] do
    if not(i in exceptions) then
      IO_close(i);
    fi;
  od;
  return;
end );

InstallGlobalFunction( IO_Popen, function(path,argv,mode)
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
      pipe := IO_pipe(); if pipe = fail then return fail; fi;
      pid := IO_fork(); 
      if pid < 0 then 
        IO_close(pipe.toread);
        IO_close(pipe.towrite);
        return fail; 
      fi;
      if pid = 0 then   # the child
          # First close all files
          IO_CloseAllFDs([0,2,pipe.towrite]);
          IO_dup2(pipe.towrite,1);
          IO_close(pipe.towrite);
          IO_execv(path,argv);
          # The following should not happen:
          IO_exit(-1);
      fi;
      # Now the parent:
      IO_close(pipe.towrite);
      fil := IO_WrapFD(pipe.toread,IO.DefaultBufSize,false);
      SetProcessID(fil,pid);
      return fil;
  elif mode = "w" then
      pipe := IO_pipe(); if pipe = fail then return fail; fi;
      pid := IO_fork(); 
      if pid < 0 then 
        IO_close(pipe.toread);
        IO_close(pipe.towrite);
        return fail; 
      fi;
      if pid = 0 then   # the child
          # First close all files
          IO_CloseAllFDs([1,2,pipe.toread]);
          IO_dup2(pipe.toread,0);
          IO_close(pipe.toread);
          IO_execv(path,argv);
          # The following should not happen:
          IO_exit(-1);
      fi;
      # Now the parent:
      IO_close(pipe.toread);
      fil := IO_WrapFD(pipe.towrite,false,IO.DefaultBufSize);
      SetProcessID(fil,pid);
      return fil;
  else
      Error("mode must be \"r\" or \"w\".");
  fi;
end );

InstallGlobalFunction( IO_Popen2, function(path,argv)
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
  pipe := IO_pipe(); if pipe = fail then return fail; fi;
  pipe2 := IO_pipe(); 
  if pipe2 = fail then
    IO_close(pipe.toread);
    IO_close(pipe.towrite);
    return fail;
  fi;
  pid := IO_fork(); 
  if pid < 0 then 
    IO_close(pipe.toread);
    IO_close(pipe.towrite);
    IO_close(pipe2.toread);
    IO_close(pipe2.towrite);
    return fail; 
  fi;
  if pid = 0 then   # the child
      # First close all files
      IO_CloseAllFDs([2,pipe.toread,pipe2.towrite]);
      IO_dup2(pipe.toread,0);
      IO_close(pipe.toread);
      IO_dup2(pipe2.towrite,1);
      IO_close(pipe2.towrite);
      IO_execv(path,argv);
      # The following should not happen:
      IO_exit(-1);
  fi;
  # Now the parent:
  IO_close(pipe.toread);
  IO_close(pipe2.towrite);
  stdin := IO_WrapFD(pipe.towrite,false,IO.DefaultBufSize);
  stdout := IO_WrapFD(pipe2.toread,IO.DefaultBufSize,false);
  SetProcessID(stdin,pid);
  SetProcessID(stdout,pid);
  return rec(stdin := stdin, stdout := stdout, pid := pid);
end );

InstallGlobalFunction( IO_Popen3, function(path,argv)
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
  pipe := IO_pipe(); if pipe = fail then return fail; fi;
  pipe2 := IO_pipe(); 
  if pipe2 = fail then
    IO_close(pipe.toread);
    IO_close(pipe.towrite);
    return fail;
  fi;
  pipe3 := IO_pipe(); 
  if pipe3 = fail then
    IO_close(pipe.toread);
    IO_close(pipe.towrite);
    IO_close(pipe2.toread);
    IO_close(pipe2.towrite);
    return fail;
  fi;
  pid := IO_fork(); 
  if pid < 0 then 
    IO_close(pipe.toread);
    IO_close(pipe.towrite);
    IO_close(pipe2.toread);
    IO_close(pipe2.towrite);
    IO_close(pipe3.toread);
    IO_close(pipe3.towrite);
    return fail; 
  fi;
  if pid = 0 then   # the child
      # First close all files
      IO_CloseAllFDs([pipe.toread,pipe2.towrite,pipe3.towrite]);
      IO_dup2(pipe.toread,0);
      IO_close(pipe.toread);
      IO_dup2(pipe2.towrite,1);
      IO_close(pipe2.towrite);
      IO_dup2(pipe3.towrite,2);
      IO_close(pipe3.towrite);
      IO_execv(path,argv);
      # The following should not happen:
      IO_exit(-1);
  fi;
  # Now the parent:
  IO_close(pipe.toread);
  IO_close(pipe2.towrite);
  IO_close(pipe3.towrite);
  stdin := IO_WrapFD(pipe.towrite,false,IO.DefaultBufSize);
  stdout := IO_WrapFD(pipe2.toread,IO.DefaultBufSize,false);
  stderr := IO_WrapFD(pipe3.toread,IO.DefaultBufSize,false);
  SetProcessID(stdin,pid);
  SetProcessID(stdout,pid);
  SetProcessID(stderr,pid);
  return rec(stdin := stdin, stdout := stdout, stderr := stderr, pid := pid);
end );

InstallGlobalFunction( IO_SendStringBackground, function(f,st)
  # The whole string st is send to the File object f but in the background.
  # This works by forking off a child process which sends away the string
  # such that the parent can go on and can already read from the other end.
  # This is especially useful for piping large amounts of data through
  # a program that has been started with Popen2 or Popen3.
  # The component pid will be bound to the process id of the child process.
  # Returns fail if an error occurred.
  local pid,len;
  pid := IO_fork();
  if pid = -1 then
      return fail;
  fi;
  if pid = 0 then   # the child
      len := IO_Write(f,st);
      IO_Flush(f);
      IO_Close(f);
      IO_exit(0);
  fi;
  return true;
end );

InstallGlobalFunction( IO_PipeThroughWithError,
function(cmd,args,input)
  local byt,chunk,err,erreof,inpos,nr,out,outeof,r,s,w;

  # Start the coprocess:
  s := IO_Popen3(cmd,args);
  if s = fail then return fail; fi;
  s.stdin!.wbufsize := false;    # do not do buffering
  s.stdout!.rbufsize := false;
  s.stderr!.rbufsize := false;
  # Switch the one we write to to non-blocking mode, just to be sure!
  IO_fcntl(s.stdin!.fd,IO.F_GETFL,IO.O_NONBLOCK);

  # Here we just do I/O multiplexing, sending away input (if non-empty)
  # and receiving stdout and stderr.
  inpos := 0;
  outeof := false;
  erreof := false;
  # Here we collect stderr and stdout:
  err := "";
  out := "";
  repeat
      if not(outeof) then
          r := [s.stdout];
      else
          r := [];
      fi;
      if not(erreof) then
          Add(r,s.stderr);
      fi;
      if inpos < Length(input) then
          w := [s.stdin];
      else
          w := [];
      fi;
      nr := IO_Select(r,w,[],[],fail,fail);
      if nr = fail then   # an error occurred
          if inpos < Length(input) then IO_Close(s.stdin); fi;
          IO_Close(s.stdout);
          IO_Close(s.stderr);
          return fail;
      fi;
      # First writing:
      if Length(w) > 0 and w[1] <> fail then
          byt := IO_WriteNonBlocking(s.stdin,input,inpos,Length(input)-inpos);
          if byt = fail then
              if LastSystemError().number <> IO.EWOULDBLOCK then
                  IO_Close(s.stdin);
                  IO_Close(s.stdout);
                  IO_Close(s.stderr);
                  return fail;
              fi;
          fi;
          inpos := inpos + byt;
          if inpos = Length(input) then IO_Close(s.stdin); fi;
      fi;
      # Now reading:
      if not(outeof) and r[1] <> fail then
          chunk := IO_Read(s.stdout,1000000);
          if chunk = "" then 
              outeof := true; 
          elif chunk = fail then
              if inpos < Length(input) then IO_Close(s.stdin); fi;
              IO_Close(s.stdout);
              IO_Close(s.stderr);
              return fail;
          else
              Append(out,chunk);
          fi;
      fi;
      if not(erreof) and r[Length(r)] <> fail then
          chunk := IO_Read(s.stderr,1000000);
          if chunk = "" then 
              erreof := true; 
          elif chunk = fail then
              if inpos < Length(input) then IO_Close(s.stdin); fi;
              IO_Close(s.stdout);
              IO_Close(s.stderr);
              return fail;
          else
              Append(err,chunk);
          fi;
      fi;
  until outeof and erreof;
  IO_Close(s.stdout);
  IO_Close(s.stderr);
  return rec( out := out, err := err );
end);

InstallGlobalFunction( IO_PipeThrough,
function(cmd,args,input)
  local byt,chunk,inpos,nr,out,outeof,r,s,w;

  # Start the coprocess:
  s := IO_Popen2(cmd,args);
  if s = fail then return fail; fi;
  s.stdin!.wbufsize := false;    # do not do buffering
  s.stdout!.rbufsize := false;
  # Switch the one we write to to non-blocking mode, just to be sure!
  IO_fcntl(s.stdin!.fd,IO.F_GETFL,IO.O_NONBLOCK);

  # Here we just do I/O multiplexing, sending away input (if non-empty)
  # and receiving stdout and stderr.
  # Note that the flushing part is superfluous since we switched off
  # the buffers, but still, like this, the code would also work with
  # buffering.
  inpos := 0;
  outeof := false;
  # Here we collect stdout:
  out := "";
  repeat
      if not(outeof) then
          r := [s.stdout];
      else
          r := [];
      fi;
      if inpos < Length(input) then
          w := [s.stdin];
      else
          w := [];
      fi;
      nr := IO_Select(r,w,[],[],fail,fail);
      if nr = fail then   # an error occurred
          if inpos < Length(input) then IO_Close(s.stdin); fi;
          IO_Close(s.stdout);
          return fail;
      fi;
      # First writing:
      if Length(w) > 0 and w[1] <> fail then
          byt := IO_WriteNonBlocking(s.stdin,input,inpos,Length(input)-inpos);
          if byt = fail then
              if LastSystemError().number <> IO.EWOULDBLOCK then
                  if inpos < Length(input) then IO_Close(s.stdin); fi;
                  IO_Close(s.stdout);
                  return fail;
              fi;
          fi;
          inpos := inpos + byt;
          if inpos = Length(input) then IO_Close(s.stdin); fi;
      fi;
      # Now reading:
      if not(outeof) and r[1] <> fail then
          chunk := IO_Read(s.stdout,1000000);
          if chunk = "" then 
              outeof := true;
          elif chunk = fail then
              if inpos < Length(input) then IO_Close(s.stdin); fi;
              IO_Close(s.stdout);
              return fail;
          else
              Append(out,chunk);
          fi;
      fi;
  until outeof;
  IO_Close(s.stdout);
  return out;
end);


