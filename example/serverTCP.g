# A small example for a network server:

LoadPackage("io");
Print("Waiting for TCP/IP connections...\n");
s := IO.socket(IO.PF_INET,IO.SOCK_STREAM,"tcp");
IO.bind(s,IO.MakeIPAddressPort("127.0.0.1",8000));
IO.listen(s,5);   # Allow a backlog of 5 connections

terminate := false;
repeat
    # We accept connections from everywhere:
    t := IO.accept(s,IO.MakeIPAddressPort("0.0.0.0",0));
    Print("Got connection...\n");
    f := IO.WrapFD(t,IO.DefaultBufSize,IO.DefaultBufSize);
    repeat
        line := IO.ReadLine(f);
        if line <> "" and line <> fail then
            Print("Got line: ",line);
            IO.Write(f,line);
            IO.Flush(f);
            if line = "QUIT\n" then
                terminate := true;
            fi;
        fi;
    until line = "" or line = fail;
    Print("Connection terminated.\n");
    IO.Close(f);
until terminate;
IO.close(s);
