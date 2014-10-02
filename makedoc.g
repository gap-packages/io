##
##  this creates the documentation, needs: GAPDoc package, latex, pdflatex,
##  mkindex, dvips
##  
##  Call this with GAP.
##  

PACKAGE := "IO";
SetPackagePath(PACKAGE, ".");
PrintTo("VERSION", PackageInfo(PACKAGE)[1].Version);

LoadPackage("GAPDoc");

if fail <> LoadPackage("AutoDoc", ">= 2014.03.27") then
    AutoDoc(PACKAGE : scaffold := rec( MainPage := false ));
else
    MakeGAPDocDoc("doc", PACKAGE, [], PACKAGE, "MathJax");
    CopyHTMLStyleFiles("doc");
    GAPDocManualLab(PACKAGE);
fi;

QUIT;

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
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
