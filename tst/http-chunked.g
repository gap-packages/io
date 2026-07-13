# Test that a chunked HTTP response does not require the server to close the
# connection.

LoadPackage("io");

listener := IO_socket(IO.PF_INET, IO.SOCK_STREAM, "tcp");
IO_bind(listener, IO_MakeIPAddressPort("127.0.0.1", 0));
IO_listen(listener, 1);
address := IO_getsockname(listener);
port := 256 * INT_CHAR(address[3]) + INT_CHAR(address[4]);

pid := IO_fork();
if pid = 0 then
    socket := IO_accept(listener, IO_MakeIPAddressPort("0.0.0.0", 0));
    connection := IO_WrapFD(socket, IO.DefaultBufSize, IO.DefaultBufSize);
    IO_Write(connection,
        "HTTP/1.1 200 OK\r\n",
        "Transfer-Encoding: chunked\r\n",
        "Connection: keep-alive\r\n\r\n",
        "4\r\nGAP \r\n",
        "2\r\nIO\r\n",
        "0\r\nX-Test: yes\r\n\r\n");
    IO_Flush(connection);
    Sleep(2);
    IO_Close(connection);
    IO_close(listener);
    IO_exit(0);
fi;

HTTPTimeoutForSelect[1] := 1;
HTTPTimeoutForSelect[2] := 0;
response := SingleHTTPRequest("127.0.0.1", port, "GET", "/",
                              rec(), false, false);
HTTPTimeoutForSelect[1] := fail;
HTTPTimeoutForSelect[2] := fail;
IO_close(listener);
IO_WaitPid(pid, true);

if response.statuscode <> 200 or response.body <> "GAP IO" then
    Error("chunked response did not finish before the server closed");
fi;
