##  this creates the documentation, needs: GAPDoc package, latex, pdflatex,
##  mkindex, dvips
##  
##  $Id: makedoc.g,v 1.4 2003/11/20 21:59:44 chevie Exp $
##  

RequirePackage("GAPDoc");

MakeGAPDocDoc("doc", "io", [], "IO");

GAPDocManualLab("IO");

quit;

