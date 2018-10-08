InstallGlobalFunction(TCP_AddrToString,
addr -> JoinStringsWithSeparator(List(addr{[5..8]},
                                      x -> String(INT_CHAR(x))), "."));

InstallGlobalFunction( StartTCPServer,
function(hostname, port, handlerCallback)
    local socket, addr, client, stream;
    socket := ListeningTCPSocket(hostname, port);
    while true do
        # Currently we accept connections from anyone.
        addr := IO_MakeIPAddressPort( "0.0.0.0", 0 );

        # Accept connection, and open stream.
        client := IO_accept(socket, addr);

        # TODO: prettier
        Info(InfoTCPSockets, 5, "Accepted connection from: ",
             TCP_AddrToString(addr));
        stream := AcceptInputOutputTCPStream(client);

        # Handle connection
        handlerCallback(addr, stream);
    od;
end);

InstallGlobalFunction( ListeningTCPSocket,
function(hostname, port)
    local socket, client, desc, stream, res, bindaddr, listenname;

    res := IO_gethostbyname(hostname);
    if res = fail then
        ErrorNoReturn("ListeningTCPSocket: lookup failed on address ",
                      hostname);
    fi;
    bindaddr := res.addr[1];
    listenname := res.name;

    if not IsPosInt(port) or (port > 65535) then
        ErrorNoReturn("ListeningTCPSocket:\n<port> must be ",
                      "a positive integer no greater than 65535");
    fi;

    # Create TCP socket
    Info(InfoTCPSockets, 5, "MitM server listening for connections...");
    socket := IO_socket( IO.PF_INET, IO.SOCK_STREAM, "tcp" );
    if socket = fail then
        ErrorNoReturn("ListeningTCPSocket: failed to open socket:\n", 
                      LastSystemError().message);
    fi;

    res := IO_bind(socket, IO_make_sockaddr_in(bindaddr, port));
    if res = fail then
        ErrorNoReturn("ListeningTCPSocket: failed to bind:\n", 
                      LastSystemError().message);
    fi;

    Info(InfoTCPSockets, 5, "MitM server listening on ", listenname, " ", port);
    # TODO: make the queue length a parameter
    IO_listen(socket, 5);
    return socket;
end);

InstallGlobalFunction( ConnectInputOutputTCPStream,
function( hostname, port )
    local lookup, sock, res, err, fio;

    if not IsString( hostname ) then
        Error("ConnectInputOutputTCPStream: <hostname> must be a string");
    fi;
    if not (IsInt(port) and port >= 0) then
        Error("ConnectInputOutputTCPStream: <port> must be a non-negative integer");
    fi;
    lookup := IO_gethostbyname( hostname );
    if lookup = fail then
        Error("ConnectInputOutputTCPStream: cannot find hostname ", hostname);
    fi;
    sock := IO_socket( IO.PF_INET, IO.SOCK_STREAM, "tcp" );
    res := IO_connect( sock, IO_make_sockaddr_in( lookup.addr[1], port ) );
    if res = fail then
        err := LastSystemError();
        IO_close(sock);
        Error("ConnectInputOutputTCPStream: ", err.message);
    else
        fio := IO_WrapFD( sock, IO.DefaultBufSize, IO.DefaultBufSize );
        return Objectify( InputOutputTCPStreamDefaultType,
                          [ fio, hostname, [ port ], false ] );
    fi;
end);

InstallGlobalFunction( AcceptInputOutputTCPStream,
function(socket_descriptor)
    local fio;
    if not (IsInt(socket_descriptor) and socket_descriptor >= 0) then
        Error("AcceptInputOutputTCPStream: argument must be a non-negative integer");
    fi;
    fio := IO_WrapFD(socket_descriptor, IO.DefaultBufSize, IO.DefaultBufSize);
    return Objectify( InputOutputTCPStreamDefaultType,
                      [ fio, "socket descriptor", [ socket_descriptor ], false ] );
end);

InstallMethod( ViewObj, "for ioTCPstream",
               [ IsInputOutputTCPStreamRep and IsInputOutputStream ],
function(stream)
    Print("<");
    if IsClosedStream(stream) then
        Print("closed ");
    fi;
    Print("input/output TCP stream to ",stream![2],":", stream![3][1], ">");
end);

