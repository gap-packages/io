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

if not LoadKernelExtension("io") then
  Error("failed to load the io package kernel extension");
fi;

ReadPackage("IO", "gap/io.gd");
ReadPackage("IO", "gap/pickle.gd");
ReadPackage("IO", "gap/realrandom.gd");
ReadPackage("IO", "gap/http.gd");
ReadPackage("IO", "gap/background.gd");
ReadPackage("IO", "gap/iohub.gd");
ReadPackage("IO", "gap/callwithtimeout.gd");

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
