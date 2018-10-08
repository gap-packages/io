# This code is mostly based on xstream.g{d,i} from the SCSCP package

DeclareInfoClass("InfoTCPSockets");


#! @Description
#! Printable version of an IP address
# TODO: Move to IO package
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

#! @Description
#! Creates a listening TCP socket
DeclareGlobalFunction("ListeningTCPSocket");

#! @Description
#! Start a TCP server
DeclareGlobalFunction("StartTCPServer");

#! @Description
#! Connects to a remote TCP server and returns an InputOutputTCPStream or fail
DeclareGlobalFunction("ConnectInputOutputTCPStream");

#! @Description
#! Accepts a connection on a listening TCP socket and returns an InputOutputTCPStream
#! or fail
DeclareGlobalFunction("AcceptInputOutputTCPStream");
