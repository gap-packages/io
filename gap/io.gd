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

DeclareGlobalFunction( "IO_WrapFD" );
DeclareGlobalFunction( "IO_File" );
DeclareGlobalFunction( "IO_Close" );
DeclareGlobalFunction( "IO_Read" );
DeclareGlobalFunction( "IO_ReadLine" );
DeclareGlobalFunction( "IO_ReadLines" );
DeclareGlobalFunction( "IO_Write" );
DeclareGlobalFunction( "IO_WriteLine" );
DeclareGlobalFunction( "IO_WriteLines" );
DeclareGlobalFunction( "IO_Flush" );
DeclareGlobalFunction( "IO_GetFD" );
DeclareGlobalFunction( "IO_GetWBuf" );
DeclareGlobalFunction( "IO_ListDir" );
DeclareGlobalFunction( "IO_MakeIPAddressPort" );
DeclareGlobalFunction( "IO_Environment" );
DeclareGlobalFunction( "IO_MakeEnvList" );
DeclareGlobalFunction( "IO_CloseAllFDs" );
DeclareGlobalFunction( "IO_Popen" );
DeclareGlobalFunction( "IO_Popen2" );
DeclareGlobalFunction( "IO_Popen3" );
DeclareGlobalFunction( "IO_SendStringBackground" );


