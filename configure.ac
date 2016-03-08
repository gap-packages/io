AC_PREREQ([2.68])
AC_INIT([io], m4_esyscmd([tr -d '\n' < VERSION]), [https://github.com/gap-packages/io/issues], [io], [http://gap-packages.github.io/io/])
AC_CONFIG_SRCDIR([src/io.c])
AC_CONFIG_HEADER([src/pkgconfig.h:cnf/pkgconfig.h.in])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([cnf])
AM_INIT_AUTOMAKE([1.11 -Wall foreign subdir-objects])
AM_SILENT_RULES([yes])

dnl Disable maintainer mode by default. This avoids troubles during packaging,
dnl in particular when the GAP team repackages the source archive.
dnl Users can re-enable it by passing "--enable-maintainer-mode" to configure.
AM_MAINTAINER_MODE

AC_PROG_CC
AM_PROG_AR

LT_PREREQ([2.4.2])
LT_INIT([disable-static dlopen win32-dll])

AC_FIND_GAP

AC_CHECK_SIZEOF([void **])

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
AC_CHECK_FUNCS([dup2 gethostbyname lchown memset mkdir mkfifo rmdir select socket getprotobyname signal sigaction opendir readdir closedir rewinddir telldir seekdir unlink link rename symlink readlink accept bind chmod connect dup fchmod fchown stat fstat lstat getsockopt listen lstat mknod mkstemp mkdtemp recv recvfrom send sendto setsockopt gettimeofday gmtime localtime getpid getppid kill gethostname getsockname])

AC_CYGWIN
AM_CONDITIONAL([SYS_IS_CYGWIN], [test "$CYGWIN" = "yes"])
if test "$CYGWIN" = "yes"; then
  AC_DEFINE(SYS_IS_CYGWIN32, 1, are we on CYGWIN?)
else
  AC_DEFINE(SYS_IS_CYGWIN32, 0, are we on CYGWIN?)
fi

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
