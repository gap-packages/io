AC_PREREQ([2.68])
AC_INIT([io], [package], [https://github.com/gap-packages/io/issues], [io], [http://gap-packages.github.io/io/])
AC_CONFIG_SRCDIR([src/io.c])
AC_CONFIG_HEADER([gen/pkgconfig.h])
AC_CONFIG_MACRO_DIR([m4])
m4_include([m4/find_gap.m4])

AC_PROG_CC

FIND_GAP

# Checks for header files.
AC_HEADER_DIRENT
AC_HEADER_STDC
AC_HEADER_SYS_WAIT
AC_CHECK_HEADERS([fcntl.h netdb.h netinet/in.h netinet/tcp.h stdlib.h sys/param.h sys/socket.h sys/time.h time.h unistd.h signal.h])

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
AC_CHECK_FUNCS([dup2 gethostbyname lchown memset mkdir mkfifo rmdir select socket getprotobyname signal sigaction opendir readdir closedir rewinddir telldir seekdir unlink link rename symlink readlink accept bind chmod connect dup fchmod fchown stat fstat lstat getsockopt listen lstat mknod mkstemp mkdtemp recv recvfrom send sendto setsockopt gettimeofday gmtime localtime getpid getppid kill gethostname getsockname])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
