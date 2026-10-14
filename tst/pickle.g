# Test file for pickling/unpickling:

# Preparations:
x := X(Rationals);
InstallMethod( EQ, [ IsStraightLineProgram, IsStraightLineProgram ],
  function(a,b)
    return LinesOfStraightLineProgram(a) = LinesOfStraightLineProgram(b) and
           NrInputsOfStraightLineProgram(a) = NrInputsOfStraightLineProgram(b);
  end );
InstallMethod( PrintObj,
    "for element in Z/pZ (ModulusRep)",
    [ IsZmodpZObj and IsModulusRep ],
    function( x )
    Print( "ZmodnZObj( ", x![1], ", ", Characteristic( x ), " )" );
    end );
InstallMethod( String,
    "for element in Z/pZ (ModulusRep)",
    [ IsZmodpZObj and IsModulusRep ],
    function( x )
      return Concatenation( "ZmodnZObj(", String(x![1]), ",",
      String(Characteristic( x )), ")" );
    end );

# HACK" for GAP before 4.9. avoid warning about
# "computing Conway polynomial".
old:=InfoLevel(InfoWarning);
SetInfoLevel(InfoWarning, 0);
Z(65537^2);
SetInfoLevel(InfoWarning, old);


# Build up a variety of different GAP objects in a list:
l := [

false,
true,
fail,
0,
-1,
1,
1234567123512636523123561311223123123123234234234,
1.0,
-1.0,
1.23456789123456789
-0., # Note, we test floats further at Error(36)
0.,
1.0/0.0, # inf
(-1.0)/0.0, # -inf
3.141^100,
3.141^-100,
Transformation([]),
Transformation([3,2,1]),
Transformation([1,1,1]),
Transformation([3,3,3]),
Transformation([100],[100]),
Transformation([100],[103]),
PartialPerm([]),
PartialPerm([2],[3]),
PartialPerm([1000],[999]),
PartialPerm([1000,1001],[1000,3]),
PartialPerm([9,10,20],[30,40,50]),
SymmetricGroup(5),
Group((1,2,3),(4,5,6)),
Group([],()),
"Max",
'M',
E(4),
E(4)+E(4)^3,
StraightLineProgram([[1,1,2,1,1,-1],[3,1,2,-1]],2),
Z(2),
Z(2)^0,
0*Z(2),
Z(2^3),
Z(2^3)^0,
0*Z(2^3),
Z(3),
Z(3)^0,
0*Z(3),
Z(3^5),
Z(3^5)^0,
0*Z(3^5),
Z(257),
0*Z(257),
Z(257)^0,
Z(257^4),
0*Z(257^4),
Z(257^4)^0,
Z(65537),
Z(65537)^0,
0*Z(65537),
Z(65537^2),
Z(65537^2)^0,
0*Z(65537^2),
(1,2,3,4),
,,,,   # a gap
x^2+x+1,
x^-3+1+x^4,
(x+1)/(x+2),
rec( a := 1, b := "Max" ),
rec( c := 3, d := "Till" ),

];

MakeImmutable(l[Length(l)]);

v := [Z(5),0*Z(5),Z(5)^2];
ConvertToVectorRep(v,5);
Add(l,v);
vecpos := Length(l);
w := ShallowCopy(v);
MakeImmutable(w);
Add(l,w);
vv := [Z(7),0*Z(7),Z(7)^2];
ConvertToVectorRep(vv,7^2);
Add(l,vv);
ww := ShallowCopy(vv);
MakeImmutable(ww);
Add(l,ww);
vvv := [Z(2),0*Z(2)];
ConvertToVectorRep(vvv,2);
Add(l,vvv);
www := ShallowCopy(vvv);
MakeImmutable(www);
Add(l,www);

# compressed matrices:
m := [[Z(5),0*Z(5),Z(5)^2]];
ConvertToMatrixRep(m,5);
Add(l,m);
n := MutableCopyMat(m);
ConvertToMatrixRep(n,5);
MakeImmutable(n);
Add(l,n);
mm := [[Z(7),0*Z(7),Z(7)^2]];
ConvertToMatrixRep(mm,7^2);
Add(l,mm);
nn := MutableCopyMat(mm);
ConvertToMatrixRep(nn,7^2);
MakeImmutable(nn);
Add(l,nn);
mmm := [[Z(2),0*Z(2)]];
ConvertToMatrixRep(mmm,2);
Add(l,mmm);
nnn := MutableCopyMat(mmm);
ConvertToMatrixRep(nnn,2);
MakeImmutable(nnn);
Add(l,nnn);

