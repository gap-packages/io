#############################################################################
##
##  init.g               IO-package                           
##                                                           Max Neunhoeffer
##
##  Copyright (C) by Max Neunhoeffer
##  This file is free software, see license information at the end.
##  
##  Initialization of the IO package
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

ReadPackage("IO", "gap/io.gd");
ReadPackage("IO", "gap/pickle.gd");
ReadPackage("IO", "gap/realrandom.gd");
ReadPackage("IO", "gap/http.gd");
ReadPackage("IO", "gap/background.gd");

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
