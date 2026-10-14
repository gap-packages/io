gap> START_TEST("pickle.tst");
gap> LoadPackage("IO", false);;
gap> old := InfoLevel(InfoWarning);;
gap> SetInfoLevel(InfoWarning, 0);

#
# Not covered: the "if IO_Write(...) = fail then return IO_Error" checks that
# carry a write error out of a pickler. Provoking one needs a real I/O
# failure; writing to a closed file raises an error instead of returning fail.
#

#
# The parsers for the deprecated PERM, FFEL and CYCL formats stand in for an
# EvalString, so every input they reject matters: whatever they accept they
# also evaluate. Exercise them directly, one rejection at a time. Rejections
# are collected with Filtered so that a regression names the input it let
# through.
#

# permutations in cycle notation
gap> List([ "()", "(1,2)", "(1,2,3)(5,7)", "(5)", "(1,2)(3,4)",
>           "(2,3)(4,10000)" ], IO_ParsePermString);
[ (), (1,2), (1,2,3)(5,7), (), (1,2)(3,4), (2,3)(4,10000) ]

# every way of not being a permutation
gap> Filtered([ ""            # empty
>             , "1,2"         # does not open a cycle
>             , "x"
>             , ")"
>             , "("           # unterminated
>             , "(1,2"
>             , "()x"         # trailing junk
>             , "(1,2))"
>             , "(1 2)"       # missing separator
>             , "(1;2)"
>             , "(,)"         # missing point
>             , "(1,)"
>             , "(a)"
>             , "(0)"         # not a point
>             , "(268435456)" # beyond MAX_DEG_PERM4
>             , "(1,1)"       # point used twice
>             , "(1,2)(2,3)"
>             ], s -> IO_ParsePermString(s) <> fail);
[  ]

# field elements, and cyclotomics, parse in disjoint modes
gap> ffe := s -> IO_ParseLegacyExpression(s, IO_LegacyFFEMode);;
gap> cyc := s -> IO_ParseLegacyExpression(s, IO_LegacyCycMode);;

# everything String() produces for a field element
gap> List([ "Z(2)", "0*Z(2)", "Z(2)^0", "Z(5)^2", "Z(2^2)", "Z(3^2)^5",
>           "ZmodpZObj(27,65537)" ], ffe);
[ Z(2)^0, 0*Z(2), Z(2)^0, Z(5)^2, Z(2^2), Z(3^2)^5, ZmodpZObj( 27, 65537 ) ]
gap> ffe("Z(2)^0+Z(2,20)^3") = Z(2)^0+Z(2,20)^3;
true
gap> ffe("Z(65537^2)^5") = Z(65537^2)^5;
true

# ... and every rejection
gap> Filtered([ ""                  # nothing to parse
>             , "Z(2)^"
>             , "Z(2)*"
>             , "Z(2)+"
>             , "E(3)"              # not callable in this mode
>             , "Exec(\"x\")"
>             , "Q(2)"
>             , "Z"                 # not a call
>             , "Zx"
>             , "Z("                # unterminated call
>             , "Z(2"
>             , "Z(2;3)"            # bad separator
>             , "(Z(2)"             # unbalanced
>             , "(Z(2)*)"           # failing subexpression
>             , "Z(2))"             # trailing junk
>             , "Z(2) Z(2)"
>             , "Z()"               # wrong number of arguments
>             , "Z(2,3,4)"
>             , "Z(6)"              # not a prime power
>             , "Z(2,0)"            # degree out of range
>             , "Z(2,70000)"
>             , "Z(281474976710657)"       # field size out of range
>             , "ZmodpZObj(1,6)"    # modulus not prime
>             , "ZmodnZObj(1,0)"
>             , "ZmodnZObj(3,6)"    # not a field element
>             , "Z(4)^Z(2)"         # exponent not an integer
>             , "Z(2)+Z(3)"         # mixed characteristic
>             , "Z(2)/Z(2)"         # division is not part of the format
>             , "5"                 # not a field element
>             , "E(3)+Z(2)"         # mixed domains
>             ], s -> ffe(s) <> fail);
[  ]