# Finally self-references:
r := rec( l := l, x := 1 );
r.r := r;
Add(l,l);
Add(l,r);

s := "";
f := IO_WrapFD(-1,false,s);
if IO_Pickle(f,l) <> IO_OK then Error(1); fi;
if IO_Pickle(f,"End") <> IO_OK then Error(2); fi;
IO_Close(f);

# Print("Bytes pickled: ",Length(s),"\n");

f := IO_WrapFD(-1,s,false);
ll := IO_Unpickle(f);
for i in [1..Length(l)-2] do
    if not( (not(IsBound(l[i])) and not(IsBound(ll[i]))) or
       (IsBound(l[i]) and IsBound(ll[i]) and l[i] = ll[i]) ) then
        Error(3);
    fi;
od;
if not(IsIdenticalObj(ll,ll[Length(ll)-1])) then Error(4); fi;
if not(IsIdenticalObj(ll,ll[Length(ll)].l)) then Error(5); fi;
if not(IsIdenticalObj(ll[Length(ll)],ll[Length(ll)].r)) then Error(6); fi;
if ll[Length(ll)].x <> l[Length(l)].x then Error(7); fi;
if not(IsMutable(ll[vecpos-2])) then Error(8); fi;
if IsMutable(ll[vecpos-1]) then Error(9); fi;
if not(Is8BitVectorRep(ll[vecpos])) then Error(10); fi;
if not(IsMutable(ll[vecpos])) then Error(11); fi;
if not(Is8BitVectorRep(ll[vecpos+1])) then Error(12); fi;
if IsMutable(ll[vecpos+1]) then Error(13); fi;
if not(Is8BitVectorRep(ll[vecpos+2])) then Error(14); fi;
if not(IsMutable(ll[vecpos+2])) then Error(15); fi;
if not(Is8BitVectorRep(ll[vecpos+3])) then Error(16); fi;
if IsMutable(ll[vecpos+3]) then Error(17); fi;
if not(IsGF2VectorRep(ll[vecpos+4])) then Error(18); fi;
if not(IsMutable(ll[vecpos+4])) then Error(19); fi;
if not(IsGF2VectorRep(ll[vecpos+5])) then Error(20); fi;
if IsMutable(ll[vecpos+5]) then Error(21); fi;
if not(Is8BitMatrixRep(ll[vecpos+6])) then Error(22); fi;
if not(IsMutable(ll[vecpos+6])) or not(IsMutable(ll[vecpos+6][1])) then
    Error(23);
fi;
if not(Is8BitMatrixRep(ll[vecpos+7])) then Error(24); fi;
if IsMutable(ll[vecpos+7]) or IsMutable(ll[vecpos+7]) then Error(25); fi;
if not(Is8BitMatrixRep(ll[vecpos+8])) then Error(26); fi;
if not(IsMutable(ll[vecpos+8])) or not(IsMutable(ll[vecpos+8])) then
    Error(27);
fi;
if not(Is8BitMatrixRep(ll[vecpos+9])) then Error(28); fi;
#if IsMutable(ll[vecpos+9]) or IsMutable(ll[vecpos+9][1]) then Error(29); fi;
if not(IsGF2MatrixRep(ll[vecpos+10])) then Error(30); fi;
if not(IsMutable(ll[vecpos+10])) or not(IsMutable(ll[vecpos+10][1])) then
    Error(31);
fi;
if not(IsGF2MatrixRep(ll[vecpos+11])) then Error(32); fi;
#if IsMutable(ll[vecpos+11]) or IsMutable(ll[vecpos+11][1]) then Error(33); fi;

ee := IO_Unpickle(f);
if ee <> "End" then Error(34); fi;

if IO_Unpickle(f) <> IO_Nothing then Error(35); fi;

IO_Close(f);

floatlist := [-0.0, 0.0, 0.0/0.0, 1.0/0.0, -1.0/0.0, 1.23456789123456789];

pickledlist := IO_Unpickle(IO_Pickle(floatlist));

# ExtRepOfObj deals with issues like infinity, -0 vs +0, nan, etc.

if List(floatlist, x -> ExtRepOfObj(x)) <>
   List(pickledlist, x -> ExtRepOfObj(x)) then
    Error(36);
fi;

