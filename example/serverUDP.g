# A small server example using UDP:
LoadPackage("io");
Print("Waiting for UDP packets...\n");
s := IO.socket(IO.PF_INET,IO.SOCK_DGRAM,"udp");
IO.bind(s,IO.MakeIPAddressPort("127.0.0.1",8000));
repeat
    b := "";
    l := IO.recv(s,b,0,80,0);
    Print("Received ",l," bytes: ",b{[1..l]},"\n");
until b{[1..l]} = "QUIT";
IO.close(s);
