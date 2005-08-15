# Pipes some megabytes through /bin/cat:
LoadPackage("io");
s := "Max";
for i in [1..25] do Append(s,s); od;
Print("Have string of length ",Length(s),".\n");
p := IO.Popen2("/bin/cat",[]);
IO.SendStringBackground(p.stdin,s);
# We want that /bin/cat terminates after the child has sent everything:
IO.Close(p.stdin);   
t := IO.Read(p.stdout);
IO.Close(p.stdout);
Print("Have read string!\n");
if s <> t then
    Print("Alert: Received string not identical to original one!\n");
fi;
