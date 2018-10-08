# Contact a server (1)
gap> stream := ConnectInputOutputTCPStream("www.google.com", 80);
<input/output TCP stream to www.google.com:80>
gap> IsInputOutputTCPStream(stream);
true
gap> WriteLine(stream, "GET");
4
gap> ReadLine(stream);
"HTTP/1.0 200 OK\r\n"
gap> CloseStream(stream);
gap> stream;
<closed input/output TCP stream to www.google.com:80>
gap> Print(stream, "\n");
<closed input/output TCP stream to www.google.com:80>

# Contact a server (2)
gap> stream := ConnectInputOutputTCPStream("www.google.com", 80);
<input/output TCP stream to www.google.com:80>
gap> WriteAll(stream, "DELE");
true
gap> WriteLine(stream, "TE");
3
gap> ReadAllIoTCPStream(stream, 40);
"HTTP/1.0 400 Bad Request\r\nContent-Type: "
gap> ReadAllIoTCPStream(stream, 40);
"text/html; charset=UTF-8\r\nReferrer-Polic"
gap> IsEndOfStream(stream);
false
gap> all := ReadAll(stream);;
gap> Length(all) > 500;
true
gap> ReadByte(stream);
fail
gap> ReadLine(stream);
fail
gap> ReadAllIoTCPStream(stream, 40);
fail
gap> CloseStream(stream);
gap> IsEndOfStream(stream);
Error, Tried to check for data on closed file.
gap> ReadAllIoTCPStream(stream, 40);
Error, Tried to read from closed file.

# Contact a server (3)
gap> stream := ConnectInputOutputTCPStream("www.google.com", 80);;
gap> WriteByte(stream, IntChar('G'));;
gap> WriteByte(stream, IntChar('E'));;
gap> WriteByte(stream, IntChar('T'));
true
gap> WriteLine(stream, "");
1
gap> ReadByte(stream) = IntChar('H');
true
gap> ReadLine(stream);
"TTP/1.0 200 OK\r\n"
gap> string := ReadAllIoTCPStream(stream, 21000);;
gap> Length(string) <= 21000;
true
gap> string := ReadAll(stream, 21000);;
gap> Length(string) <= 21000;
true
gap> CloseStream(stream);

# Serve a local client
gap> sock := IO_socket(IO.PF_INET, IO.SOCK_STREAM, "tcp");;
gap> lookup := IO_gethostbyname("localhost");;
gap> port := Random([20000..40000]);;
gap> res := IO_bind( sock, IO_make_sockaddr_in(lookup.addr[1], port));
true
gap> IO_listen(sock, 5);
true
gap> child := IO_fork();;
gap> if child = 0 then
>   clientstream := ConnectInputOutputTCPStream("localhost", port);;
>   WriteLine(clientstream, "12345");;
>   if ReadLine(clientstream){[1..5]} = "54321" then
>     WriteAll(clientstream, "Read successfully!");;
>   fi;
>   CloseStream(clientstream);
>   FORCE_QUIT_GAP(0);
> fi;
gap> socket_descriptor := IO_accept(sock, IO_MakeIPAddressPort("0.0.0.0", 0));;
gap> serverstream := AcceptInputOutputTCPStream(socket_descriptor);;
gap> FileDescriptorOfStream(serverstream) = socket_descriptor;
true
gap> ReadLine(serverstream);
"12345\n"
gap> WriteLine(serverstream, "54321");
6
gap> ReadLine(serverstream);
"Read successfully!"
gap> wait := IO_WaitPid(child, true);;
gap> wait.pid = child;
true
gap> wait.status;
0
gap> CloseStream(serverstream);

