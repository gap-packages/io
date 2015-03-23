# Test HTTP protocol:

LoadPackage("io");

r := SingleHTTPRequest("www-groups.mcs.st-and.ac.uk",80,"GET",
        "/~neunhoef/Computer/Software/Gap/io.version",
        rec(),false,false);

if r.statuscode <> 200 then
    Print("Request was not successful, please check record r!\n");
else
    expected := Concatenation(
    "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<mixer>\n",
    "5.0\n</mixer>\n");

    if r.body <> expected then
        Print("Did not find expected body. ",
              "Maybe your IO package is not current?\n");
    fi;
fi;