rng:= IO_Unpickle( IO_Pickle( [ 1 .. 1000 ] ) );;
if rng <> [ 1 .. 1000 ] then
  Error( 37 );
elif not IsRangeRep( rng ) then
  Error( 38 );
fi;

g:= SymmetricGroup( 6 );;  tbl:= CharacterTable( g );;  Irr( tbl );;
tbl2:= IO_Unpickle( IO_Pickle( tbl ) );;
if not ( HasIrr( tbl ) and HasIrr( tbl2 ) ) then
  Error( 39 );
elif Irr( tbl ) <> Irr( tbl2 ) then
  Error( 40 );
elif not ( HasConjugacyClasses( UnderlyingGroup( tbl ) )
           and HasConjugacyClasses( UnderlyingGroup( tbl2 ) ) ) then
  Error( 41 );
elif ConjugacyClasses( UnderlyingGroup( tbl ) )
     <> ConjugacyClasses( UnderlyingGroup( tbl2 ) ) then
  Error( 42 );
fi;

# Check we can unpickle old pickled data
# Generated with GAP 4.12.0, IO 4.7.2 on 2022-09-08
pickled_l := "MLIS\<52FALSTRUEFAILINTG\>10INTG\>2-1INTG\>11INTG\<28D83FE78A80042DF6FD2034951C81859E557F5F7AFLOT\>21.FLOT\>3-1.FLOT\
\<121.2345678912345679FLOT\>20.FLOT\>3infFLOT\>4-infFLOT\<165.0908891397056544e+49FLOT\<161.9642934123248629e-50TRANIL\
IS\>0TRANILIS\>3INTG\>13INTG\>12INTG\>11TRANILIS\>3INTG\>11INTG\>11INTG\>11TRANILIS\>3INTG\>13INTG\>13INTG\>13TRANILIS\
\>0TRANILIS\<67INTG\>11INTG\>12INTG\>13INTG\>14INTG\>15INTG\>16INTG\>17INTG\>18INTG\>19INTG\>1AINTG\>1BINTG\>1CINTG\>1\
DINTG\>1EINTG\>1FINTG\>210INTG\>211INTG\>212INTG\>213INTG\>214INTG\>215INTG\>216INTG\>217INTG\>218INTG\>219INTG\>21AIN\
TG\>21BINTG\>21CINTG\>21DINTG\>21EINTG\>21FINTG\>220INTG\>221INTG\>222INTG\>223INTG\>224INTG\>225INTG\>226INTG\>227INT\
G\>228INTG\>229INTG\>22AINTG\>22BINTG\>22CINTG\>22DINTG\>22EINTG\>22FINTG\>230INTG\>231INTG\>232INTG\>233INTG\>234INTG\
\>235INTG\>236INTG\>237INTG\>238INTG\>239INTG\>23AINTG\>23BINTG\>23CINTG\>23DINTG\>23EINTG\>23FINTG\>240INTG\>241INTG\
\>242INTG\>243INTG\>244INTG\>245INTG\>246INTG\>247INTG\>248INTG\>249INTG\>24AINTG\>24BINTG\>24CINTG\>24DINTG\>24EINTG\
\>24FINTG\>250INTG\>251INTG\>252INTG\>253INTG\>254INTG\>255INTG\>256INTG\>257INTG\>258INTG\>259INTG\>25AINTG\>25BINTG\
\>25CINTG\>25DINTG\>25EINTG\>25FINTG\>260INTG\>261INTG\>262INTG\>263INTG\>267INTG\>265INTG\>266INTG\>267PPERILIS\>0MLI\
S\>0PPERILIS\>1INTG\>12MLIS\>1INTG\>13PPERILIS\>1INTG\>33E8MLIS\>1INTG\>33E7PPERILIS\>2INTG\>33E8INTG\>33E9MLIS\>2INTG\
\>33E8INTG\>13PPERILIS\>3INTG\>19INTG\>1AINTG\>214MLIS\>3INTG\>21EINTG\>228INTG\>232PRMGILIS\>2PERM\>B(1,2,3,4,5)PERM\
\>5(1,2)INTG\>278FAILPRMGILIS\>2PERM\>7(1,2,3)PERM\>7(4,5,6)FAILFAILPRMGILIS\>0INTG\>11FAILMSTR\>3MaxCHARMCYCL\>4E(4)I\
NTG\>10GSLPILIS\>2ILIS\>6INTG\>11INTG\>11INTG\>12INTG\>11INTG\>11INTG\>2-1ILIS\>4INTG\>13INTG\>11INTG\>12INTG\>2-1INTG\
\>12FFEL\>6Z(2)^0FFEL\>6Z(2)^0FFEL\>60*Z(2)FFEL\>6Z(2^3)FFEL\>6Z(2)^0FFEL\>60*Z(2)FFEL\>4Z(3)FFEL\>6Z(3)^0FFEL\>60*Z(3\
)FFEL\>6Z(3^5)FFEL\>6Z(3)^0FFEL\>60*Z(3)FFEL\>6Z(257)FFEL\>80*Z(257)FFEL\>8Z(257)^0FFEL\>8Z(257,4)FFEL\>80*Z(257)FFEL\
\>8Z(257)^0FFEL\<12ZmodnZObj(3,65537)FFEL\<12ZmodnZObj(1,65537)FFEL\<12ZmodnZObj(0,65537)FFEL\>AZ(65537,2)FFEL\<12Zmod\
nZObj(1,65537)FFEL\<12ZmodnZObj(0,65537)PERM\>9(1,2,3,4)GAPL\>4UPOLINTG\>11ILIS\>2ILIS\>3INTG\>11INTG\>11INTG\>11INTG\
\>10INTG\>11UPOLINTG\>11ILIS\>2ILIS\>8INTG\>11INTG\>10INTG\>10INTG\>11INTG\>10INTG\>10INTG\>10INTG\>11INTG\>2-3INTG\>1\
1URFUINTG\>11ILIS\>3ILIS\>2INTG\>11INTG\>11ILIS\>2INTG\>12INTG\>11INTG\>10INTG\>11MREC\>2ISTR\>1bMSTR\>3MaxISTR\>1aINT\
G\>11IREC\>2ISTR\>1cINTG\>13ISTR\>1dISTR\>4TillMF8V\>3FFEL\>4Z(5)FFEL\>60*Z(5)FFEL\>6Z(5)^2IF8V\>3FFEL\>4Z(5)FFEL\>60*\
Z(5)FFEL\>6Z(5)^2MF8V\>3FFEL\>4Z(7)FFEL\>60*Z(7)FFEL\>6Z(7)^2IF8V\>3FFEL\>4Z(7)FFEL\>60*Z(7)FFEL\>6Z(7)^2MF2V\>2FFEL\>\
6Z(2)^0FFEL\>60*Z(2)IF2V\>2FFEL\>6Z(2)^0FFEL\>60*Z(2)MF8M\>1MF8V\>3FFEL\>4Z(5)FFEL\>60*Z(5)FFEL\>6Z(5)^2IF8M\>1MF8V\>3\
FFEL\>4Z(5)FFEL\>60*Z(5)FFEL\>6Z(5)^2MF8M\>1MF8V\>3FFEL\>4Z(7)FFEL\>60*Z(7)FFEL\>6Z(7)^2IF8M\>1MF8V\>3FFEL\>4Z(7)FFEL\
\>60*Z(7)FFEL\>6Z(7)^2MF2M\>1MF2V\>2FFEL\>6Z(2)^0FFEL\>60*Z(2)IF2M\>1MF2V\>2FFEL\>6Z(2)^0FFEL\>60*Z(2)SREF\>1MREC\>3IS\
TR\>1xINTG\>11ISTR\>1lSREF\>1ISTR\>1rSREF\<33";

unpickle_l := IO_Unpickle(pickled_l);

if Length(l) <> Length(unpickle_l) then
  Error( 43 );
fi;

for i in [1..Length(l)-2] do
    if not( (not(IsBound(l[i])) and not(IsBound(unpickle_l[i]))) or
       (IsBound(l[i]) and IsBound(unpickle_l[i]) and l[i] = unpickle_l[i]) ) then
        Error( 44 );
    fi;
od;

if not IsIdenticalObj(unpickle_l, unpickle_l[Length(unpickle_l) - 1]) then
  Error( 45 );
fi;

pickled_floatlist := "MLIS\>6FLOT\>3-0.FLOT\>20.FLOT\>3nanFLOT\>3infFLOT\>4-infFLOT\<121.2345678912345679";;

unpickled_floatlist := IO_Unpickle(pickled_floatlist);

if List(floatlist, x -> ExtRepOfObj(x)) <>
   List(unpickled_floatlist, x -> ExtRepOfObj(x)) then
    Error(46);
fi;
