#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.61)
AC_INIT(IOPKG, 1.0, neunhoef@mcs.st-and.ac.uk)
AC_CONFIG_HEADER([ioconfig.h:ioconfig.hin])
AC_CONFIG_AUX_DIR(.)

AC_CANONICAL_TARGET

# From aclocal.m4:
GP_C_LONG_ALIGN_IO
GP_CFLAGS
GP_LDFLAGS
GP_PROG_CC_DYNFLAGS

# Checks for programs.
AC_PROG_CC

# Checks for libraries.

# Checks for header files.
AC_HEADER_DIRENT
AC_HEADER_STDC
AC_HEADER_SYS_WAIT
AC_CHECK_HEADERS([fcntl.h netdb.h netinet/in.h netinet/tcp.h stdlib.h sys/socket.h sys/time.h time.h unistd.h signal.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_PID_T
AC_CHECK_MEMBERS([struct stat.st_blksize])
AC_STRUCT_ST_BLOCKS
AC_CHECK_MEMBERS([struct stat.st_rdev])
AC_HEADER_TIME

# Checks for library functions.
AC_FUNC_CHOWN
AC_FUNC_CLOSEDIR_VOID
AC_FUNC_FORK
AC_FUNC_LSTAT
AC_FUNC_LSTAT_FOLLOWS_SLASHED_SYMLINK
AC_FUNC_SELECT_ARGTYPES
AC_TYPE_SIGNAL
AC_FUNC_STAT
AC_CHECK_FUNCS([dup2 gethostbyname lchown memset mkdir mkfifo rmdir select socket getprotobyname signal opendir readdir closedir rewinddir telldir seekdir unlink link rename symlink readlink accept bind chmod connect dup fchmod fchown stat fstat lstat getsockopt listen lstat mknod recv recvfrom send sendto setsockopt gettimeofday gmtime localtime getpid getppid kill])

AC_CYGWIN
if test "$CYGWIN" = "yes"; then
  AC_DEFINE(SYS_IS_CYGWIN32, 1, are we on CYGWIN?)
else
  AC_DEFINE(SYS_IS_CYGWIN32, 0, are we on CYGWIN?)
fi


case "$host" in
        *-darwin* )
        AC_DEFINE(SYS_IS_DARWIN, 1, are we on DARWIN?)
        ;;
        * )
        AC_DEFINE(SYS_IS_DARWIN, 0, are we on DARWIN?)
        ;;
esac
     
AC_SUBST(GAPPATH)
AC_SUBST(GAPARCH)
AC_SUBST(PKGIOPATH)
AC_OUTPUT(Makefile:Makefile.in)
