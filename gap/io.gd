#############################################################################
##
#W  io.gd               GAP 4 package `IO'                    Max Neunhoeffer
##
#Y  Copyright (C)  2005,  Lehrstuhl D fuer Mathematik,  RWTH Aachen,  Germany
##
##  This file contains functions mid level IO providing buffering and
##  easier access from the GAP level. 
##
DeclareCategory( "IsFile", IsObject );
DeclareGlobalVariable( "FileType" );
DeclareAttribute( "ProcessID", IsFile );
