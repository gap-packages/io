#############################################################################
##
##  pickle.gi           GAP 4 package IO
##                                                           Max Neunhoeffer
##
##  Copyright (C) by Max Neunhoeffer
##  This file is free software, see license information at the end.
##
##  This file contains functions for pickling and unpickling.
##

#################
# (Un-)Pickling:
#################

BindGlobal( "IO_PICKLECACHE", rec( ids := [], nrs := [], obs := [],
                                   depth := 0 ) );

InstallGlobalFunction( IO_ClearPickleCache,
  function( )
    IO_PICKLECACHE.ids := [];
    IO_PICKLECACHE.nrs := [];
    IO_PICKLECACHE.obs := [];
    IO_PICKLECACHE.depth := 0;
  end );

InstallGlobalFunction( IO_AddToPickled,
  function( ob )
    local id,pos;
    IO_PICKLECACHE.depth := IO_PICKLECACHE.depth + 1;
    id := MASTER_POINTER_NUMBER(ob);
    pos := PositionSorted( IO_PICKLECACHE.ids, id );
    if pos <= Length(IO_PICKLECACHE.ids) and IO_PICKLECACHE.ids[pos] = id then
        return IO_PICKLECACHE.nrs[pos];
    else
        Add(IO_PICKLECACHE.ids,id,pos);
        Add(IO_PICKLECACHE.nrs,Length(IO_PICKLECACHE.ids),pos);
        # Store a reference here so the result of
        # MASTER_POINTER_NUMBER will not get reused by another object.
        Add(IO_PICKLECACHE.obs,ob);
        return false;
    fi;
  end );

InstallGlobalFunction( IO_IsAlreadyPickled,
  function( ob )
    local id,pos;
    id := MASTER_POINTER_NUMBER(ob);
    pos := PositionSorted( IO_PICKLECACHE.ids, id );
    if pos <= Length(IO_PICKLECACHE.ids) and IO_PICKLECACHE.ids[pos] = id then
        return IO_PICKLECACHE.nrs[pos];
    else
        return false;
    fi;
  end );

InstallGlobalFunction( IO_FinalizePickled,
  function( )
    if IO_PICKLECACHE.depth <= 0 then
        Error("pickling depth has gone below zero!");
    fi;
    IO_PICKLECACHE.depth := IO_PICKLECACHE.depth - 1;
    if IO_PICKLECACHE.depth = 0 then
        # important to clear the cache:
        IO_ClearPickleCache();
    fi;
  end );

InstallGlobalFunction( IO_AddToUnpickled,
  function( ob )
    IO_PICKLECACHE.depth := IO_PICKLECACHE.depth + 1;
    Add( IO_PICKLECACHE.obs, ob );
  end );

InstallGlobalFunction( IO_FinalizeUnpickled,
  function( )
    if IO_PICKLECACHE.depth <= 0 then
        Error("pickling depth has gone below zero!");
    fi;
    IO_PICKLECACHE.depth := IO_PICKLECACHE.depth - 1;
    if IO_PICKLECACHE.depth = 0 then
        # important to clear the cache:
        IO_ClearPickleCache();
    fi;
  end );

InstallGlobalFunction( IO_WriteSmallInt,
  function( f, i )
    local h,l;
    h := HexStringInt(i);
    l := Length(h);
    Add(h,CHAR_INT(Length(h)),1);
    if IO_Write(f,h) = fail then
        return IO_Error;
    else
        return IO_OK;
    fi;
  end );

InstallGlobalFunction( IO_ReadSmallInt,
  function( f )
    local h,l;
    l := IO_ReadBlock(f,1);
    if l = "" or l = fail then return IO_Error; fi;
    h := IO_ReadBlock(f,INT_CHAR(l[1]));
    if h = fail or Length(h) < INT_CHAR(l[1]) then return IO_Error; fi;
    return IntHexString(h);
  end );

InstallGlobalFunction( IO_WriteAttribute,
  # can also do properties
  function( f, at, ob )
    if IO_Pickle(f, Tester(at)(ob)) = IO_Error then return IO_Error; fi;
    if Tester(at)(ob) then
        if IO_Pickle(f, at(ob)) = IO_Error then return IO_Error; fi;
    fi;
    return IO_OK;
  end );

InstallGlobalFunction( IO_ReadAttribute,
  # can also do properties
  function( f, at, ob )
    local val;
    val := IO_Unpickle(f);
    if val = IO_Error then return IO_Error; fi;
    if val = true then
        val := IO_Unpickle(f);
        if val = IO_Error then return IO_Error; fi;
        Setter(at)(ob,val);
    fi;
    return IO_OK;
  end );

InstallGlobalFunction( IO_PickleByString,
  function( f, ob, tag )
    local s;
    s := String(ob);
    if IO_Write(f,tag) = fail then return IO_Error; fi;
    if IO_WriteSmallInt(f,Length(s)) = IO_Error then return IO_Error; fi;
    if IO_Write(f,s) = fail then return IO_Error; fi;
    return IO_OK;
  end );

InstallGlobalFunction( IO_UnpickleByFunction,
  function( unpickleFn )
    return function( f )
      local len,s;
      len := IO_ReadSmallInt(f);
      if len = IO_Error then return IO_Error; fi;
      s := IO_ReadBlock(f,len);
      if s = fail or Length(s) < len then return IO_Error; fi;
      return unpickleFn(s);
    end;
  end );

# Deprecated: this evaluates its input, so a hostile pickle can run arbitrary
# code. Kept only because it is a documented global. Use a parser instead.
InstallGlobalFunction( IO_UnpickleByEvalString,
    IO_UnpickleByFunction(EvalString)
);

#############################################################################
##
##  Readers for the deprecated PERM, FFEL and CYCL formats.
##
##  These store the printed form of the object and used to be read back with
##  EvalString, which let a hostile pickle run arbitrary code (issue #7). They
##  are parsed instead. New pickles use PRML, FFEC and CYCC.
##

# The only functions a deprecated pickle may name. The bounds stop a hostile
# pickle from asking for an object large enough to exhaust memory; they are
# far above anything GAP ever printed.
BindGlobal( "IO_LegacyFuncs", rec(
  E := rec(
    check := a -> Length(a) = 1 and a[1] >= 1 and a[1] <= 2^24,
    call  := a -> E(a[1]) ),
  Z := rec(
    check := a -> (Length(a) = 1 and a[1] <= 2^48 and IsPrimePowerInt(a[1]))
               or (Length(a) = 2 and a[1] <= 2^48 and IsPrimeInt(a[1])
                                 and a[2] >= 1 and a[2] <= 2^16),
    call  := a -> CallFuncList(Z,a) ),
  ZmodnZObj := rec(
    check := a -> Length(a) = 2 and a[2] >= 1 and a[2] <= 2^48,
    call  := a -> ZmodnZObj(a[1],a[2]) ),
  ZmodpZObj := rec(
    check := a -> Length(a) = 2 and a[2] <= 2^48 and IsPrimeInt(a[2]),
    call  := a -> ZmodpZObj(a[1],a[2]) ),
) );

