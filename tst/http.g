# Test HTTP protocol:

LoadPackage("io");

r := SingleHTTPRequest("neverssl.com",80,"GET",
        "/index.html",
        rec(),false,false);

if r.statuscode <> 200 then
    Print("Error ", r.statuscode, ": request was not successful, please check record r!\n");
fi;