# cyclotomics, including the rationals that appear as coefficients
gap> List([ "E(3)", "E(4)", "E(1)", "3", "-5", "7/3", "-22/7", "0" ], cyc);
[ E(3), E(4), 1, 3, -5, 7/3, -22/7, 0 ]
gap> cyc("3/7*E(15)-5*E(15)^2+11/13") = 3/7*E(15)-5*E(15)^2+11/13;
true
gap> Filtered([ ""
>             , "E(3)+"
>             , "E("
>             , "E(3"
>             , "E"
>             , "E(3))"             # trailing junk
>             , "(E(3)+)"           # failing subexpression
>             , "1 2"
>             , "Z(2)"              # not callable in this mode
>             , "Exec(\"x\")"
>             , "E()"               # wrong number of arguments
>             , "E(1,2)"
>             , "E(0)"              # conductor out of range
>             , "E(16777217)"
>             , "E(-1)"             # argument not a non-negative integer
>             , "E(E(3))"
>             , "1/0"               # division by zero
>             , "E(3)/0"
>             , "0^-1"              # zero to a negative power
>             , "2^(2^64)"          # a rational raised to an absurd power
>             ], s -> cyc(s) <> fail);
[  ]

#
# The same inputs through IO_Unpickle, so the wiring is covered too, and to
# show that a hostile pickle is refused rather than executed.
#

# write <tag> followed by a raw payload, then read it back
gap> raw := function(tag, str)
>      local s, f, res;
>      s := ""; f := IO_WrapFD(-1, false, s);
>      IO_Write(f, tag); IO_WriteSmallInt(f, Length(str)); IO_Write(f, str);
>      IO_Close(f);
>      f := IO_WrapFD(-1, s, false); res := IO_Unpickle(f); IO_Close(f);
>      return res;
>    end;;

# write <tag> followed by pickles of <data>, then read it back
gap> craft := function(tag, data)
>      local s, f, res, x;
>      s := ""; f := IO_WrapFD(-1, false, s);
>      IO_Write(f, tag);
>      for x in data do IO_Pickle(f, x); od;
>      IO_Close(f);
>      f := IO_WrapFD(-1, s, false); res := IO_Unpickle(f); IO_Close(f);
>      return res;
>    end;;
gap> IO_TestWasPwned := false;;
gap> Filtered([ [ "PERM", "IO_TestWasPwned := true;" ]
>             , [ "FFEL", "IO_TestWasPwned := true" ]
>             , [ "CYCL", "IO_TestWasPwned := true" ]
>             , [ "CYCL", "Exec(\"touch /tmp/io-pickle-pwned\")" ]
>             , [ "FFEL", "SetInfoLevel(InfoWarning,0)" ]
>             , [ "CYCL", "E(2^64)" ]
>             , [ "CYCL", "2^(2^64)" ]
>             , [ "PERM", "((((" ]
>             ], p -> raw(p[1], p[2]) <> IO_Error);
[  ]
gap> IO_TestWasPwned;
false

# a legacy pickle still round trips
gap> legacy := function(ob, tag)
>      local s, f, res;
>      s := ""; f := IO_WrapFD(-1, false, s);
>      IO_PickleByString(f, ob, tag);
>      IO_Close(f);
>      f := IO_WrapFD(-1, s, false); res := IO_Unpickle(f); IO_Close(f);
>      return res;
>    end;;
gap> ForAll([ (), (1,2,3)(5,7), Random(SymmetricGroup(500)) ],
>           p -> legacy(p, "PERM") = p);
true
gap> ForAll([ Z(2), 0*Z(2), Z(5)^2, Z(4), Z(9)^5, Z(65537)^3, Z(65537^2)^5,
>             Z(2,20)^123, Z(3,20)^7, Z(2,100)^3+Z(2,100)^5, Z(65537,2)^7 ],
>           x -> legacy(x, "FFEL") = x);
true
gap> ForAll([ E(3), E(4), -5, 7/3, -22/7, 3/7*E(15)-5*E(15)^2+11/13 ],
>           x -> legacy(x, "CYCL") = x);
true

