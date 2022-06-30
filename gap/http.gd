#############################################################################
##
##  http.gd               GAP 4 package IO
##                                                            Max Neunhoeffer
##
##  Copyright (C) 2006-2011 by Max Neunhoeffer
##  This file is free software, see license information at the end.
##
##  This file contains declarations for the implementation of the client
##  side of the HTTP protocol.
##

DeclareGlobalFunction( "OpenHTTPConnection" );
DeclareGlobalFunction( "HTTPRequest" );
DeclareGlobalFunction( "CloseHTTPConnection" );
DeclareGlobalFunction( "SingleHTTPRequest" );
DeclareGlobalFunction( "FixChunkedBody" );

DeclareGlobalFunction( "ReadWeb" );

##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <https://www.gnu.org/licenses/>.
##
