#############################################################################
##
#W  http.gd               GAP 4 package `IO'  
##                                                            Max Neunhoeffer
##
#Y  Copyright (C)  2006,  Lehrstuhl D fuer Mathematik,  RWTH Aachen,  Germany
##
##  This file contains declarations for the implementation of the client 
##  side of the HTTP protocol.
##

DeclareGlobalVariable( "HTTPTimeoutForSelect" );
DeclareGlobalFunction( "OpenHTTPConnection" );
DeclareGlobalFunction( "HTTPRequest" );
DeclareGlobalFunction( "CloseHTTPConnection" );
DeclareGlobalFunction( "SingleHTTPRequest" );