# Finite field elements and cyclotomics live in disjoint modes so that no
# expression can mix them; together with the guards below this makes every
# operation total, so nothing in here can throw.
BindGlobal( "IO_LegacyFFEMode", rec(
    funcs    := [ "Z", "ZmodnZObj", "ZmodpZObj" ],
    allowdiv := false,
    ok       := v -> IsInt(v) or IsFFE(v),
    final    := IsFFE ) );

BindGlobal( "IO_LegacyCycMode", rec(
    funcs    := [ "E" ],
    allowdiv := true,
    ok       := IsCyclotomic,
    final    := IsCyclotomic ) );

InstallGlobalFunction( IO_ParseLegacyExpression,
  function( s, mode )
    local len, pos, skip, integer, combine, atom, factor, term, expr, res;

    len := Length(s);
    pos := 1;

    skip := function()
        while pos <= len and s[pos] = ' ' do pos := pos + 1; od;
      end;

    integer := function()
        local start;
        start := pos;
        while pos <= len and IsDigitChar(s[pos]) do pos := pos + 1; od;
        if pos = start then return fail; fi;
        return Int(s{[start..pos-1]});
      end;

    combine := function( op, a, b )
        if IsFFE(a) and IsFFE(b) and Characteristic(a) <> Characteristic(b) then
            return fail;
        fi;
        if op = '+' then return a + b;
        elif op = '-' then return a - b;
        elif op = '*' then return a * b;
        elif IsZero(b) then return fail;
        else return a / b; fi;
      end;

    atom := function()
        local start, name, entry, args, a;
        skip();
        if pos > len then return fail; fi;
        if s[pos] = '(' then
            pos := pos + 1;
            a := expr();
            if a = fail then return fail; fi;
            skip();
            if pos > len or s[pos] <> ')' then return fail; fi;
            pos := pos + 1;
            return a;
        fi;
        if IsDigitChar(s[pos]) then return integer(); fi;
        start := pos;
        while pos <= len and IsAlphaChar(s[pos]) do pos := pos + 1; od;
        name := s{[start..pos-1]};
        if not name in mode.funcs then return fail; fi;
        entry := IO_LegacyFuncs.(name);
        skip();
        if pos > len or s[pos] <> '(' then return fail; fi;
        pos := pos + 1;
        args := [];
        skip();
        if pos <= len and s[pos] = ')' then
            pos := pos + 1;
        else
            while true do
                a := expr();
                if not IsInt(a) or a < 0 then return fail; fi;
                Add(args,a);
                skip();
                if pos > len then return fail; fi;
                if s[pos] = ')' then pos := pos + 1; break; fi;
                if s[pos] <> ',' then return fail; fi;
                pos := pos + 1;
            od;
        fi;
        if not entry.check(args) then return fail; fi;
        return entry.call(args);
      end;

    factor := function()
        local neg, base, e;
        skip();
        neg := false;
        while pos <= len and (s[pos] = '-' or s[pos] = '+') do
            if s[pos] = '-' then neg := not neg; fi;
            pos := pos + 1;
            skip();
        od;
        base := atom();
        if base = fail or not mode.ok(base) then return fail; fi;
        skip();
        if pos <= len and s[pos] = '^' then
            pos := pos + 1;
            e := factor();
            if e = fail or not IsInt(e) then return fail; fi;
            if e < 0 and IsZero(base) then return fail; fi;
            # a rational base with a large exponent is a memory bomb, and no
            # printed GAP object needs one
            if IsRat(base) and AbsInt(e) > 1024 then return fail; fi;
            base := base ^ e;
        fi;
        if neg then base := - base; fi;
        return base;
      end;

    term := function()
        local res, op, rhs;
        res := factor();
        if res = fail then return fail; fi;
        while true do
            skip();
            if pos > len then return res; fi;
            op := s[pos];
            if op <> '*' and op <> '/' then return res; fi;
            if op = '/' and not mode.allowdiv then return res; fi;
            pos := pos + 1;
            rhs := factor();
            if rhs = fail then return fail; fi;
            res := combine(op,res,rhs);
            if res = fail or not mode.ok(res) then return fail; fi;
        od;
      end;

    expr := function()
        local res, op, rhs;
        res := term();
        if res = fail then return fail; fi;
        while true do
            skip();
            if pos > len then return res; fi;
            op := s[pos];
            if op <> '+' and op <> '-' then return res; fi;
            pos := pos + 1;
            rhs := term();
            if rhs = fail then return fail; fi;
            res := combine(op,res,rhs);
            if res = fail or not mode.ok(res) then return fail; fi;
        od;
      end;

    res := expr();
    if res = fail then return fail; fi;
    skip();
    if pos <= len or not mode.final(res) then return fail; fi;
    return res;
  end );

InstallGlobalFunction( IO_ParsePermString,
  function( s )
    local imgs, len, pos, cyc, start, n, i;
    imgs := [];
    len := Length(s);
    pos := 1;
    while pos <= len do
        if s[pos] <> '(' then return fail; fi;
        pos := pos + 1;
        cyc := [];
        while pos <= len and s[pos] <> ')' do
            if not IsEmpty(cyc) then
                if s[pos] <> ',' then return fail; fi;
                pos := pos + 1;
            fi;
            start := pos;
            while pos <= len and IsDigitChar(s[pos]) do pos := pos + 1; od;
            if pos = start then return fail; fi;
            n := Int(s{[start..pos-1]});
            # MAX_DEG_PERM4 is 2^28-1; anything beyond is not a permutation
            if n < 1 or n >= 2^28 or IsBound(imgs[n]) then return fail; fi;
            imgs[n] := n;
            Add(cyc,n);
        od;
        if pos > len then return fail; fi;   # unterminated cycle
        pos := pos + 1;
        for i in [1..Length(cyc)] do
            imgs[cyc[i]] := cyc[(i mod Length(cyc)) + 1];
        od;
    od;
    for i in [1..Length(imgs)] do
        if not IsBound(imgs[i]) then imgs[i] := i; fi;
    od;
    return PermList(imgs);
  end );

InstallGlobalFunction( IO_UnpickleByParser,
  function( parse )
    return function( f )
      local len, s, res;
      len := IO_ReadSmallInt(f);
      if len = IO_Error then return IO_Error; fi;
      s := IO_ReadBlock(f,len);
      if s = fail or Length(s) < len then return IO_Error; fi;
      res := parse(s);
      if res = fail then
          Info(InfoWarning, 1, "IO_Unpickle: malformed pickle \"",s,"\"");
          return IO_Error;
      fi;
      return res;
    end;
  end );

