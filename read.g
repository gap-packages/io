#############################################################################
##
##    read.g                 The IO package                  
##                                                           Max Neunhoeffer
##
##  Copyright (C) by Max Neunhoeffer
##  This file is free software, see license information at the end.
##

ReadPackage("IO", "gap/io.gi");
ReadPackage("IO", "gap/pickle.gi");
ReadPackage("IO", "gap/realrandom.gi");
ReadPackage("IO", "gap/http.gi");
ReadPackage("IO", "gap/background.gi");

# We now create the possibility that other packages can provide pickling
# and unpickling handlers.

if IsBound(IO_PkgThingsToRead) then
    for p in IO_PkgThingsToRead do
        ReadPackage(p[1],p[2]);
    od;
    Unbind(IO_PkgThingsToRead);
fi;

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