#
# The formats written today, and what their unpicklers reject. Each stores a
# length or a degree that the payload has to match, which is what stops a
# short pickle from asking for an enormous object.
#
gap> l := [ (1,2,3)(5,7), (), Z(4), 0*Z(2), Z(2,100)^3+Z(2,100)^5, Z(65537)^3,
>           7/3, -22/7, E(3), 3/7*E(15)-5*E(15)^2+11/13, 2^100, infinity,
>           -infinity ];;
gap> IO_Unpickle(IO_Pickle(l)) = l;
true
gap> IO_Unpickle(IO_Pickle(l)) = l;   # the pickle cache is left clean
true
gap> Filtered([ [ "PRML", [ 1 ] ]                 # not a list
>             , [ "PRML", [ [ 1, 1 ] ] ]          # not a permutation
>             , [ "FFEC", [ 4, 1, [ 0 ] ] ]       # characteristic not prime
>             , [ "FFEC", [ 2, 0, [  ] ] ]        # degree not positive
>             , [ "FFEC", [ 2, 2, [ 1 ] ] ]       # one coefficient per degree
>             , [ "FFEC", [ 2, 1, [ 1, 1 ] ] ]
>             , [ "FFEC", [ 2, 1, 1 ] ]           # coefficients not a list
>             , [ "FFEC", [ 2, 1, [ 1/2 ] ] ]     # coefficient not an integer
>             , [ "CYCC", [ 0, [  ] ] ]           # conductor not positive
>             , [ "CYCC", [ 3, [ 1, 0 ] ] ]       # one coefficient per root
>             , [ "CYCC", [ 3, 1 ] ]              # coefficients not a list
>             , [ "CYCC", [ 1, [ E(3) ] ] ]       # coefficient not rational
>             , [ "FRAC", [ 1, 0 ] ]              # zero denominator
>             , [ "FRAC", [ 1, -1 ] ]
>             , [ "FRAC", [ 1/2, 1 ] ]            # numerator not an integer
>             ], p -> craft(p[1], p[2]) <> IO_Error);
[  ]

#
# Functions and operations are stored by name where they are globals, which
# needs no evaluation. Source does, and is refused by default.
#
gap> ForAll([ Size, IsPrimeInt, PrintObj, \+, \*, \=, \[\], \in ],
>           f -> IO_Unpickle(IO_Pickle(f)) = f);
true
gap> pickled_func := IO_Pickle(function(x) return x+1; end);;
gap> IO_Unpickle(pickled_func);
IO_Error
gap> IO_UnpickleAllowEvalOfFunctions := true;;
gap> IO_Unpickle(pickled_func)(1);
2
gap> IO_UnpickleAllowEvalOfFunctions := false;;
gap> Filtered([ [ "OPER", [ "no_such_global_variable" ] ]  # not bound
>             , [ "OPER", [ "IsPrimeInt" ] ]               # not an operation
>             , [ "OPER", [ 1 ] ]                          # not a name
>             , [ "FUNC", [ 1 ] ]
>             ], p -> craft(p[1], p[2]) <> IO_Error);
[  ]

#
# Free and finitely presented groups. An element is only usable next to the
# group it came from, so what matters is that objects pickled together still
# fit together afterwards.
#
gap> f := FreeGroup("a", "b");;
gap> u := IO_Unpickle(IO_Pickle(f));;
gap> IsFreeGroup(u); List(GeneratorsOfGroup(u), String);
true
[ "a", "b" ]
gap> w := IO_Unpickle(IO_Pickle([ f.1^3*f.2^-2, f.2*f.1 ]));;
gap> List(w, String);
[ "a^3*b^-2", "b*a" ]
gap> IsIdenticalObj(FamilyObj(w[1]), FamilyObj(w[2]));
true
gap> String(w[1]*w[2]) = String(f.1^3*f.2^-2*f.2*f.1);
true

# one copy of the free group per stream, not one per word
gap> s := IO_Pickle(GeneratorsOfGroup(f));;
gap> PositionSublist(s, "FREG", PositionSublist(s, "FREG"));
fail
gap> g := f / [ f.1^2, f.2^3, (f.1*f.2)^5 ];;
gap> u := IO_Unpickle(IO_Pickle(g));;
gap> Size(u);
60
gap> List(RelatorsOfFpGroup(u), String) = List(RelatorsOfFpGroup(g), String);
true
gap> e := IO_Unpickle(IO_Pickle([ g.1*g.2, g.2^-1 ]));;
gap> IsIdenticalObj(FamilyObj(e[1]), FamilyObj(e[2]));
true
gap> Order(e[1]*e[2]) = Order(g.1);
true
gap> h := Subgroup(g, [ g.1 ]);;
gap> u := IO_Unpickle(IO_Pickle(h));;
gap> Index(Parent(u), u) = Index(g, h);
true
gap> Length(GeneratorsOfGroup(IO_Unpickle(IO_Pickle(
>        Subgroup(f, [ f.1^2, f.2 ])))));
2

# an element only pickles next to its group, and the helpers that look that
# group up say so rather than erroring when there is none
gap> IO_WholeGroupOfElement((1,2));
fail
gap> IO_FreeGroupUnderlying(SymmetricGroup(3));
fail