InstallGlobalFunction( IO_GenericObjectPickler,
  function( f, tag, prepickle, ob, atts, filts, comps )
    local at,com,fil,nr,o;
    nr := IO_IsAlreadyPickled(ob);
    if nr = false then    # not yet known
        if IO_Write(f,tag) = fail then return IO_Error; fi;
        for o in prepickle do
            if IO_Pickle(f,o) = IO_Error then return IO_Error; fi;
        od;
        nr := IO_AddToPickled(ob);
        if nr <> false then
            Error("prepickle objects had references to object - panic!");
            return IO_Error;
        fi;
        for at in atts do
            if IO_WriteAttribute(f,at,ob) = IO_Error then
                IO_FinalizePickled();
                return IO_Error;
            fi;
        od;
        for fil in filts do
            if IO_Pickle(f,fil(ob)) = IO_Error then
                IO_FinalizePickled();
                return IO_Error;
            fi;
        od;
        for com in comps do
            if IsBound(ob!.(com)) then
                if IO_Pickle(f,com) = IO_Error then
                    IO_FinalizePickled();
                    return IO_Error;
                fi;
                if IO_Pickle(f,ob!.(com)) = IO_Error then
                    IO_FinalizePickled();
                    return IO_Error;
                fi;
            fi;
        od;
        IO_FinalizePickled();
        if IO_Pickle(f,fail) = IO_Error then return IO_Error; fi;
        return IO_OK;
    else   # this object was already pickled once!
        if IO_Write(f,"SREF") = IO_Error then
            return IO_Error;
        fi;
        if IO_WriteSmallInt(f,nr) = IO_Error then
            return IO_Error;
        fi;
        return IO_OK;
    fi;
  end );

InstallGlobalFunction( IO_GenericObjectUnpickler,
  function( f, ob, atts, filts )
    local at,fil,val,val2;
    IO_AddToUnpickled(ob);
    for at in atts do
        if IO_ReadAttribute(f,at,ob) = IO_Error then
            IO_FinalizeUnpickled();
            return IO_Error;
        fi;
    od;
    for fil in filts do
        val := IO_Unpickle(f);
        if val = IO_Error then
            IO_FinalizeUnpickled();
            return IO_Error;
        fi;
        if val <> fil(ob) then
            if val then
                SetFilterObj(ob,fil);
            else
                ResetFilterObj(ob,fil);
            fi;
        fi;
    od;
    while true do
        val := IO_Unpickle(f);
        if val = fail then
            IO_FinalizeUnpickled();
            return ob;
        fi;
        if val = IO_Error then
            IO_FinalizeUnpickled();
            return IO_Error;
        fi;
        if IsString(val) then
            val2 := IO_Unpickle(f);
            if val2 = IO_Error then
                IO_FinalizeUnpickled();
                return IO_Error;
            fi;
            ob!.(val) := val2;
        fi;
    od;
  end );


InstallMethod( IO_Unpickle, "for a file",
  [ IsFile ],
  function( f )
    local magic,up;
    magic := IO_ReadBlock(f,4);
    if magic = fail then return IO_Error;
    elif Length(magic) < 4 then return IO_Nothing;
    fi;
    if not(IsBound(IO_Unpicklers.(magic))) then
        Info(InfoWarning, 1, "No unpickler for magic value \"",magic,"\"");
        Info(InfoWarning, 
             1, 
             "Maybe you have to load a package for this to work?");
        return IO_Error;
    fi;
    up := IO_Unpicklers.(magic);
    if IsFunction(up) then
        return up(f);
    else
        return up;
    fi;
  end );

InstallMethod(IO_Pickle, "for an object, pickle to string method",
  [IsObject],
  function(o)
    local f,res,s;
    s := "";
    f := IO_WrapFD(-1,false,s);
    res := IO_Pickle(f,o);
    IO_Close(f);
    if res = IO_Error then return IO_Error; fi;
    ShrinkAllocationString(s);
    return s;
  end);

InstallMethod(IO_Unpickle, "for a string, unpickle from string method",
  [IsStringRep],
  function(s)
    local f,o;
    f := IO_WrapFD(-1,s,false);
    o := IO_Unpickle(f);
    IO_Close(f);
    return o;
  end);

InstallMethod( IO_Pickle, "for an integer",
  [ IsFile, IsInt ],
  function( f, i )
    local h;
    if IO_Write( f, "INTG" ) = fail then return IO_Error; fi;
    h := HexStringInt(i);
    if IO_WriteSmallInt( f, Length(h) ) = fail then return IO_Error; fi;
    if IO_Write(f,h) = fail then return fail; fi;
    return IO_OK;
  end );

IO_Unpicklers.INTG :=
  function( f )
    local h,len;
    len := IO_ReadSmallInt(f);
    if len = IO_Error then return IO_Error; fi;
    h := IO_ReadBlock(f,len);
    if h = fail or Length(h) < len then return IO_Error; fi;
    return IntHexString(h);
  end;

InstallMethod( IO_Pickle, "for a string",
  [ IsFile, IsStringRep and IsList ],
  function( f, s )
    local tag;
    if IsMutable(s) then tag := "MSTR";
    else tag := "ISTR"; fi;
    if IO_Write(f,tag) = fail then return IO_Error; fi;
    if IO_WriteSmallInt(f, Length(s)) = IO_Error then return IO_Error; fi;
    if IO_Write(f,s) = fail then return IO_Error; fi;
    return IO_OK;
  end );

IO_Unpicklers.MSTR :=
  function( f )
    local len,s;
    len := IO_ReadSmallInt(f);
    if len = IO_Error then return IO_Error; fi;
    s := IO_ReadBlock(f,len);
    if s = fail or Length(s) < len then return IO_Error; fi;
    return s;
  end;

IO_Unpicklers.ISTR :=
  function( f )
    local s;
    s := IO_Unpicklers.MSTR(f); if s = IO_Error then return IO_Error; fi;
    MakeImmutable(s);
    return s;
  end;

InstallMethod( IO_Pickle, "for a boolean",
  [ IsFile, IsBool ],
  function( f, b )
    local val;
    if b = false then val := "FALS";
    elif b = true then val := "TRUE";
    elif b = fail then val := "FAIL";
    else
        Error("Unknown boolean value");
    fi;
    if IO_Write(f,val) = fail then
        return IO_Error;
    else
        return IO_OK;
    fi;
  end );

IO_Unpicklers.FALS := false;
IO_Unpicklers.TRUE := true;
IO_Unpicklers.FAIL := fail;
IO_Unpicklers.SPRF :=
  function( f )
    Info(InfoWarning, 1, "unpickling deprecated 'SuPeRfail' value");
    return "SuPeRfail";
  end;

InstallMethod( IO_Pickle, "for a permutation",
  [ IsFile, IsPerm ],
  function( f, p )
    if IO_Write(f,"PRML") = fail then return IO_Error; fi;
    return IO_Pickle(f,ListPerm(p));
  end );

IO_Unpicklers.PRML :=
  function( f )
    local l,p;
    l := IO_Unpickle(f); if l = IO_Error then return IO_Error; fi;
    if not IsList(l) then return IO_Error; fi;
    p := PermList(l);
    if p = fail then return IO_Error; fi;
    return p;
  end;

IO_Unpicklers.PERM := IO_UnpickleByParser( IO_ParsePermString );

InstallMethod( IO_Pickle, "for a transformation",
  [ IsFile, IsTransformation ],
  function( f, t )
    if IO_Write(f,"TRAN") = fail then return IO_Error; fi;
    if IO_Pickle(f,ListTransformation(t)) = IO_Error then
        return IO_Error;
    fi;
    return IO_OK;
  end);

