# A small client example using UDP:
LoadPackage("io");
Print("Sending packets using UDP...\n");
s := IO.socket(IO.PF_INET,IO.SOCK_DGRAM,"udp");
IO.connect(s,IO.MakeIPAddressPort("127.0.0.1",8000));
IO.send(s,"Max",0,3,0);
IO.send(s,"is",0,2,0);
IO.send(s,"here!",0,5,0);
IO.send(s,"QUIT",0,4,0);
IO.close(s);
