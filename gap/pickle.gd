#############################################################################
##
#W  pickle.gd           GAP 4 package `IO'                    Max Neunhoeffer
##
#Y  Copyright (C)  2006,  Lehrstuhl D fuer Mathematik,  RWTH Aachen,  Germany
##
##  This file contains functions for pickling and unpickling.
##

BindGlobal( "IO_ResultsFamily", NewFamily( "IO_ResultsFamily" ) );
DeclareCategory( "IO_Result", IsComponentObjectRep );
DeclareGlobalVariable( "IO_Error" );
DeclareGlobalVariable( "IO_Nothing" );
DeclareGlobalVariable( "IO_OK" );

DeclareGlobalVariable( "IO_PICKLECACHE" );
DeclareGlobalVariable( "IO_ClearPickleCache" );
DeclareGlobalFunction( "IO_AddToPickled" );
DeclareGlobalFunction( "IO_FinalizePickled" );
DeclareGlobalFunction( "IO_AddToUnpickled" );
DeclareGlobalFunction( "IO_FinalizeUnpickled" );

DeclareGlobalFunction( "IO_WriteSmallInt" );
DeclareGlobalFunction( "IO_ReadSmallInt" );
DeclareGlobalFunction( "IO_WriteAttribute" );
DeclareGlobalFunction( "IO_ReadAttribute" );
DeclareGlobalFunction( "IO_PickleByString" );
DeclareGlobalFunction( "IO_UnpickleByEvalString" );
DeclareGlobalFunction( "IO_GenericObjectPickler" );
DeclareGlobalFunction( "IO_GenericObjectUnpickler" );

DeclareOperation( "IO_Pickle", [ IsFile, IsObject  ] );
DeclareOperation( "IO_Unpickle", [ IsFile ] );
BindGlobal ("IO_Unpicklers", rec() );