IO_Unpicklers.TRAN :=
  function( f )
    local l;
    l := IO_Unpickle(f);
    if l = IO_Error then return IO_Error; fi;
    return TransformationList(l);
  end;

InstallMethod( IO_Pickle, "for a partial perm",
  [ IsFile, IsPartialPerm ],
  function( f, pp )
    local d;
    d := DomainOfPartialPerm(pp);
    if IO_Write(f,"PPER") = fail then return IO_Error; fi;
    if IO_Pickle(f,d) = IO_Error then
        return IO_Error;
    fi;
    if IO_Pickle(f,List(d, x -> x^pp)) = IO_Error then
        return IO_Error;
    fi;
    return IO_OK;
  end);

IO_Unpicklers.PPER :=
  function( f )
    local dom, im;
    dom := IO_Unpickle(f);
    if dom = IO_Error then return IO_Error; fi;
    im := IO_Unpickle(f);
    if im = IO_Error then return IO_Error; fi;
    return PartialPerm(dom, im);
  end;


InstallMethod( IO_Pickle, "for a float",
  [ IsFile, IsFloat ],
  function( f, fl )
    return IO_PickleByString( f, fl, "FLOT" );
  end );

IO_Unpicklers.FLOT := IO_UnpickleByFunction(Float);

InstallMethod( IO_Pickle, "for a character",
  [ IsFile, IsChar ],
  function(f, c)
    local s;
    s := "CHARx";
    s[5] := c;
    if IO_Write(f,s) = fail then return IO_Error; fi;
    return IO_OK;
  end );

IO_Unpicklers.CHAR :=
  function( f )
    local s;
    s := IO_ReadBlock(f,1);
    if s = fail or Length(s) < 1 then return IO_Error; fi;
    return s[1];
  end;

InstallMethod( IO_Pickle, "for a finite field element",
  [ IsFile, IsFFE ],
  function( f, ffe )
    local d,p;
    p := Characteristic(ffe);
    d := DegreeFFE(ffe);
    if IO_Write(f,"FFEC") = fail then return IO_Error; fi;
    if IO_Pickle(f,p) = IO_Error then return IO_Error; fi;
    if IO_Pickle(f,d) = IO_Error then return IO_Error; fi;
    return IO_Pickle(f,IntVecFFE(Coefficients(CanonicalBasis(GF(p,d)),ffe)));
  end );

IO_Unpicklers.FFEC :=
  function( f )
    local c,d,p,z;
    p := IO_Unpickle(f); if p = IO_Error then return IO_Error; fi;
    d := IO_Unpickle(f); if d = IO_Error then return IO_Error; fi;
    c := IO_Unpickle(f); if c = IO_Error then return IO_Error; fi;
    # requiring one coefficient per degree bounds the field by the file size
    if not (IsInt(p) and IsPosInt(d) and IsList(c) and Length(c) = d and
            IsPrimeInt(p) and ForAll(c,IsInt)) then
        return IO_Error;
    fi;
    z := Z(p,d);
    return ValuePol(c*(z^0),z);
  end;

IO_Unpicklers.FFEL := IO_UnpickleByParser(
    s -> IO_ParseLegacyExpression(s,IO_LegacyFFEMode) );

# Rationals need a method of their own: they are cyclotomics, so without one
# the coefficients written below would pickle themselves forever. Integers are
# unaffected, the IsInt method above is more specific still.
InstallMethod( IO_Pickle, "for a rational",
  [ IsFile, IsRat ],
  function( f, x )
    if IO_Write(f,"FRAC") = fail then return IO_Error; fi;
    if IO_Pickle(f,NumeratorRat(x)) = IO_Error then return IO_Error; fi;
    return IO_Pickle(f,DenominatorRat(x));
  end );

IO_Unpicklers.FRAC :=
  function( f )
    local d,n;
    n := IO_Unpickle(f); if n = IO_Error then return IO_Error; fi;
    d := IO_Unpickle(f); if d = IO_Error then return IO_Error; fi;
    if not (IsInt(n) and IsPosInt(d)) then return IO_Error; fi;
    return n/d;
  end;

InstallMethod( IO_Pickle, "for a cyclotomic",
  [ IsFile, IsCyclotomic ],
  function( f, cyc )
    local n;
    n := Conductor(cyc);
    if IO_Write(f,"CYCC") = fail then return IO_Error; fi;
    if IO_Pickle(f,n) = IO_Error then return IO_Error; fi;
    return IO_Pickle(f,CoeffsCyc(cyc,n));
  end );

IO_Unpicklers.CYCC :=
  function( f )
    local c,n;
    n := IO_Unpickle(f); if n = IO_Error then return IO_Error; fi;
    c := IO_Unpickle(f); if c = IO_Error then return IO_Error; fi;
    # one coefficient per root of unity bounds the conductor by the file size
    if not (IsPosInt(n) and IsList(c) and Length(c) = n and ForAll(c,IsRat))
       then return IO_Error; fi;
    return CycList(c);
  end;

IO_Unpicklers.CYCL := IO_UnpickleByParser(
    s -> IO_ParseLegacyExpression(s,IO_LegacyCycMode) );

InstallMethod( IO_Pickle, "for infinity",
  [ IsFile, IsInfinity ],
  function( f, x )
    if IO_Write(f,"PINF") = fail then return IO_Error; fi;
    return IO_OK;
  end );

IO_Unpicklers.PINF := infinity;

InstallMethod( IO_Pickle, "for negative infinity",
  [ IsFile, IsNegInfinity ],
  function( f, x )
    if IO_Write(f,"NINF") = fail then return IO_Error; fi;
    return IO_OK;
  end );

IO_Unpicklers.NINF := -infinity;

InstallMethod( IO_Pickle, "for a list",
  [ IsFile, IsList ],
  function( f, l )
    local count,i,nr,tag;
    nr := IO_AddToPickled(l);
    if nr = false then   # not yet known
        # Here we have to do something
        if IsMutable(l) then tag := "M"; else tag := "I"; fi;
        if IsGF2VectorRep(l) then Append(tag,"F2V");
        elif Is8BitVectorRep(l) then Append(tag,"F8V");
        elif IsGF2MatrixRep(l) then Append(tag,"F2M");
        elif Is8BitMatrixRep(l) then Append(tag,"F8M");
        else Append(tag,"LIS"); fi;
        if IO_Write(f,tag) = fail then
            IO_FinalizePickled();
            return IO_Error;
        fi;
        if IO_WriteSmallInt(f,Length(l)) = IO_Error then
            IO_FinalizePickled();
            return IO_Error;
        fi;
        count := 0;
        i := 1;
        while i <= Length(l) do
            if not(IsBound(l[i])) then
                count := count + 1;
            else
                if count > 0 then
                    if IO_Write(f,"GAPL") = fail then
                        IO_FinalizePickled();
                        return IO_Error;
                    fi;
                    if IO_WriteSmallInt(f,count) = IO_Error then
                        IO_FinalizePickled();
                        return IO_Error;
                    fi;
                    count := 0;
                fi;
                if IO_Pickle(f,l[i]) = IO_Error then
                    IO_FinalizePickled();
                    return IO_Error;
                fi;
            fi;
            i := i + 1;
        od;
        # Note that the last entry is always bound!
        IO_FinalizePickled();
        return IO_OK;
    else
        if IO_Write(f,"SREF") = IO_Error then
            IO_FinalizePickled();
            return IO_Error;
        fi;
        if IO_WriteSmallInt(f,nr) = IO_Error then
            IO_FinalizePickled();
            return IO_Error;
        fi;
        IO_FinalizePickled();
        return IO_OK;
    fi;
  end );