# Serve a local client with ListeningTCPSocket
gap> host := "localhost";;
gap> port := Random([20000..40000]);;
gap> sock := ListeningTCPSocket(host, port);;
gap> child := IO_fork();;
gap> if child = 0 then
>   clientstream := ConnectInputOutputTCPStream(host, port);;
>   WriteLine(clientstream, "12345");;
>   if ReadLine(clientstream){[1..5]} = "54321" then
>     WriteAll(clientstream, "Read successfully!");;
>   fi;
>   CloseStream(clientstream);
>   FORCE_QUIT_GAP(0);
> fi;
gap> socket_descriptor := IO_accept(sock, IO_MakeIPAddressPort("0.0.0.0", 0));;
gap> serverstream := AcceptInputOutputTCPStream(socket_descriptor);;
gap> FileDescriptorOfStream(serverstream) = socket_descriptor;
true
gap> ReadLine(serverstream);
"12345\n"
gap> WriteLine(serverstream, "54321");
6
gap> ReadLine(serverstream);
"Read successfully!"
gap> wait := IO_WaitPid(child, true);;
gap> wait.pid = child;
true
gap> wait.status;
0
gap> CloseStream(serverstream);

# TCP_AddrToString
gap> addr := IO_MakeIPAddressPort("123.234.87.6", 0);;
gap> TCP_AddrToString(addr);
"123.234.87.6"
gap> addr := IO_MakeIPAddressPort("0.0.0.0", 0);;
gap> TCP_AddrToString(addr);
"0.0.0.0"

# Errors
gap> stream := ConnectInputOutputTCPStream("www.google.com", 80);;
gap> ReadAll(stream, -1);
Error, ReadAll: negative limit not allowed
gap> WriteByte(stream, -1);
Error, <byte> must an integer between 0 and 255
gap> WriteByte(stream, 256);
Error, <byte> must an integer between 0 and 255
gap> CloseStream(stream);
gap> ListeningTCPSocket("www.rubbish.rubbish", 12345);
Error, ListeningTCPSocket: lookup failed on address www.rubbish.rubbish
gap> ListeningTCPSocket("localhost", "a hundred");
Error, ListeningTCPSocket:
<port> must be a positive integer no greater than 65535
gap> ListeningTCPSocket("www.google.com", 123);
Error, ListeningTCPSocket: failed to bind:
Cannot assign requested address
gap> ConnectInputOutputTCPStream("localhost", 12345);
Error, ConnectInputOutputTCPStream: Connection refused

# Vandalise a stream to cause IO to fail
gap> stream := ConnectInputOutputTCPStream("www.google.com", 80);;
gap> stream![1]!.wbufsize := 0;;
gap> stream![1]!.fd := "terrible input!";;
gap> WriteLine(stream, "GET");
fail
gap> WriteAll(stream, "GET");
fail
gap> WriteByte(stream, IntChar('G'));
fail
gap> CloseStream(stream);

# Vandalise IO variables to cause IO_socket to fail
gap> inet := IO.PF_INET;;
gap> IO.PF_INET := 0;;
gap> ListeningTCPSocket("www.google.com", 80);
Error, ListeningTCPSocket: failed to open socket:
Address family not supported by protocol
gap> IO.PF_INET := inet;;

# InputOutputTCPStream errors
gap> ConnectInputOutputTCPStream(80, "www.google.com");
Error, ConnectInputOutputTCPStream: <hostname> must be a string
gap> ConnectInputOutputTCPStream("www.google.com", "80");
Error, ConnectInputOutputTCPStream: <port> must be a non-negative integer
gap> ConnectInputOutputTCPStream("www.google.com", -80);
Error, ConnectInputOutputTCPStream: <port> must be a non-negative integer
gap> ConnectInputOutputTCPStream("www.g.michael", 80);
Error, ConnectInputOutputTCPStream: cannot find hostname www.g.michael
gap> AcceptInputOutputTCPStream(-1);
Error, AcceptInputOutputTCPStream: argument must be a non-negative integer
gap> AcceptInputOutputTCPStream("seventeen");
Error, AcceptInputOutputTCPStream: argument must be a non-negative integer
