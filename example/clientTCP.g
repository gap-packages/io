# A little network client using TCP/IP:

LoadPackage("io");
Print("Connecting via TCP/IP...\n");
s := IO.socket(IO.PF_INET,IO.SOCK_STREAM,"tcp");
res := IO.connect(s,IO.MakeIPAddressPort("127.0.0.1",8000));
if res = fail then
    Print("Error: ",LastSystemError(),"\n");
    IO.close(s);
else
    f := IO.WrapFD(s,IO.DefaultBufSize,IO.DefaultBufSize);
    IO.WriteLine(f,"Hello world!\n");
    Print("Sent: Hello word!\n");
    st := IO.ReadLine(f);
    Print("Got back: ",st);
    IO.Close(f);
fi;
s := IO.socket(IO.PF_INET,IO.SOCK_STREAM,"tcp");
res := IO.connect(s,IO.MakeIPAddressPort("127.0.0.1",8000));
if res = fail then
    Print("Error: ",LastSystemError(),"\n");
    IO.close(s);
else
    f := IO.WrapFD(s,IO.DefaultBufSize,IO.DefaultBufSize);
    IO.WriteLine(f,"QUIT\n");
    Print("Sent: QUIT\n");
    st := IO.ReadLine(f);
    Print("Got back: ",st);
    IO.Close(f);
fi;
