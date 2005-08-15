# A few examples for IO to and from strings:
# Click this into a GAP:
LoadPackage("io");

# Reading from a string:
s := "A long string\nMax is here!\nHello world";
f := IO.WrapFD(-1,s,false);
IO.ReadLine(f);
f;
IO.Read(f,2);
f;
IO.ReadLines(f);
f; 
IO.ReadLines(f);
IO.Read(f);
IO.ReadLine(f);
IO.Close(f);

# Writing into a string:
b := "Anfang\n";
f:= IO.WrapFD(-1,false,b);
IO.WriteLine(f2,"Max");
f2;
IO.GetWBuf(f2);
IO.Write(f2,"Hi there","\n","\c",1234,2/3,"\n");
f2;
IO.Write(f2,Elements(SymmetricGroup(3)),"\n");
l := ["a","b","c"];
IO.WriteLines(f2,l);
IO.GetWBuf(f2);
f2;
IO.Close(f2);
f2;
IO.GetWBuf(f2);