IO_Unpicklers.MLIS :=
  function( f )
    local i,j,l,len,ob;
    len := IO_ReadSmallInt(f);
    if len = IO_Error then return IO_Error; fi;
    l := 0*[1..len];
    IO_AddToUnpickled(l);
    i := 1;
    while i <= len do
        ob := IO_Unpickle(f);
        if ob = IO_Error then
            IO_FinalizeUnpickled();
            return IO_Error;
        fi;
        # IO_OK or IO_Nothing cannot happen!
        if IO_Result(ob) then
            if ob!.val = "Gap" then   # this is a Gap
                for j in [0..ob!.nr-1] do
                    Unbind(l[i+j]);
                od;
                i := i + ob!.nr;
            fi;
        else
            l[i] := ob;
            i := i + 1;
        fi;
    od;  # i is already incremented
    IO_FinalizeUnpickled();
    return l;
  end;

IO_Unpicklers.ILIS :=
  function( f )
    local l;
    l := IO_Unpicklers.MLIS(f); if l = IO_Error then return IO_Error; fi;
    MakeImmutable(l);
    return l;
  end;

IO_Unpicklers.MF2V :=
  function( f )
    local v;
    v := IO_Unpicklers.MLIS(f); if v = IO_Error then return IO_Error; fi;
    ConvertToVectorRep(v,2);
    return v;
  end;

IO_Unpicklers.MF8V :=
  function( f )
    local v;
    v := IO_Unpicklers.MLIS(f); if v = IO_Error then return IO_Error; fi;
    ConvertToVectorRep(v);
    return v;
  end;

IO_Unpicklers.IF2V :=
  function( f )
    local v;
    v := IO_Unpicklers.MLIS(f); if v = IO_Error then return IO_Error; fi;
    ConvertToVectorRep(v);
    MakeImmutable(v);
    return v;
  end;

IO_Unpicklers.IF8V :=
  function( f )
    local v;
    v := IO_Unpicklers.MLIS(f); if v = IO_Error then return IO_Error; fi;
    ConvertToVectorRep(v);
    MakeImmutable(v);
    return v;
  end;

IO_Unpicklers.MF2M :=
  function( f )
    local v;
    v := IO_Unpicklers.MLIS(f); if v = IO_Error then return IO_Error; fi;
    ConvertToMatrixRep(v,2);
    return v;
  end;

IO_Unpicklers.MF8M :=
  function( f )
    local v;
    v := IO_Unpicklers.MLIS(f); if v = IO_Error then return IO_Error; fi;
    ConvertToMatrixRep(v);
    return v;
  end;

IO_Unpicklers.IF2M :=
  function( f )
    local v;
    v := IO_Unpicklers.MLIS(f); if v = IO_Error then return IO_Error; fi;
    ConvertToMatrixRep(v);
    MakeImmutable(v);
    return v;
  end;

IO_Unpicklers.IF8M :=
  function( f )
    local v;
    v := IO_Unpicklers.MLIS(f); if v = IO_Error then return IO_Error; fi;
    ConvertToMatrixRep(v);
    MakeImmutable(v);
    return v;
  end;

IO_Unpicklers.GAPL :=
  function( f )
    local ob;
    ob := rec( val := "Gap", nr := IO_ReadSmallInt(f) );
    if ob.nr = IO_Error then
        return IO_Error;
    fi;
    return Objectify( NewType( IO_ResultsFamily, IO_Result ), ob );
  end;

IO_Unpicklers.SREF :=
  function( f )
    local nr;
    nr := IO_ReadSmallInt(f); if nr = IO_Error then return IO_Error; fi;
    if not(IsBound(IO_PICKLECACHE.obs[nr])) then
        Print("Found a self-reference to an unknown object!\n");
        return IO_Error;
    fi;
    return IO_PICKLECACHE.obs[nr];
  end;

InstallMethod( IO_Pickle, "for a range",
  [ IsFile, IsList and IsRangeRep ],
  function( f, rng )
    local tag;

    # Do not deal with empty or trivial ranges
    # (if they ever get the filters in question,
    # note that 'ConvertToRangeRep' does not set it).
    if Length( rng ) < 2 then
      TryNextMethod();
    fi;

    if IsMutable( rng ) then
      tag:= "MRNG";
    else
      tag:= "IRNG";
    fi;

    if IO_Write( f, tag ) = fail then
      return IO_Error;
    elif IO_WriteSmallInt( f, rng[1] ) = IO_Error then
      return IO_Error;
    elif IO_WriteSmallInt( f, rng[2] ) = IO_Error then
      return IO_Error;
    elif IO_WriteSmallInt( f, rng[ Length( rng ) ] ) = IO_Error then
      return IO_Error;
    fi;

    return IO_OK;
  end );

IO_Unpicklers.MRNG:= function( f )
    local first, second, last;

    first:= IO_ReadSmallInt( f );
    if first = IO_Error then
      return IO_Error;
    fi;
    second:= IO_ReadSmallInt( f );
    if second = IO_Error then
      return IO_Error;
    fi;
    last:= IO_ReadSmallInt( f );
    if last = IO_Error then
      return IO_Error;
    fi;

    return [ first, second .. last ];
  end;

IO_Unpicklers.IRNG:= function( f )
    local l;

    l:= IO_Unpicklers.MRNG( f );
    if l = IO_Error then
      return IO_Error;
    fi;
    MakeImmutable( l );

    return l;
  end;

InstallMethod( IO_Pickle, "for a record",
  [ IsFile, IsRecord ],
  function( f, r )
    local n,names,nr,tag;
    nr := IO_AddToPickled(r);
    if nr = false then   # not yet known
        # Here we have to do something
        if IsMutable(r) then tag := "MREC";
        else tag := "IREC"; fi;
        if IO_Write(f,tag) = fail then
            IO_FinalizePickled();
            return IO_Error;
        fi;
        names := RecNames(r);
        if IO_WriteSmallInt(f,Length(names)) = IO_Error then
            IO_FinalizePickled();
            return IO_Error;
        fi;
        for n in names do
            if IO_Pickle(f,n) = IO_Error then
                IO_FinalizePickled();
                return IO_Error;
            fi;
            if IO_Pickle(f,r.(n)) = IO_Error then
                IO_FinalizePickled();
                return IO_Error;
            fi;
        od;
        IO_FinalizePickled();
        return IO_OK;
    else
        if IO_Write(f,"SREF") = IO_Error then
            IO_FinalizePickled();
            return IO_Error;
        fi;
        if IO_WriteSmallInt(f,nr) = IO_Error then
            IO_FinalizePickled();
            return IO_Error;
        fi;
        IO_FinalizePickled();
        return IO_OK;
    fi;
  end );

