# This code is mostly based on xstream.g{d,i} from the SCSCP package

#! @Chapter TCP Streams
DeclareInfoClass("InfoTCPSockets");

#! @Description
#! Printable version of an IP address
#! @Arguments address
#! @Example
addr := IO_MakeIPAddressPort("127.0.0.1", 22);
#! "\<\000\000\026\000\000\>\000\000\000\000\000\000\000\000"
TCP_AddrToString(addr);
#! "127.0.0.1"
# @EndExample
DeclareGlobalFunction("TCP_AddrToString");

#! @Description
#!  <Ref Filt="IsInputOutputTCPStream"/> is a subcategory of
#!  <Ref BookName="ref" Filt="IsInputOutputStream"/>.
#!  Streams in the category <Ref Filt="IsInputOutputTCPStream"/>
#!  are created with the help of the function
#!  <Ref Func="InputOutputTCPStream" Label="for client" /> with
#!  one or two arguments dependently on whether they will be
#!  used in the client or server mode. Examples of their creation
#!  and usage will be given in subsequent sections.
DeclareCategory( "IsInputOutputTCPStream", IsInputOutputStream );

#! @Description
#!  This is the representation used for streams in the
#!  category <Ref Filt="IsInputOutputTCPStream"/>.
DeclareRepresentation( "IsInputOutputTCPStreamRep",
                       IsPositionalObjectRep, [ ] );

InputOutputTCPStreamDefaultType :=
  NewType( StreamsFamily,
           IsInputOutputTCPStreamRep and IsInputOutputTCPStream);

#! @Arguments hostname, port
#! @Description
#! Creates a listening TCP socket on the <A>hostname</A> and <A>port</A > given.
#! @Returns a file descriptor
#! @Log
sock := ListeningTCPSocket("localhost", 22222);;
socket_descriptor := IO_accept(sock, IO_MakeIPAddressPort("0.0.0.0", 0));;
serverstream := AcceptInputOutputTCPStream(socket_descriptor);;
#! @EndLog
DeclareGlobalFunction("ListeningTCPSocket");

#! @Arguments hostname, port, handerCallback
#! @Description
#! Creates and starts a TCP server on the address given in
#! <A>hostname</A> and the port given in <A>port</A>.
#! If a client connects, the function <A>handlerCallback</A>
#! is called with the address of the connected client as the first
#! argument, and an <Ref Filt="IsInputOutputStream"/> which can be
#! used to communicate with the client as second argument.
#!
#! Note this can currently only handle a single connection at a time.
#!
#! @Log
#! @EndLog
DeclareGlobalFunction("StartTCPServer");

#! @Arguments hostname, port
#! @Description
#! Connects to the remote TCP server <A>hostname</A> at <A>port</A>
#! and returns an InputOutputTCPStream on success or fail
DeclareGlobalFunction("ConnectInputOutputTCPStream");

#! @Arguments socket_descriptor
#! @Description
#! Accepts a connection on a listening TCP socket given by <A>socket_descriptor</A>
#! and returns an InputOutputTCPStream on success or fail
DeclareGlobalFunction("AcceptInputOutputTCPStream");