# a free group of infinite rank has no finite list of names to store
gap> IO_Pickle(FreeGroup(infinity, "x"));
IO_Error

# malformed presentations and words
gap> Filtered([ [ "FREG", [ 2 ] ]                    # names not a list
>             , [ "FREG", [ [ 1 ] ] ]                # names not strings
>             , [ "FPGR", [ 2, [  ] ] ]              # not a free group
>             , [ "FPGR", [ f, [ [ 1 ] ] ] ]         # ext rep of odd length
>             , [ "FPGR", [ f, [ [ 3, 1 ] ] ] ]      # no such generator
>             , [ "FPGR", [ f, [ [ 1, 0 ] ] ] ]      # zero exponent
>             , [ "FPGR", [ f, [ [ 1, 1/2 ] ] ] ]    # exponent not an integer
>             , [ "FPGR", [ f, 1 ] ]                 # relators not a list
>             , [ "FREW", [ 2, [ 1, 1 ] ] ]          # not a free group
>             , [ "FREW", [ f, [ 3, 1 ] ] ]          # no such generator
>             , [ "FPEL", [ 2, [ 1, 1 ] ] ]          # not an fp group
>             , [ "FPEL", [ g, [ 3, 1 ] ] ]          # no such generator
>             , [ "FPSG", [ 2, [  ] ] ]              # not an fp group
>             , [ "FPSG", [ g, [ [ 3, 1 ] ] ] ]      # no such generator
>             ], p -> craft(p[1], p[2]) <> IO_Error);
[  ]

#
# Truncated and unknown input
#
gap> trunc := function(tag, len, str)
>      local s, f, res;
>      s := ""; f := IO_WrapFD(-1, false, s);
>      IO_Write(f, tag); IO_WriteSmallInt(f, len); IO_Write(f, str);
>      IO_Close(f);
>      f := IO_WrapFD(-1, s, false); res := IO_Unpickle(f); IO_Close(f);
>      return res;
>    end;;
gap> Filtered([ [ "PERM", 10, "(1,2)" ]     # fewer bytes than promised
>             , [ "FFEL", 10, "Z(2)" ]
>             , [ "CYCL", 10, "E(3)" ]
>             , [ "FLOT", 10, "1.5" ]
>             , [ "MSTR", 10, "abc" ]
>             ], p -> trunc(p[1], p[2], p[3]) <> IO_Error);
[  ]
gap> IO_Unpickle("NOPE");
IO_Error
gap> IO_Unpickle("");
IO_Nothing

# the length field itself can be missing
gap> Filtered([ "PERM", "FFEL", "CYCL", "MSTR", "INTG" ],
>          x -> IO_Unpickle(x) <> IO_Error);
[  ]

# an error in a nested object has to propagate out of every unpickler that
# reads one; "NOPE" stands in for any object that fails to unpickle
gap> Filtered([ "FREGNOPE", "FPGRNOPE", "FPSGNOPE", "FREWNOPE", "FPELNOPE"
>             , Concatenation("FPGR", IO_Pickle(f), "NOPE")
>             , Concatenation("FPSG", IO_Pickle(g), "NOPE")
>             , Concatenation("FREW", IO_Pickle(f), "NOPE")
>             , Concatenation("FPEL", IO_Pickle(g), "NOPE")
>             , Concatenation("FFEC", IO_Pickle(2), "NOPE")
>             , Concatenation("CYCC", IO_Pickle(1), "NOPE")
>             , Concatenation("FRAC", IO_Pickle(1), "NOPE")
>             , Concatenation("PRML", "NOPE")
>             , Concatenation("OPER", "NOPE")
>             , Concatenation("FUNC", "NOPE")
>             ], x -> IO_Unpickle(x) <> IO_Error);
[  ]

# and none of that leaves the pickle cache behind
gap> IO_Unpickle(IO_Pickle(l)) = l;
true

#
# Pickles written by earlier versions have to keep working. These two were
# produced by GAP 4.17 with IO 4.10, the last version to write the printed
# form of permutations, field elements and cyclotomics.
#
gap> pickled_old := "MLIS\>4PERM\>C(1,2,3)(5,7)FFEL\>6Z(2^2)CYCL\>4E(3)\
> CYCL\>37/3";;
gap> IO_Unpickle(pickled_old);
[ (1,2,3)(5,7), Z(2^2), E(3), 7/3 ]
gap> SetInfoLevel(InfoWarning, old);
gap> STOP_TEST("pickle.tst", 1);