IO_Unpicklers.MREC :=
  function( f )
    local i,len,name,ob,r;
    len := IO_ReadSmallInt(f);
    if len = IO_Error then return IO_Error; fi;
    r := rec();
    IO_AddToUnpickled(r);
    for i in [1..len] do
        name := IO_Unpickle(f);
        if name = IO_Error or not(IsString(name)) then
            IO_FinalizeUnpickled();
            return IO_Error;
        fi;
        ob := IO_Unpickle(f);
        if IO_Result(ob) then
            if ob = IO_Error then
                IO_FinalizeUnpickled();
                return IO_Error;
            fi;
        else
            r.(name) := ob;
        fi;
    od;
    IO_FinalizeUnpickled();
    return r;
  end;

IO_Unpicklers.IREC :=
  function( f )
    local r;
    r := IO_Unpicklers.MREC(f); if r = IO_Error then return IO_Error; fi;
    MakeImmutable(r);
    return r;
  end;

InstallMethod( IO_Pickle, "IO_Results are forbidden",
  [ IsFile, IO_Result ],
  function( f, ob )
    Print("Pickling of IO_Result is forbidden!\n");
    return IO_Error;
  end );

InstallMethod( IO_Pickle, "for rational functions",
  [ IsFile, IsPolynomialFunction and IsRationalFunctionDefaultRep ],
  function( f, pol )
    local num,den,one;
    one := One(CoefficientsFamily(FamilyObj(pol)));
    num := ExtRepNumeratorRatFun(pol);
    den := ExtRepDenominatorRatFun(pol);
    if IO_Write(f,"RATF") = fail then return IO_Error; fi;
    if IO_Pickle(f,one) = IO_Error then return IO_Error; fi;
    if IO_Pickle(f,num) = IO_Error then return IO_Error; fi;
    if IO_Pickle(f,den) = IO_Error then return IO_Error; fi;
    return IO_OK;
  end );

IO_Unpicklers.RATF :=
  function( f )
    local num,den,one,poly;
    one := IO_Unpickle(f);
    if one = IO_Error then return IO_Error; fi;
    num := IO_Unpickle(f);
    if num = IO_Error then return IO_Error; fi;
    den := IO_Unpickle(f);
    if den = IO_Error then return IO_Error; fi;
    poly := RationalFunctionByExtRepNC(
                   RationalFunctionsFamily(FamilyObj(one)),num,den);
    return poly;
  end;

InstallMethod( IO_Pickle, "for rational functions",
  [ IsFile, IsPolynomialFunction and IsPolynomialDefaultRep ],
  function( f, pol )
    local num,one;
    one := One(CoefficientsFamily(FamilyObj(pol)));
    num := ExtRepNumeratorRatFun(pol);
    if IO_Write(f,"POLF") = fail then return IO_Error; fi;
    if IO_Pickle(f,one) = IO_Error then return IO_Error; fi;
    if IO_Pickle(f,num) = IO_Error then return IO_Error; fi;
    return IO_OK;
  end );

IO_Unpicklers.POLF :=
  function( f )
    local num,one,poly;
    one := IO_Unpickle(f);
    if one = IO_Error then return IO_Error; fi;
    num := IO_Unpickle(f);
    if num = IO_Error then return IO_Error; fi;
    poly := PolynomialByExtRepNC(
                   RationalFunctionsFamily(FamilyObj(one)),num);
    return poly;
  end;

# This is for compatibility only and will go eventually:
IO_Unpicklers.POLY :=
  function( f )
    local ext,one,poly;
    one := IO_Unpickle(f);
    if one = IO_Error then return IO_Error; fi;
    ext := IO_Unpickle(f);
    if ext = IO_Error then return IO_Error; fi;
    poly := PolynomialByExtRepNC( RationalFunctionsFamily(FamilyObj(one)),ext);
    IsUnivariatePolynomial(poly);   # to make it learn
    IsLaurentPolynomial(poly);      # to make it learn
    return poly;
  end;

InstallMethod( IO_Pickle, "for a univariate Laurent polynomial",
  [ IsFile, IsLaurentPolynomial and IsLaurentPolynomialDefaultRep ],
  function( f, pol )
  local cofs,one,ind;
    one := One(CoefficientsFamily(FamilyObj(pol)));
    cofs := CoefficientsOfLaurentPolynomial(pol);
    ind := IndeterminateNumberOfLaurentPolynomial(pol);
    if IO_Write(f,"UPOL") = fail then return IO_Error; fi;
    if IO_Pickle(f,one) = IO_Error then return IO_Error; fi;
    if IO_Pickle(f,cofs) = IO_Error then return IO_Error; fi;
    if IO_Pickle(f,ind) = IO_Error then return IO_Error; fi;
    return IO_OK;
  end );

IO_Unpicklers.UPOL :=
  function( f )
    local cofs,one,ind,poly;
    one := IO_Unpickle(f);
    if one = IO_Error then return IO_Error; fi;
    cofs := IO_Unpickle(f);
    if cofs = IO_Error then return IO_Error; fi;
    ind := IO_Unpickle(f);
    if ind = IO_Error then return IO_Error; fi;
    poly := LaurentPolynomialByCoefficients(FamilyObj(one),cofs[1],cofs[2],ind);
    return poly;
  end;

InstallMethod( IO_Pickle, "for a univariate rational function",
  [ IsFile,
    IsUnivariateRationalFunction and IsUnivariateRationalFunctionDefaultRep ],
  function( f, pol )
    local cofs,one,ind;
    one := One(CoefficientsFamily(FamilyObj(pol)));
    cofs := CoefficientsOfUnivariateRationalFunction(pol);
    ind := IndeterminateNumberOfUnivariateRationalFunction(pol);
    if IO_Write(f,"URFU") = fail then return IO_Error; fi;
    if IO_Pickle(f,one) = IO_Error then return IO_Error; fi;
    if IO_Pickle(f,cofs) = IO_Error then return IO_Error; fi;
    if IO_Pickle(f,ind) = IO_Error then return IO_Error; fi;
    return IO_OK;
  end );

IO_Unpicklers.URFU :=
  function( f )
    local cofs,one,ind,poly;
    one := IO_Unpickle(f);
    if one = IO_Error then return IO_Error; fi;
    cofs := IO_Unpickle(f);
    if cofs = IO_Error then return IO_Error; fi;
    ind := IO_Unpickle(f);
    if ind = IO_Error then return IO_Error; fi;
    poly := UnivariateRationalFunctionByCoefficients(
               FamilyObj(one),cofs[1],cofs[2],cofs[3],ind);
    return poly;
  end;

