LoadPackage("io");

# Test if GAP hangs while exiting. We will not
# clean up these processes, but hopefully they won't
# cause too much trouble.

x1 := IO_Popen("sleep", ["3600"],"r");
x2 := IO_Popen("sleep", ["3600"],"w");
x3 := IO_Popen2("sleep", ["3600"]);
x4 := IO_Popen3("sleep", ["3600"]);

y1 := IO_Popen("sleep", ["3600"],"r");
y2 := IO_Popen("sleep", ["3600"],"w");
y3 := IO_Popen2("sleep", ["3600"]);
y4 := IO_Popen3("sleep", ["3600"]);
Print("trying to exit...");
