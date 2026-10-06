# Installing and restoring the SIGCHLD handler never raises an error, also
# on platforms without SIGCHLD
gap> IsBool(IO_RestoreSIGCHLDHandler());
true
gap> IsBool(IO_InstallSIGCHLDHandler());
true