InstallMethod( IO_Pickle, "for a straight line program",
  [ IsFile, IsStraightLineProgram ],
  function( f, s )
    if IO_Write(f,"GSLP") = fail then return IO_Error; fi;
    if IO_Pickle(f,LinesOfStraightLineProgram(s)) = IO_Error then
        return IO_Error;
    fi;
    if IO_Pickle(f,NrInputsOfStraightLineProgram(s)) = IO_Error then
        return IO_Error;
    fi;
    return IO_OK;
  end);

IO_Unpicklers.GSLP :=
  function( f )
    local l,n,s;
    l := IO_Unpickle(f);
    if l = IO_Error then return IO_Error; fi;
    n := IO_Unpickle(f);
    if l = IO_Error then return IO_Error; fi;
    s := StraightLineProgramNC(l,n);
    return s;
  end;

InstallMethod( IO_Pickle, "for the global random source",
  [ IsFile, IsRandomSource and IsGlobalRandomSource ],
  function( f, r )
    local s;
    if IO_Write(f,"RSGL") = fail then return IO_Error; fi;
    s := State(r);
    if IO_Pickle(f,s) = IO_Error then return IO_Error; fi;
    return IO_OK;
  end );

IO_Unpicklers.RSGL :=
  function( f )
    local s;
    s := IO_Unpickle(f);
    if s = IO_Error then return IO_Error; fi;
    return RandomSource(IsGlobalRandomSource,s);
  end;

InstallMethod( IO_Pickle, "for a GAP random source",
  [ IsFile, IsRandomSource and IsGAPRandomSource ],
  function( f, r )
    local s;
    if IO_Write(f,"RSGA") = fail then return IO_Error; fi;
    s := State(r);
    if IO_Pickle(f,s) = IO_Error then return IO_Error; fi;
    return IO_OK;
  end );

IO_Unpicklers.RSGA :=
  function( f )
    local s;
    s := IO_Unpickle(f);
    if s = IO_Error then return IO_Error; fi;
    return RandomSource(IsGAPRandomSource,s);
  end;

InstallMethod( IO_Pickle, "for a Mersenne twister random source",
  [ IsFile, IsRandomSource and IsMersenneTwister ],
  function( f, r )
    local s;
    if IO_Write(f,"RSMT") = fail then return IO_Error; fi;
    s := State(r);
    if IO_Pickle(f,s) = IO_Error then return IO_Error; fi;
    return IO_OK;
  end );

IO_Unpicklers.RSMT :=
  function( f )
    local s;
    s := IO_Unpickle(f);
    if s = IO_Error then return IO_Error; fi;
    return RandomSource(IsMersenneTwister,s);
  end;

InstallMethod( IO_Pickle, "for an operation",
  [ IsFile, IsOperation and IsFunction ],
  function(f,o)
    if IO_Write(f,"OPER") = fail then return IO_Error; fi;
    if IO_Pickle(f,NAME_FUNC(o)) = IO_Error then return IO_Error; fi;
    return IO_OK;
  end );

IO_FuncToUnpickle := fail;
IO_Unpicklers.OPER :=
  function( f )
    local s;
    s := IO_Unpickle(f); if s = IO_Error then return IO_Error; fi;
    if not (IsString(s) and IsBoundGlobal(s)) then return IO_Error; fi;
    s := ValueGlobal(s);
    if not IsOperation(s) then return IO_Error; fi;
    return s;
  end;

InstallMethod( IO_Pickle, "for a function",
  [ IsFile, IsFunction ],
  function( f, fu )
    local o,s;
    s := NAME_FUNC(fu);
    if not(IsBoundGlobal(s)) or not(IsIdenticalObj(ValueGlobal(s),fu)) then
        s := "";
        o := OutputTextString(s,true);
        PrintTo(o,fu);
        CloseStream(o);
        if PositionSublist(s,"<<compiled code>>") <> fail then
            Print("#Error: Cannot pickle compiled function.\n");
            return IO_Error;
        fi;
    fi;
    if IO_Write(f,"FUNC") = fail then return IO_Error; fi;
    if IO_Pickle(f,s) = IO_Error then return IO_Error; fi;
    return IO_OK;
  end );

IO_Unpicklers.FUNC :=
  function( f )
    local i,s;
    s := IO_Unpickle(f); if s = IO_Error then return IO_Error; fi;
    if not IsString(s) then return IO_Error; fi;
    # the pickler writes a global's name where it can, and the function's
    # source otherwise; only the latter needs evaluating
    if IsBoundGlobal(s) then
        s := ValueGlobal(s);
        if not IsFunction(s) then return IO_Error; fi;
        return s;
    fi;
    if not IO_UnpickleAllowEvalOfFunctions then
        Info(InfoWarning, 1, "IO_Unpickle: refusing to evaluate the source of ",
             "a pickled function; set IO_UnpickleAllowEvalOfFunctions := true ",
             "if you trust this data");
        return IO_Error;
    fi;
    s := Concatenation( "IO_FuncToUnpickle := ",s,";" );
    i := InputTextString(s);
    Read(i);
    if not(IsBound(IO_FuncToUnpickle)) then return IO_Error; fi;
    s := IO_FuncToUnpickle;
    Unbind(IO_FuncToUnpickle);
    return s;
  end;
Unbind(IO_FuncToUnpickle);

InstallMethod( IO_Pickle, "for a weak pointer object",
  [ IsFile, IsWeakPointerObject and IsList ],
  function( f, l )
    local count,i,nr;
    nr := IO_AddToPickled(l);
    if nr = false then   # not yet known
        # Here we have to do something
        if IO_Write(f,"WPOB") = fail then
            IO_FinalizePickled();
            return IO_Error;
        fi;
        if IO_WriteSmallInt(f,Length(l)) = IO_Error then
            IO_FinalizePickled();
            return IO_Error;
        fi;
        count := 0;
        i := 1;
        while i <= Length(l) do
            if not(IsBound(l[i])) then
                count := count + 1;
            else
                if count > 0 then
                    if IO_Write(f,"GAPL") = fail then
                        IO_FinalizePickled();
                        return IO_Error;
                    fi;
                    if IO_WriteSmallInt(f,count) = IO_Error then
                        IO_FinalizePickled();
                        return IO_Error;
                    fi;
                    count := 0;
                fi;
                if IO_Pickle(f,l[i]) = IO_Error then
                    IO_FinalizePickled();
                    return IO_Error;
                fi;
            fi;
            i := i + 1;
        od;
        # Note that the last entry is always bound!
        IO_FinalizePickled();
        return IO_OK;
    else
        if IO_Write(f,"SREF") = IO_Error then
            IO_FinalizePickled();
            return IO_Error;
        fi;
        if IO_WriteSmallInt(f,nr) = IO_Error then
            IO_FinalizePickled();
            return IO_Error;
        fi;
        IO_FinalizePickled();
        return IO_OK;
    fi;
  end );

