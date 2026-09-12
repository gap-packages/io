#############################################################################
##
##  unavailable.g            The IO package
##
##  Stubs for kernel functions which are not available on this platform.
##

#
# The C part registers each of the functions below only when configure found
# the system call it wraps, so which ones exist depends on the platform. On
# native Windows, for instance, there is no fork and there are no signals.
#
# Bind the missing ones here, before any of the GAP code that mentions them
# is read: without this, reading it warns about unbound globals, and calling
# one of them fails with a message that says nothing about the real reason.
#
BindGlobal( "IO_UnavailableFunc", function( name )
    return function( arg )
        Error( name, " is not available on this platform" );
    end;
end );

BindGlobal( "IO_MaybeUnavailable", [
  "IO_IgnorePid", "IO_InstallSIGCHLDHandler", "IO_RestoreSIGCHLDHandler",
  "IO_WaitPid", "IO_accept", "IO_bind", "IO_chmod", "IO_chown",
  "IO_closedir", "IO_connect", "IO_dup", "IO_dup2", "IO_fchmod",
  "IO_fchown", "IO_fcntl", "IO_fork", "IO_fstat", "IO_gethostbyname",
  "IO_gethostname", "IO_getpid", "IO_getppid", "IO_getsockname",
  "IO_getsockopt", "IO_gettimeofday", "IO_gmtime", "IO_kill",
  "IO_lchown", "IO_link", "IO_listen", "IO_localtime", "IO_lstat",
  "IO_make_sockaddr_in", "IO_mkdir", "IO_mkdtemp", "IO_mkfifo",
  "IO_mknod", "IO_mkstemp", "IO_opendir", "IO_pipe", "IO_readdir",
  "IO_readlink", "IO_recv", "IO_recvfrom", "IO_rename", "IO_rewinddir",
  "IO_rmdir", "IO_seekdir", "IO_select", "IO_send", "IO_sendto",
  "IO_setsockopt", "IO_socket", "IO_stat", "IO_symlink", "IO_telldir",
  "IO_unlink"
] );

for IO_name in IO_MaybeUnavailable do
    if not IsBoundGlobal( IO_name ) then
        BindGlobal( IO_name, IO_UnavailableFunc( IO_name ) );
    fi;
od;
Unbind( IO_name );
