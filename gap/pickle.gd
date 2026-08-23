#############################################################################
##
##  pickle.gd           GAP 4 package IO
##                                                           Max Neunhoeffer
##
##  Copyright (C) by Max Neunhoeffer
##  This file is free software, see license information at the end.
##
##  This file contains functions for pickling and unpickling.
##

DeclareGlobalFunction( "IO_ClearPickleCache" );
DeclareGlobalFunction( "IO_AddToPickled" );
DeclareGlobalFunction( "IO_IsAlreadyPickled" );
DeclareGlobalFunction( "IO_FinalizePickled" );
DeclareGlobalFunction( "IO_AddToUnpickled" );
DeclareGlobalFunction( "IO_FinalizeUnpickled" );

DeclareGlobalFunction( "IO_WriteSmallInt" );
DeclareGlobalFunction( "IO_ReadSmallInt" );
DeclareGlobalFunction( "IO_WriteAttribute" );
DeclareGlobalFunction( "IO_ReadAttribute" );
DeclareGlobalFunction( "IO_PickleByString" );
DeclareGlobalFunction( "IO_UnpickleByEvalString" );   # deprecated, see below
DeclareGlobalFunction( "IO_UnpickleByFunction" );
DeclareGlobalFunction( "IO_UnpickleByParser" );
DeclareGlobalFunction( "IO_ParseLegacyExpression" );
DeclareGlobalFunction( "IO_ParsePermString" );
DeclareGlobalFunction( "IO_GenericObjectPickler" );
DeclareGlobalFunction( "IO_GenericObjectUnpickler" );

DeclareOperation( "IO_Pickle", [ IsFile, IsObject  ] );
DeclareOperation( "IO_Unpickle", [ IsFile ] );
DeclareOperation( "IO_Pickle", [ IsObject ]);
DeclareOperation( "IO_Unpickle", [ IsStringRep ]);
BindGlobal ("IO_Unpicklers", rec() );

# Unpickling the source of a function means evaluating it, which lets a
# hostile pickle run arbitrary code, so it is refused unless this is set.
# Functions that are global variables are unpickled by name either way.
IO_UnpickleAllowEvalOfFunctions := false;

# Here is an overview over the defined tags in this package:
#
# CHAR  a character
# CYCC  a cyclotomic, as its coefficients over the rationals
# FAIL  fail
# FALS  false
# FFEC  a finite field element, as its coefficients over the prime field
# FLOT  a Floating point number
# FRAC  a rational number
# FUNC  a GAP function, if it is a global one, only its name is pickled
# GAPL  a gap in a list (unbound entries)
# GSLP  a GAP straight line program
# IF2M  an immutable compressed GF2 matrix
# IF2V  an immutable compressed GF2 vector
# IF8M  an immutable compressed 8Bit matrix
# IF8V  an immutable compressed 8Bit vector
# ILIS  an immutable list
# INTG  an integer
# IREC  an immutable record
# IRNG  an immutable range
# ISTR  an immutable string
# MF2M  a mutable compressed GF2 matrix
# MF2V  a mutable compressed GF2 vector
# MF8M  a mutable compressed 8Bit matrix
# MF8V  a mutable compressed 8Bit vector
# MLIS  a mutable list
# MREC  a mutable record
# MRNG  a mutable range
# MSTR  a mutable string
# NINF  minus infinity
# OPER  a GAP operation, only its name is pickled
# PINF  infinity
# POLF  an object in the representation IsPolynomialDefaultRep
# POLY  a Laurent polynomial (or a rational function) deprecated
# PPER  a partial permutation
# PRML  a permutation, as its list of images
# RATF  an object in the representation IsRationalFunctionDefaultRep
# RSGL  the global random source
# RSGA  a GAP random source
# RSMT  a Mersenne twister random source
# RSRE  a really random source
# SREF  a self-reference
# TRAN  a transformation
# TRUE  true
# UPOL  an object in the representation IsLaurentPolynomialDefaultRep
# URFU  an object in the representation IsUnivariateRationalFunctionDefaultRep
#
# These tags are only read, never written. They store the printed form of the
# object, which used to be read back with EvalString; that let a hostile
# pickle run arbitrary code, so they are parsed now and were replaced by the
# tags above. Files written before IO 4.11 still use them.
#
# CYCL  a cyclotomic
# FFEL  a finite field element
# PERM  a permutation
#
# Some tags defined in other packages:
#
# ICVC  an immutable cvec
# MCVC  a mutable cvec
# ICMA  an immutable cmat
# MCMA  a mutable cmat
# CMOD  a module from the CHOP package
# GWDG  a GAP word generator from the CHOP package
#

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
