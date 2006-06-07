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
DeclareGlobalFunction( "IO_ClearPickleCache" );
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

# Here is an overview over the defined tags in this package:
#
# CHAR  a character
# CYCL  a cyclotomic
# FAIL  fail
# FALS  false
# FFEL  a finite field element
# GAPL  a gap in a list (unbound entries)
# GSLP  a GAP straight line program
# IF2M  an immutable compressed GF2 matrix
# IF2V  an immutable compressed GF2 vector
# IF8M  an immutable compressed 8Bit matrix
# IF8V  an immutable compressed 8Bit vector
# ILIS  an immutable list
# INTG  an integer
# IREC  an immutable record
# ISTR  an immutable string
# MF2M  a mutable compressed GF2 matrix
# MF2V  a mutable compressed GF2 vector
# MF8M  a mutable compressed 8Bit matrix
# MF8V  a mutable compressed 8Bit vector
# MLIS  a mutable list
# MREC  a mutable record
# MSTR  a mutable string
# PERM  a permutation
# POLF  an object in the representation IsPolynomialDefaultRep
# POLY  a Laurent polynomial (or a rational function) deprecated
# RATF  an object in the representation IsRationalFunctionDefaultRep
# SPRF  SuPeRfail
# SREF  a self-reference
# TRUE  true
# UPOL  an object in the representation IsLaurentPolynomialDefaultRep
# URFU  an object in the representation IsUnivariateRationalFunctionDefaultRep
#
# Some tags defined in other packages:
#
# ICVC  an immutable cvec
# MCVC  a mutable cvec
# ICMA  an immutable cmat
# MCMA  a mutable cmat
# CMOD  a module from the CHOP package
#