InstallMethod( PrintObj, "for ioTCPstream",
               [ IsInputOutputTCPStreamRep and IsInputOutputStream ],
               ViewObj);

InstallMethod( ReadByte, "for ioTCPstream",
               [ IsInputOutputTCPStreamRep and IsInputOutputStream ],
function(stream)
    local buf;
    buf := IO_Read( stream![1], 1 );
    if buf = fail or Length(buf) = 0 then
        stream![4] := true;
        return fail;
    else
        stream![4] := true;
        return INT_CHAR(buf[1]);
    fi;
end);

InstallMethod( ReadLine, "for ioTCPstream",
               [ IsInputOutputTCPStreamRep and IsInputOutputStream ],
function( stream )
    local sofar, chunk;
    sofar := IO_Read( stream![1], 1 );
    if sofar = fail or Length(sofar) = 0 then
        stream![4] := true;
        return fail;
    fi;
    while sofar[ Length(sofar) ] <> '\n' do
        chunk := IO_Read( stream![1], 1);
        if chunk = fail or Length(chunk) = 0 then
            stream![4] := true;
            return sofar;
        fi;
        Append( sofar, chunk );
    od;
    return sofar;
end);

BindGlobal( "ReadAllIoTCPStream",
function(stream, limit)
    local sofar, chunk, csize;
    if limit = -1 then
        csize := 20000;
    else
        csize := Minimum(20000,limit);
        limit := limit - csize;
    fi;
    sofar := IO_Read(stream![1], csize);
    if sofar = fail or Length(sofar) = 0 then
        stream![4] := true;
        return fail;
    fi;
    while limit <> 0  do
        if limit = -1 then
            csize := 20000;
        else
            csize := Minimum(20000,limit);
            limit := limit - csize;
        fi;
        chunk := IO_Read( stream![1], csize);
        if chunk = fail or Length(chunk) = 0 then
            stream![4] := true;
            return sofar;
        fi;
        Append(sofar,chunk);
    od;
    return sofar;
end);


InstallMethod( ReadAll, "for ioTCPstream",
               [ IsInputOutputTCPStreamRep and IsInputOutputStream ],
               stream ->  ReadAllIoTCPStream(stream, -1) );

InstallMethod( ReadAll, "for ioTCPstream",
               [ IsInputOutputTCPStreamRep and IsInputOutputStream, IsInt ],
function( stream, limit )
    if limit < 0 then
        Error("ReadAll: negative limit not allowed");
    fi;
    return  ReadAllIoTCPStream(stream, limit);
end);

InstallMethod( WriteByte, "for ioTCPstream",
               [ IsInputOutputTCPStreamRep and IsInputOutputStream, IsInt ],
function(stream, byte)
    local ret,s;
    if byte < 0 or 255 < byte  then
        Error( "<byte> must an integer between 0 and 255" );
    fi;
    s := [CHAR_INT(byte)];
    ConvertToStringRep( s );
    ret := IO_Write( stream![1], s );
    if ret <> 1 then
        return fail;
    else
        return true;
    fi;
end);

InstallMethod( WriteLine, "for ioTCPstream",
               [ IsInputOutputTCPStreamRep and IsInputOutputStream, IsString ],
function( stream, string )
    return IO_WriteLine( stream![1], string );
end);

InstallMethod( WriteAll, "for ioTCPstream",
               [ IsInputOutputTCPStreamRep and IsInputOutputStream, IsString ],
function( stream, string )
    local byte;
    for byte in string  do
        if WriteByte( stream, INT_CHAR(byte) ) <> true  then
            return fail;
        fi;
    od;
    return true;
end);

InstallMethod( IsEndOfStream, "iostream",
               [ IsInputOutputTCPStreamRep and IsInputOutputStream ],
stream -> not IO_HasData( stream![1] ) );
# TODO: when does this return true? -MT

InstallMethod( CloseStream, "for ioTCPstream",
               [ IsInputOutputTCPStreamRep and IsInputOutputStream ],
function(stream)
    IO_Close( stream![1] );
    SetFilterObj( stream, IsClosedStream );
end);

InstallMethod( FileDescriptorOfStream, "for ioTCPstream",
               [ IsInputOutputTCPStreamRep and IsInputOutputStream ],
               stream -> IO_GetFD( stream![1] ) );