IO_Unpicklers.WPOB :=
  function( f )
    local i,l,len,ob;
    len := IO_ReadSmallInt(f);
    if len = IO_Error then return IO_Error; fi;
    l := WeakPointerObj( [] );
    if len > 0 then
        SetElmWPObj(l,len,0);
    fi;
    IO_AddToUnpickled(l);
    i := 1;
    while i <= len do
        ob := IO_Unpickle(f);
        if ob = IO_Error then
            IO_FinalizeUnpickled();
            return IO_Error;
        fi;
        # IO_OK or IO_Nothing cannot happen!
        if IO_Result(ob) then
            if ob!.val = "Gap" then   # this is a Gap
                i := i + ob!.nr;
            fi;
        else
            SetElmWPObj(l,i,ob);
            i := i + 1;
        fi;
    od;  # i is already incremented
    IO_FinalizeUnpickled();
    return l;
  end;

InstallMethod( IO_Pickle, "for a permutation group",
  [ IsFile, IsPermGroup ],
  function( f, g )
    if IO_Write(f,"PRMG") = fail then return IO_Error; fi;
    if IO_Pickle(f,GeneratorsOfGroup(g)) = IO_Error then return IO_Error; fi;
    if HasSize(g) then
        if IO_Pickle(f,Size(g)) = IO_Error then return IO_Error; fi;
    else
        if IO_Pickle(f,fail) = IO_Error then return IO_Error; fi;
    fi;
    if HasStabChainImmutable(g) then
        if IO_Pickle(f,BaseStabChain(StabChainImmutable(g))) = IO_Error then
            return IO_Error;
        fi;
    elif HasStabChainMutable(g) then
        if IO_Pickle(f,BaseStabChain(StabChainMutable(g))) = IO_Error then
            return IO_Error;
        fi;
    else
        if IO_Pickle(f,fail) = IO_Error then return IO_Error; fi;
    fi;
    return IO_OK;
  end );

IO_Unpicklers.PRMG :=
  function(f)
    local base,g,gens,size;
    gens := IO_Unpickle(f); if gens = IO_Error then return IO_Error; fi;
    g := GroupWithGenerators(gens, ());
    size := IO_Unpickle(f); if size = IO_Error then return IO_Error; fi;
    if size <> fail then SetSize(g,size); fi;
    base := IO_Unpickle(f); if base = IO_Error then return IO_Error; fi;
    if base <> fail then
        StabChain(g,rec(knownBase := base));
    fi;
    return g;
  end;

InstallMethod( IO_Pickle, "for a matrix group",
  [ IsFile, IsMatrixGroup ],
  function( f, g )
    return IO_GenericObjectPickler(f,"MATG",[GeneratorsOfGroup(g)],g,
               [Name,Size,DimensionOfMatrixGroup,FieldOfMatrixGroup],[],[]);
  end );

IO_Unpicklers.MATG :=
  function(f)
    local g,gens;
    gens := IO_Unpickle(f); if gens = IO_Error then return IO_Error; fi;
    g := GroupWithGenerators(gens);
    return
    IO_GenericObjectUnpickler(f,g,
                 [Name,Size,DimensionOfMatrixGroup,FieldOfMatrixGroup],[]);
    return g;
  end;

InstallMethod( IO_Pickle, "for a finite field",
  [ IsFile, IsField and IsFinite ],
  function(f,F)
    return IO_GenericObjectPickler(f,"FFIE",
              [Characteristic(F),DegreeOverPrimeField(F)],F,[],[],[]);
  end );

IO_Unpicklers.FFIE :=
  function(f)
    local d,p;
    p := IO_Unpickle(f); if p = IO_Error then return IO_Error; fi;
    d := IO_Unpickle(f); if d = IO_Error then return IO_Error; fi;
    if IO_Unpickle(f) <> fail then return IO_Error; fi;
    return GF(p,d);
  end;

InstallMethod( IO_Pickle, "for a character table",
    [ IsFile, IsCharacterTable ],
    function( f, tbl )
    local irr, ccl, cclg, g;

    if HasIrr( tbl ) then
      irr:= List( Irr( tbl ), ValuesOfClassFunction );
    else
      irr:= fail;
    fi;

    ccl:= fail;
    cclg:= fail;
    if HasConjugacyClasses( tbl ) then
      ccl:= List( ConjugacyClasses( tbl ), Representative );
    fi;
    if HasUnderlyingGroup( tbl ) then
      g:= UnderlyingGroup( tbl );
      if HasConjugacyClasses( g ) then
        cclg:= List( ConjugacyClasses( g ), Representative );
      fi;
    fi;

    return IO_GenericObjectPickler( f, "CTBL",
               [ irr, UnderlyingCharacteristic( tbl ), ccl, cclg ], tbl,
               [ AutomorphismsOfTable, CharacterDegrees, CharacterNames,
                 CharacterParameters, ClassNames, ClassParameters,
                 ClassPermutation, ComputedClassFusions, ComputedPowerMaps,
                 FactorsOfDirectProduct, IdentificationOfConjugacyClasses,
                 Identifier, InfoText, NamesOfFusionSources,
                 OrdersClassRepresentatives, OrdinaryCharacterTable,
                 SizesCentralizers, SizesConjugacyClasses,
                 SourceOfIsoclinicTable, UnderlyingGroup ],
               [ IsLibraryCharacterTableRep ],
               [] );
    end );

IO_Unpicklers.CTBL:= function( f )
    local irr, p, ccl, cclg, tbl, g;

    irr:= IO_Unpickle( f );
    if irr = IO_Error then
      return IO_Error;
    fi;
    p:= IO_Unpickle( f );
    if p = IO_Error then
      return IO_Error;
    fi;
    ccl:= IO_Unpickle( f );
    if ccl = IO_Error then
      return IO_Error;
    fi;
    cclg:= IO_Unpickle( f );
    if cclg = IO_Error then
      return IO_Error;
    fi;
    tbl:= rec( UnderlyingCharacteristic:= p );
    ConvertToLibraryCharacterTableNC( tbl );

    IO_GenericObjectUnpickler( f, tbl,
         [ AutomorphismsOfTable, CharacterDegrees, CharacterNames,
           CharacterParameters, ClassNames, ClassParameters,
           ClassPermutation, ComputedClassFusions, ComputedPowerMaps,
           FactorsOfDirectProduct, IdentificationOfConjugacyClasses,
           Identifier, InfoText, NamesOfFusionSources,
           OrdersClassRepresentatives, OrdinaryCharacterTable,
           SizesCentralizers, SizesConjugacyClasses,
           SourceOfIsoclinicTable, UnderlyingGroup ],
         [ IsLibraryCharacterTableRep ] );

    if HasUnderlyingGroup( tbl ) then
      g:= UnderlyingGroup( tbl );
      if ccl <> fail then
        SetConjugacyClasses( tbl, List( ccl, x -> ConjugacyClass( g, x ) ) );
      fi;
      if cclg <> fail then
        SetConjugacyClasses( g, List( cclg, x -> ConjugacyClass( g, x ) ) );
      fi;
    fi;

    # Do not set this earlier,
    # because it may trigger the computation of conjugacy classes.
    if irr <> fail then
      SetIrr( tbl, List( irr, x -> Character( tbl, x ) ) );
    fi;

    return tbl;
  end;

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
