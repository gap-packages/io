#############################################################################
##
##  realrandom.gi           IO package 
##                                                        by Max Neunhoeffer
##                                                          and Felix Noeske
##
##  Copyright 2006 Lehrstuhl D für Mathematik, RWTH Aachen
##
##  Code for "real" random sources using /dev/random
##
#############################################################################

InstallMethod( RandomSource, "for a real random source", [IsString], 1,
  function( type )
    local f,r;
    if type <> "random" and type <> "urandom" then TryNextMethod(); fi;
    # Return the global random source:
    if type = "random" then
        f := IO_File("/dev/random",128);  # Use smaller buffer size
    else
        f := IO_File("/dev/urandom",1024);  # Use medium buffer size
    fi; 
    if f = fail then return fail; fi;
    r := rec(file := f);
    Objectify(RandomSourceType,r);
    SetFilterObj(r,IsRealRandomSourceRep);
    return r;
  end );

InstallMethod( Random, "for a real random source and two integers",
  [ IsRandomSource and IsRealRandomSourceRep, IsInt, IsInt ],
  function( r, f, t )
    local c,d,h,i,l,q,s;
    d := t-f;   # we need d+1 different outcomes from [0..d]
    if d <= 0 then return fail; fi;
    l := (Log2Int(d)+1);      # now 2^l >= d
    l := (l+7) - (l+7) mod 8; # this rounds up to a multiple of 8, still 2^l>=d
    q := QuoInt(2^l,d+1);     # now q*(d+1) <= 2^l < (q+1)*(d+1)
                              # thus for 0 <= x   < 2^l
                              # we have  0 <= x/q <= d+1 <= 2^l/q
                              # Thus if we do QuoInt(x,q) we get something
                              # between 0 and d inclusively, and if x is
                              # evenly distributed in [0..2^l-1], all values
                              # between 0 and d occur equally often
    repeat
        s := IO_Read(r!.file,l/8); # note that l is divisible by 8
        h := "";
        for c in s do Append(h,HexStringInt(INT_CHAR(c))); od;
        i := IntHexString(h);  # this is now between 0 and 2^l-1 inclusively
        i := QuoInt(i,q);
    until i <= d;
    return f+i;
  end );

InstallMethod( Random, "for a real random source and a list",
  [ IsRandomSource and IsRealRandomSourceRep, IsList ],
  function( r, l )
    local nr;
    repeat
        nr := Random(r,1,Length(l));
    until IsBound(l[nr]);
    return l[nr];
  end );

InstallMethod( ViewObj, "for a real random source",
  [IsRandomSource and IsRealRandomSourceRep],
  function(rs)
    Print("<a real random source>");
  end );

InstallMethod( Reset, "for a real random source",
  [IsRandomSource and IsRealRandomSourceRep],
  function(rs)
    Error("Real random sources cannot be Reset by definition");
  end );


