/***************************************************************************
**
*A  io.c               IO-package                            Max Neunhoeffer
**
**
**  Copyright (C) by Max Neunhoeffer
**  This file is free software, see license information at the end.
**
*/

/* Try to use as much of the GNU C library as possible: */
#define _GNU_SOURCE

#include "compiled.h" // GAP headers

#if GAP_KERNEL_MAJOR_VERSION >= 6
#include "src/profile.h"
#endif

#undef PACKAGE
#undef PACKAGE_BUGREPORT
#undef PACKAGE_NAME
#undef PACKAGE_STRING
#undef PACKAGE_TARNAME
#undef PACKAGE_URL
#undef PACKAGE_VERSION

#include "pkgconfig.h"    /* our own autoconf results */

#include <stdio.h>
#include <stdlib.h>
#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#endif
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#ifdef HAVE_TIME_H
#include <time.h>
#endif
#include <errno.h>
#ifdef HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_DIRENT_H
#include <dirent.h>
#endif
#ifdef HAVE_NETDB_H
#include <netdb.h>
#endif
#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif
#ifdef HAVE_SYS_WAIT_H
#include <sys/wait.h>
#endif
#ifdef HAVE_SIGNAL_H
/* Maybe the GAP kernel headers have already included it: */
#ifndef SYS_SIGNAL_H
#include <signal.h>
#endif
#endif
/* We should test for existence of netinet/in.h and netinet/tcp.h, but
 * this would require a change in the GAP configure script, which is
 * tedious. */
#ifdef HAVE_NETINET_IN_H
#include <netinet/in.h>
/* #include <netinet/ip.h> */
#endif
#ifdef HAVE_NETINET_TCP_H
#include <netinet/tcp.h>
#endif
#if defined(__CYGWIN__) || defined(__CYGWIN32__)
#include <cygwin/in.h>
#endif

/* The following seems to be necessary to run under modern gcc compilers
 * which have the ssp stack checking enabled. Hopefully this does not
 * hurt in future or other versions... */
#ifdef __GNUC__
#if (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 1))
#if defined(__CYGWIN__) || defined(__CYGWIN32__)
extern void __stack_chk_fail();
void __stack_chk_fail_local (void)
{
  __stack_chk_fail ();
}
#endif
#endif
#endif


/* Functions that are done:
 * open, creat, read, write, close, unlink, lseek, opendir, readdir,
 * closedir, rewinddir, telldir, seekdir, link, rename, symlink, readlink,
 * rmdir, mkdir, stat, lstat, fstat, chmod, fchmod, chown, fchown, lchown,
 * mknod, mkstemp, mkdtemp, mkfifo, dup, dup2, socket, bind, connect,
 * gethostbyname, listen,
 * accept, recv, recvfrom, send, sendto, getsockopt, setsockopt, select,
 * fork, execv, execvp, execve, pipe, exit, getsockname, gethostname,
 *
 * Additional helper functions:
 * make_sockaddr_in, MakeEnvList, environ,
 */

/* Functions that are to do (maybe later):
 *
 * and perhaps:
 *   socketpair, getsockname, poll, setrlimit, getrlimit, getrusage, ulimit,
 * not for the moment (portability or implementation problems):
 *   remove, scandir, ioctl? (absolutely unportable, as it seems),
 *   fcntl? (for file locking purposes), recvmsg, sendmsg,
 */

/***********************************************************************
 * First we have our own SIGCHLD handler. It is a copy of the one in the
 * GAP kernel, however, information about all children that are not
 * coming from streams is stored in one data structure here, such that
 * we can read it out from GAP using IO.Wait.
 ***********************************************************************/

// FIXME: globals

#define MAXCHLDS 1024
/* The following arrays make a FIFO structure: */
static int stats[MAXCHLDS];        /* than this number */
static int pids[MAXCHLDS];         /* and this number! */
static int fistats = 0;            /* First used entry */
static int lastats = 0;            /* First unused entry */
static int statsfull = 0;          /* Flag, whether stats FIFO full */


// This function must only be called while IO's signal handler is disabled!
static int findSignaledPid(int pidc)
{
    if (fistats == lastats && !statsfull) /* queue empty */
        return -1;

    if (pidc == -1)  /* queue not empty and any entry welcome */
        return fistats;

    int pos = fistats;
    while (pids[pos] != pidc)
    {
        pos++;
        if (pos >= MAXCHLDS) pos = 0;
        if (pos == lastats) {
            pos = -1;  /* None found */
            break;
        }
    }
    return pos;
}

// This function must only be called while IO's signal handler is disabled!
static void removeSignaledPidByPos(int pos)
{
    if (fistats == lastats && !statsfull) /* queue empty */
        return;

    int newpos;
    if (pos == fistats) {  /* this is the easy case: */
        fistats++;
        if (fistats >= MAXCHLDS) fistats = 0;
    } else {  /* The more difficult case: */
        do {
            newpos = pos+1;
            if (newpos >= MAXCHLDS) newpos = 0;
            if (newpos == lastats) break;
            stats[pos] = stats[newpos];
            pids[pos] = pids[newpos];
            pos = newpos;
        } while(1);
        lastats = pos;
    }
    statsfull = 0;
}

/* This does not have to be the same size as the array above */
static int ignoredpids[MAXCHLDS];
static int ignoredpidslen;

static int IO_CheckForIgnoredPid( int pid );

static void (*oldhandler)(int whichsig) = 0;  /* the old handler */

static void IO_HandleChildSignal(int retcode, int status)
{
   if (retcode > 0) {   /* One of our child processes terminated */
        if (WIFEXITED(status) || WIFSIGNALED(status)) {
#ifdef GAP_HasCheckChildStatusChanged
            if (CheckChildStatusChanged(retcode, status)) {
                // GAP has dealt with the signal
            } else
#endif
            if (IO_CheckForIgnoredPid(retcode)) {
                // Previously registered with IO_IgnorePid
            } else
            if (!statsfull) {
                stats[lastats] = status;
                pids[lastats++] = retcode;
                if (lastats >= MAXCHLDS) lastats = 0;
                if (lastats == fistats) statsfull = 1;
            } else
                Pr("#E Overflow in table of terminated processes\n",0,0);
        }
    }
}

#ifdef HAVE_SIGNAL
void IO_SIGCHLDHandler( int whichsig )
{
  int retcode,status;
  /* We collect information about our child processes that have
     terminated: */
  do {
    retcode = waitpid(-1, &status, WNOHANG);
    IO_HandleChildSignal(retcode, status);
  } while (retcode > 0);

  signal(SIGCHLD, IO_SIGCHLDHandler);
}

static Obj FuncIO_InstallSIGCHLDHandler( Obj self )
{
  /* Do not install ourselves twice: */
  if (oldhandler == 0) {
      oldhandler = signal(SIGCHLD, IO_SIGCHLDHandler);
      signal(SIGPIPE,SIG_IGN);
      return True;
  } else
      return False;
}

static Obj FuncIO_RestoreSIGCHLDHandler( Obj self )
{
  if (oldhandler == 0)
      return False;
  else {
      signal(SIGCHLD,oldhandler);
      oldhandler = 0;
      signal(SIGPIPE,SIG_DFL);
      return True;
  }
}

// The following function checks if a PID is marked as ignored.
// Returns 1 if the PID was ignored, 0 otherwise.
// This function must only be called while IO's signal handler is disabled!
static int IO_CheckForIgnoredPid( int pid )
{
    int i;
    // Make sure a new signal doesn't come in while looking at array
    int found = 0;
    for(i = 0; i < ignoredpidslen; ++i) {
        if (ignoredpids[i] == pid) {
            ignoredpids[i] = ignoredpids[ignoredpidslen - 1];
            ignoredpidslen--;
            found = 1;
            break;
        }
    }
    return found;
}

static Obj FuncIO_IgnorePid(Obj self, Obj pid)
{
    Int pidc;
    int pos;
    if (!IS_INTOBJ(pid)) {
        return Fail;
    }
    pidc = INT_INTOBJ(pid);

    if (pidc < 0) {
        return Fail;
    }

    // Make sure a new signal doesn't come in while we are changing array
    signal(SIGCHLD, SIG_DFL);

    pos = findSignaledPid(pidc);
    if (pos != -1)
    {
        // This PID has already finished
        removeSignaledPidByPos(pos);
        signal(SIGCHLD,IO_SIGCHLDHandler);
        return True;
    }

    if (ignoredpidslen < MAXCHLDS - 1) {
        ignoredpids[ignoredpidslen] = pidc;
        ignoredpidslen++;
        signal(SIGCHLD,IO_SIGCHLDHandler);
    }
    else {
        Pr("#E Overflow in table of ignored processes",0,0);
        signal(SIGCHLD,IO_SIGCHLDHandler);
        return Fail;
    }
    return True;
}

static Obj FuncIO_WaitPid(Obj self,Obj pid,Obj wait)
{
  Int pidc;
  int pos;
  Obj tmp;
  int retcode,status;
  int reallytried;
  if (!IS_INTOBJ(pid)) {
      SyClearErrorNo();
      return Fail;
  }
  /* First set SIGCHLD to default action to avoid clashes with access: */
  signal(SIGCHLD,SIG_DFL);
  pidc = INT_INTOBJ(pid);
  reallytried = 0;
  do {
      pos = findSignaledPid(pidc);
      if (pos != -1)
          break;  /* we found something! */
      if (reallytried && wait != True) {
          /* Reinstantiate our handler: */
          signal(SIGCHLD,IO_SIGCHLDHandler);
          return False;
      }
      /* Really wait for something */
      retcode = waitpid(-1, &status, (wait == True) ? 0 : WNOHANG);
      IO_HandleChildSignal(retcode, status);
      reallytried = 1;  /* Do not try again. */
  } while (1);  /* Left by break */
  tmp = NEW_PREC(0);
  AssPRec(tmp,RNamName("pid"),INTOBJ_INT(pids[pos]));
  AssPRec(tmp,RNamName("status"),INTOBJ_INT(stats[pos]));
  AssPRec(tmp,RNamName("WIFEXITED"), INTOBJ_INT(WIFEXITED(stats[pos])));
  AssPRec(tmp,RNamName("WEXITSTATUS"), INTOBJ_INT(WEXITSTATUS(stats[pos])));

  /* Dequeue element: */
  removeSignaledPidByPos(pos);
  /* Reinstantiate our handler: */
  signal(SIGCHLD,IO_SIGCHLDHandler);
  return tmp;
}
#endif

static Obj FuncIO_open(Obj self,Obj path,Obj flags,Obj mode)
{
  int res;
  if (!IS_STRING(path) || !IS_STRING_REP(path) || !IS_INTOBJ(flags) ||
      !IS_INTOBJ(mode) ) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = open(CSTR_STRING(path),
                 INT_INTOBJ(flags),INT_INTOBJ(mode));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return INTOBJ_INT(res);
  }
}

static Obj FuncIO_creat(Obj self,Obj path,Obj mode)
{
  int res;
  if (!IS_STRING(path) || !IS_STRING_REP(path) || !IS_INTOBJ(mode) ) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = creat(CSTR_STRING(path),INT_INTOBJ(mode));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return INTOBJ_INT(res);
  }
}

static Obj FuncIO_read(Obj self,Obj fd,Obj st,Obj offset,Obj count)
{
  Int bytes;
  Int len;

  if (!IS_INTOBJ(fd) || !IS_STRING(st) || !IS_STRING_REP(st) ||
      !IS_INTOBJ(count)) {
      SyClearErrorNo();
      return Fail;
  }

  len = INT_INTOBJ(offset)+INT_INTOBJ(count);
  if (len > GET_LEN_STRING(st)) GrowString(st,len);
  bytes = read(INT_INTOBJ(fd),CHARS_STRING(st)+INT_INTOBJ(offset),
               INT_INTOBJ(count));
  if (bytes < 0) {
      SySetErrorNo();
      return Fail;
  } else {
      if (bytes + INT_INTOBJ(offset) > GET_LEN_STRING(st)) {
          SET_LEN_STRING(st,bytes + INT_INTOBJ(offset));
          CHARS_STRING(st)[len] = 0;
      }
      return INTOBJ_INT(bytes);
  }
}

static Obj FuncIO_write(Obj self,Obj fd,Obj st,Obj offset,Obj count)
{
  Int bytes;

  if (!IS_INTOBJ(fd) || !IS_STRING(st) || !IS_STRING_REP(st) ||
      !IS_INTOBJ(offset) || !IS_INTOBJ(count)) {
      SyClearErrorNo();
      return Fail;
  }
  if (GET_LEN_STRING(st) < INT_INTOBJ(offset)+INT_INTOBJ(count)) {
      SyClearErrorNo();
      return Fail;
  }
  bytes = (Int) write(INT_INTOBJ(fd),CHARS_STRING(st)+INT_INTOBJ(offset),
                      INT_INTOBJ(count));
  if (bytes < 0) {
      SySetErrorNo();
      return Fail;
  } else
      return INTOBJ_INT(bytes);
}

static Obj FuncIO_close(Obj self,Obj fd)
{
  int res;

  if (!IS_INTOBJ(fd)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = close(INT_INTOBJ(fd));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}

static Obj FuncIO_lseek(Obj self,Obj fd,Obj offset,Obj whence)
{
  Int bytes;

  if (!IS_INTOBJ(fd) || !IS_INTOBJ(offset) || !IS_INTOBJ(whence)) {
      SyClearErrorNo();
      return Fail;
  }

  bytes = lseek(INT_INTOBJ(fd),INT_INTOBJ(offset),INT_INTOBJ(whence));
  if (bytes < 0) {
      SySetErrorNo();
      return Fail;
  } else {
      return INTOBJ_INT(bytes);
  }
}

#ifdef HAVE_DIRENT_H
// FIXME: globals
static DIR *ourDIR = 0;
static struct dirent *ourdirent;

#ifdef HAVE_OPENDIR
static Obj FuncIO_opendir(Obj self,Obj name)
{
  if (!IS_STRING(name) || !IS_STRING_REP(name)) {
      SyClearErrorNo();
      return Fail;
  } else {
      ourDIR = opendir(CSTR_STRING(name));
      if (ourDIR == 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif     /* HAVE_OPENDIR */

#ifdef HAVE_READDIR
static Obj FuncIO_readdir(Obj self)
{
  Int olderrno;
  if (ourDIR == 0) {
      SyClearErrorNo();
      return Fail;
  }
  olderrno = errno;
  ourdirent = readdir(ourDIR);
  if (ourdirent == 0) {
      /* This is a bit of a hack, but how should this be done? */
      if (errno == EBADF && olderrno != EBADF) {
          SySetErrorNo();
          return Fail;
      } else {
          SyClearErrorNo();
          return False;
      }
  }
  return MakeString(ourdirent->d_name);
}
#endif     /* HAVE_READDIR */

#ifdef HAVE_CLOSEDIR
static Obj FuncIO_closedir(Obj self)
{
  int res;

  if (ourDIR == 0) {
      SyClearErrorNo();
      return Fail;
  }
  res = closedir(ourDIR);
  if (res < 0) {
      SySetErrorNo();
      return Fail;
  } else
      return True;
}
#endif     /* HAVE_CLOSEDIR */

#ifdef HAVE_REWINDDIR
static Obj FuncIO_rewinddir(Obj self)
{
  if (ourDIR == 0) {
      SyClearErrorNo();
      return Fail;
  }
  rewinddir(ourDIR);
  return True;
}
#endif     /* HAVE_REWINDDIR */

#ifdef HAVE_TELLDIR
static Obj FuncIO_telldir(Obj self)
{
  Int o;
  if (ourDIR == 0) {
      SyClearErrorNo();
      return Fail;
  }
  o = telldir(ourDIR);
  if (o < 0) {
      SySetErrorNo();
      return Fail;
  } else
      return INTOBJ_INT(o);
}
#endif     /* HAVE_TELLDIR */

#ifdef HAVE_SEEKDIR
static Obj FuncIO_seekdir(Obj self,Obj offset)
{
  if (!IS_INTOBJ(offset)) {
      SyClearErrorNo();
      return Fail;
  }
  if (ourDIR == 0) {
      SyClearErrorNo();
      return Fail;
  }
  seekdir(ourDIR,INT_INTOBJ(offset));
  return True;
}
#endif     /* HAVE_SEEKDIR */

#endif     /* HAVE_DIRENT_H */

#ifdef HAVE_UNLINK
static Obj FuncIO_unlink(Obj self,Obj path)
{
  int res;
  if (!IS_STRING(path) || !IS_STRING_REP(path)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = unlink(CSTR_STRING(path));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_LINK
static Obj FuncIO_link(Obj self,Obj oldpath,Obj newpath)
{
  int res;
  if (!IS_STRING(oldpath) || !IS_STRING_REP(oldpath) ||
      !IS_STRING(newpath) || !IS_STRING_REP(newpath)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = link(CSTR_STRING(oldpath),CSTR_STRING(newpath));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_RENAME
static Obj FuncIO_rename(Obj self,Obj oldpath,Obj newpath)
{
  int res;
  if (!IS_STRING(oldpath) || !IS_STRING_REP(oldpath) ||
      !IS_STRING(newpath) || !IS_STRING_REP(newpath)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = rename(CSTR_STRING(oldpath),
                   CSTR_STRING(newpath));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_SYMLINK
static Obj FuncIO_symlink(Obj self,Obj oldpath,Obj newpath)
{
  int res;
  if (!IS_STRING(oldpath) || !IS_STRING_REP(oldpath) ||
      !IS_STRING(newpath) || !IS_STRING_REP(newpath)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = symlink(CSTR_STRING(oldpath),
                    CSTR_STRING(newpath));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_READLINK
static Obj FuncIO_readlink(Obj self,Obj path,Obj buf,Obj bufsize)
{
  int res;
  if (!IS_STRING(path) || !IS_STRING_REP(path) ||
      !IS_STRING(buf) || !IS_STRING_REP(buf) || !IS_INTOBJ(bufsize)) {
      SyClearErrorNo();
      return Fail;
  } else {
      GrowString(buf,INT_INTOBJ(bufsize));
      res = readlink(CSTR_STRING(path),
                     CSTR_STRING(buf),INT_INTOBJ(bufsize));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else {
          SET_LEN_STRING(buf,res);
          CHARS_STRING(buf)[res] = 0;
          return INTOBJ_INT(res);
      }
  }
}
#endif

static Obj FuncIO_realpath(Obj self, Obj path)
{
    if (!IS_STRING_REP(path)) {
        SyClearErrorNo();
        return Fail;
    }

    char buf[PATH_MAX];
    if (realpath(CSTR_STRING(path), buf)) {
        return MakeImmString(buf);
    }

    SySetErrorNo();
    return Fail;
}


static Obj FuncIO_chdir(Obj self,Obj pathname)
{
  int res;
  if (!IS_STRING(pathname) || !IS_STRING_REP(pathname)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = chdir(CSTR_STRING(pathname));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}

static Obj FuncIO_getcwd(Obj self)
{
  char *res;
  char buf[GAP_PATH_MAX];

  res = getcwd(buf, sizeof(buf));
  if (res == NULL) {
      SySetErrorNo();
      return Fail;
  } else
      return MakeImmString(buf);
}

#ifdef HAVE_MKDIR
static Obj FuncIO_mkdir(Obj self,Obj pathname,Obj mode)
{
  int res;
  if (!IS_STRING(pathname) || !IS_STRING_REP(pathname) || !IS_INTOBJ(mode)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = mkdir(CSTR_STRING(pathname),INT_INTOBJ(mode));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_RMDIR
static Obj FuncIO_rmdir(Obj self,Obj path)
{
  int res;
  if (!IS_STRING(path) || !IS_STRING_REP(path)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = rmdir(CSTR_STRING(path));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#if defined(HAVE_STAT) || defined(HAVE_FSTAT) || defined(HAVE_LSTAT)

static Obj WrapStat(struct stat * statbuf)
{
    Obj rec = NEW_PREC(13);
    AssPRec(rec, RNamName("dev"), ObjInt_UInt8(statbuf->st_dev));
    AssPRec(rec, RNamName("ino"), ObjInt_UInt8(statbuf->st_ino));
    AssPRec(rec, RNamName("mode"),ObjInt_UInt(statbuf->st_mode));
    AssPRec(rec, RNamName("nlink"), ObjInt_UInt8(statbuf->st_nlink));
    AssPRec(rec, RNamName("uid"), ObjInt_UInt(statbuf->st_uid));
    AssPRec(rec, RNamName("gid"), ObjInt_UInt(statbuf->st_gid));
    AssPRec(rec, RNamName("rdev"), ObjInt_UInt8(statbuf->st_rdev));
    AssPRec(rec, RNamName("size"), ObjInt_Int8(statbuf->st_size));
    AssPRec(rec, RNamName("blksize"), ObjInt_Int8(statbuf->st_blksize));
    AssPRec(rec, RNamName("blocks"), ObjInt_Int8(statbuf->st_blocks));
    AssPRec(rec, RNamName("atime"), ObjInt_Int(statbuf->st_atime));
    AssPRec(rec, RNamName("mtime"), ObjInt_Int(statbuf->st_mtime));
    AssPRec(rec, RNamName("ctime"), ObjInt_Int(statbuf->st_ctime));
    return rec;
}

#endif

#ifdef HAVE_STAT
static Obj FuncIO_stat(Obj self,Obj filename)
{
    if (!IS_STRING(filename) || !IS_STRING_REP(filename)) {
        SyClearErrorNo();
        return Fail;
    }

    struct stat ourstatbuf;
    int res = stat(CSTR_STRING(filename), &ourstatbuf);
    if (res < 0) {
        SySetErrorNo();
        return Fail;
    }
    return WrapStat(&ourstatbuf);
}
#endif

#ifdef HAVE_FSTAT
static Obj FuncIO_fstat(Obj self,Obj fd)
{
    if (!IS_INTOBJ(fd)) {
        SyClearErrorNo();
        return Fail;
    }

    struct stat ourstatbuf;
    int res = fstat(INT_INTOBJ(fd), &ourstatbuf);
    if (res < 0) {
        SySetErrorNo();
        return Fail;
    }
    return WrapStat(&ourstatbuf);
}
#endif

#ifdef HAVE_LSTAT
static Obj FuncIO_lstat(Obj self,Obj filename)
{
    if (!IS_STRING(filename) || !IS_STRING_REP(filename)) {
        SyClearErrorNo();
        return Fail;
    }

    struct stat ourstatbuf;
    int res = lstat(CSTR_STRING(filename), &ourstatbuf);
    if (res < 0) {
        SySetErrorNo();
        return Fail;
    }
    return WrapStat(&ourstatbuf);
}
#endif

#ifdef HAVE_CHMOD
static Obj FuncIO_chmod(Obj self,Obj pathname,Obj mode)
{
  int res;
  if (!IS_STRING(pathname) || !IS_STRING_REP(pathname) || !IS_INTOBJ(mode)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = chmod(CSTR_STRING(pathname),INT_INTOBJ(mode));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_FCHMOD
static Obj FuncIO_fchmod(Obj self,Obj fd,Obj mode)
{
  int res;
  if (!IS_INTOBJ(fd) || !IS_INTOBJ(mode)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = fchmod(INT_INTOBJ(fd),INT_INTOBJ(mode));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_CHOWN
static Obj FuncIO_chown(Obj self,Obj path,Obj owner,Obj group)
{
  int res;
  if (!IS_STRING(path) || !IS_STRING_REP(path) ||
      !IS_INTOBJ(owner) || !IS_INTOBJ(group)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = chown(CSTR_STRING(path),
                  INT_INTOBJ(owner),INT_INTOBJ(group));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_FCHOWN
static Obj FuncIO_fchown(Obj self,Obj fd,Obj owner,Obj group)
{
  int res;
  if (!IS_INTOBJ(fd) || !IS_INTOBJ(owner) || !IS_INTOBJ(group)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = fchown(INT_INTOBJ(fd),INT_INTOBJ(owner),INT_INTOBJ(group));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_LCHOWN
static Obj FuncIO_lchown(Obj self,Obj path,Obj owner,Obj group)
{
  int res;
  if (!IS_STRING(path) || !IS_STRING_REP(path) ||
      !IS_INTOBJ(owner) || !IS_INTOBJ(group)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = lchown(CSTR_STRING(path),
                   INT_INTOBJ(owner),INT_INTOBJ(group));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_MKNOD
static Obj FuncIO_mknod(Obj self,Obj path,Obj mode,Obj dev)
{
  int res;
  if (!IS_STRING(path) || !IS_STRING_REP(path) ||
      !IS_INTOBJ(mode) || !IS_INTOBJ(dev)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = mknod(CSTR_STRING(path),INT_INTOBJ(mode),INT_INTOBJ(dev));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_MKSTEMP
static Obj FuncIO_mkstemp(Obj self,Obj template)
{
    Int fd;
    if (!IS_STRING(template) || !IS_STRING_REP(template)) {
        SyClearErrorNo();
        return Fail;

    } else {
        fd = mkstemp(CSTR_STRING(template));
        if (fd < 0) {
            SySetErrorNo();
            return Fail;
        } else {
            return INTOBJ_INT(fd);
        }
    }
}
#endif

#ifdef HAVE_MKDTEMP
static Obj FuncIO_mkdtemp(Obj self,Obj template)
{
    char *r;

    if (!IS_STRING(template) || !IS_STRING_REP(template)) {
        SyClearErrorNo();
        return Fail;
    } else {
        r = mkdtemp(CSTR_STRING(template));
        if (r == NULL) {
            SySetErrorNo();
            return Fail;
        } else {
            return MakeString(r);
        }
    }
}
#endif

#ifdef HAVE_MKFIFO
static Obj FuncIO_mkfifo(Obj self,Obj path,Obj mode)
{
  int res;
  if (!IS_STRING(path) || !IS_STRING_REP(path) || !IS_INTOBJ(mode)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = mkfifo(CSTR_STRING(path),INT_INTOBJ(mode));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_DUP
static Obj FuncIO_dup(Obj self,Obj oldfd)
{
  int res;
  if (!IS_INTOBJ(oldfd)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = dup(INT_INTOBJ(oldfd));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return INTOBJ_INT(res);
  }
}
#endif

#ifdef HAVE_DUP2
static Obj FuncIO_dup2(Obj self,Obj oldfd,Obj newfd)
{
  int res;
  if (!IS_INTOBJ(oldfd) || !IS_INTOBJ(newfd)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = dup2(INT_INTOBJ(oldfd),INT_INTOBJ(newfd));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_SOCKET
static Obj FuncIO_socket(Obj self,Obj domain,Obj type,Obj protocol)
{
  int res;
#ifdef HAVE_GETPROTOBYNAME
  struct protoent *pe;
#endif
  Int proto;
  if (!IS_INTOBJ(domain) || !IS_INTOBJ(type) ||
      !(IS_INTOBJ(protocol)
#ifdef HAVE_GETPROTOBYNAME
        || (IS_STRING(protocol) && IS_STRING_REP(protocol))
#endif
       )) {
      SyClearErrorNo();
      return Fail;
  } else {
#ifdef HAVE_GETPROTOBYNAME
      if (IS_STRING(protocol)) { /* we have to look up the protocol */
           pe = getprotobyname(CSTR_STRING(protocol));
           if (pe == NULL) {
               SySetErrorNo();
               return Fail;
           }
           proto = pe->p_proto;
      } else
#endif
      proto = INT_INTOBJ(protocol);
      res = socket(INT_INTOBJ(domain),INT_INTOBJ(type),proto);
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return INTOBJ_INT(res);
  }
}
#endif

#ifdef HAVE_BIND
static Obj FuncIO_bind(Obj self,Obj fd,Obj my_addr)
{
  int res;
  Int len;
  if (!IS_INTOBJ(fd) || !IS_STRING(my_addr) || !IS_STRING_REP(my_addr)) {
      SyClearErrorNo();
      return Fail;
  } else {
      len = GET_LEN_STRING(my_addr);
      res = bind(INT_INTOBJ(fd),(struct sockaddr *)CHARS_STRING(my_addr),len);
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_CONNECT
static Obj FuncIO_connect(Obj self,Obj fd,Obj serv_addr)
{
  int res;
  Int len;
  if (!IS_INTOBJ(fd) || !IS_STRING(serv_addr) || !IS_STRING_REP(serv_addr)) {
      SyClearErrorNo();
      return Fail;
  } else {
      len = GET_LEN_STRING(serv_addr);
      res = connect(INT_INTOBJ(fd),
                    (struct sockaddr *)(CHARS_STRING(serv_addr)),len);
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_SOCKET
static Obj FuncIO_make_sockaddr_in(Obj self,Obj ip,Obj port)
{
  struct sockaddr_in sa;
  Obj res;
  if (!IS_INTOBJ(port) || !IS_STRING(ip) || !IS_STRING_REP(ip) ||
      GET_LEN_STRING(ip) != 4) {
      SyClearErrorNo();
      return Fail;
  } else {
      memset(&sa,0,sizeof(sa));
      sa.sin_family = AF_INET;
      sa.sin_port = htons(INT_INTOBJ(port));
      memcpy(&(sa.sin_addr.s_addr),CHARS_STRING(ip),4);
      res = NEW_STRING(sizeof(sa));
      memcpy(CHARS_STRING(res),&sa,sizeof(sa));
      return res;
  }
}
#endif

#ifdef HAVE_GETHOSTBYNAME
static Obj FuncIO_gethostbyname(Obj self,Obj name)
{
  struct hostent *he;
  Obj res;
  Obj tmp;
  Obj tmp2;
  char **p;
  Int i;
  Int len;
  if (!IS_STRING(name) || !IS_STRING_REP(name)) {
      SyClearErrorNo();
      return Fail;
  } else {
      he = gethostbyname(CSTR_STRING(name));
      if (he == NULL) {
          SySetErrorNo();
          return Fail;
      }
      res = NEW_PREC(0);
      tmp = MakeString(he->h_name);
      AssPRec(res,RNamName("name"),tmp);
      for (len = 0,p = he->h_aliases; *p != NULL ; len++, p++) ;
      tmp2 = NEW_PLIST(T_PLIST_DENSE,len);
      SET_LEN_PLIST(tmp2,len);
      for (i = 1,p = he->h_aliases; i <= len; i++,p++) {
          tmp = MakeString(*p);
          SET_ELM_PLIST(tmp2,i,tmp);
          CHANGED_BAG(tmp2);
      }
      AssPRec(res,RNamName("aliases"),tmp2);
      AssPRec(res,RNamName("addrtype"),INTOBJ_INT(he->h_addrtype));
      AssPRec(res,RNamName("length"),INTOBJ_INT(he->h_length));
      for (len = 0,p = he->h_addr_list; *p != NULL ; len++, p++) ;
      tmp2 = NEW_PLIST(T_PLIST_DENSE,len);
      SET_LEN_PLIST(tmp2,len);
      for (i = 1,p = he->h_addr_list; i <= len; i++,p++) {
          tmp = NEW_STRING(he->h_length);
          memcpy(CHARS_STRING(tmp), *p, he->h_length);
          SET_ELM_PLIST(tmp2,i,tmp);
          CHANGED_BAG(tmp2);
      }
      AssPRec(res,RNamName("addr"),tmp2);
      return res;
  }
}
#endif

#ifdef HAVE_LISTEN
static Obj FuncIO_listen(Obj self,Obj s,Obj backlog)
{
  int res;
  if (!IS_INTOBJ(s) || !IS_INTOBJ(backlog)) {
      SyClearErrorNo();
      return Fail;
  } else {
      res = listen(INT_INTOBJ(s),INT_INTOBJ(backlog));
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return True;
  }
}
#endif

#ifdef HAVE_ACCEPT
static Obj FuncIO_accept(Obj self,Obj fd,Obj addr)
{
  int res;
  socklen_t len;
  if (!IS_INTOBJ(fd) || !IS_STRING(addr) || !IS_STRING_REP(addr)) {
      SyClearErrorNo();
      return Fail;
  } else {
      len = GET_LEN_STRING(addr);
      res = accept(INT_INTOBJ(fd),
                   (struct sockaddr *)(CHARS_STRING(addr)),&len);
      if (res < 0) {
          SySetErrorNo();
          return Fail;
      } else
          return INTOBJ_INT(res);
  }
}
#endif

#ifdef HAVE_RECV
static Obj FuncIO_recv(Obj self,Obj fd,Obj st,Obj offset,Obj count,Obj flags)
{
  Int bytes;
  Int len;

  if (!IS_INTOBJ(fd) || !IS_STRING(st) || !IS_STRING_REP(st) ||
      !IS_INTOBJ(count) || !IS_INTOBJ(flags)) {
      SyClearErrorNo();
      return Fail;
  }

  len = INT_INTOBJ(offset)+INT_INTOBJ(count);
  if (len > GET_LEN_STRING(st)) GrowString(st,len);
  bytes = recv(INT_INTOBJ(fd),CHARS_STRING(st)+INT_INTOBJ(offset),
               INT_INTOBJ(count),INT_INTOBJ(flags));
  if (bytes < 0) {
      SySetErrorNo();
      return Fail;
  } else {
      if (bytes + INT_INTOBJ(offset) > GET_LEN_STRING(st)) {
          SET_LEN_STRING(st,bytes + INT_INTOBJ(offset));
          CHARS_STRING(st)[len] = 0;
      }
      return INTOBJ_INT(bytes);
  }
}
#endif

#ifdef HAVE_RECVFROM
static Obj FuncIO_recvfrom(Obj self,Obj fd,Obj st,Obj offset,Obj count,Obj flags,
                    Obj from)
{
  Int bytes;
  Int len;
  socklen_t fromlen;

  if (!IS_INTOBJ(fd) || !IS_STRING(st) || !IS_STRING_REP(st) ||
      !IS_INTOBJ(count) || !IS_INTOBJ(flags) || !IS_STRING(from) ||
      !IS_STRING_REP(from)) {
      SyClearErrorNo();
      return Fail;
  }

  len = INT_INTOBJ(offset)+INT_INTOBJ(count);
  if (len > GET_LEN_STRING(st)) GrowString(st,len);
  fromlen = GET_LEN_STRING(from);
  bytes = recvfrom(INT_INTOBJ(fd),CSTR_STRING(st)+INT_INTOBJ(offset),
                   INT_INTOBJ(count),INT_INTOBJ(flags),
                   (struct sockaddr *)CHARS_STRING(from),&fromlen);
  if (bytes < 0) {
      SySetErrorNo();
      return Fail;
  } else {
      if (bytes + INT_INTOBJ(offset) > GET_LEN_STRING(st)) {
          SET_LEN_STRING(st,bytes + INT_INTOBJ(offset));
          CHARS_STRING(st)[len] = 0;
      }
      return INTOBJ_INT(bytes);
  }
}
#endif

#ifdef HAVE_SEND
static Obj FuncIO_send(Obj self,Obj fd,Obj st,Obj offset,Obj count,Obj flags)
{
  Int bytes;

  if (!IS_INTOBJ(fd) || !IS_STRING(st) || !IS_STRING_REP(st) ||
      !IS_INTOBJ(offset) || !IS_INTOBJ(count) || !IS_INTOBJ(flags)) {
      SyClearErrorNo();
      return Fail;
  }
  if (GET_LEN_STRING(st) < INT_INTOBJ(offset)+INT_INTOBJ(count)) {
      SyClearErrorNo();
      return Fail;
  }
  bytes = (Int) send(INT_INTOBJ(fd),
                     CSTR_STRING(st)+INT_INTOBJ(offset),
                     INT_INTOBJ(count),INT_INTOBJ(flags));
  if (bytes < 0) {
      SySetErrorNo();
      return Fail;
  } else
      return INTOBJ_INT(bytes);
}
#endif

#ifdef HAVE_SENDTO
static Obj FuncIO_sendto(Obj self,Obj fd,Obj st,Obj offset,Obj count,Obj flags,
                  Obj to)
{
  Int bytes;
  socklen_t fromlen;

  if (!IS_INTOBJ(fd) || !IS_STRING(st) || !IS_STRING_REP(st) ||
      !IS_INTOBJ(offset) || !IS_INTOBJ(count) || !IS_INTOBJ(flags) ||
      !IS_STRING(to) || !IS_STRING_REP(to)) {
      SyClearErrorNo();
      return Fail;
  }
  if (GET_LEN_STRING(st) < INT_INTOBJ(offset)+INT_INTOBJ(count)) {
      SyClearErrorNo();
      return Fail;
  }
  fromlen = GET_LEN_STRING(to);
  bytes = (Int) sendto(INT_INTOBJ(fd),
                       CSTR_STRING(st)+INT_INTOBJ(offset),
                       INT_INTOBJ(count),INT_INTOBJ(flags),
                       (struct sockaddr *)CHARS_STRING(to),fromlen);
  if (bytes < 0) {
      SySetErrorNo();
      return Fail;
  } else
      return INTOBJ_INT(bytes);
}
#endif

#ifdef HAVE_GETSOCKOPT
static Obj FuncIO_getsockopt(Obj self,Obj fd,Obj level,Obj optname,
                      Obj optval,Obj optlen)
{
  int res;
  socklen_t olen;

  if (!IS_INTOBJ(fd) || !IS_INTOBJ(level) || !IS_INTOBJ(optname) ||
      !IS_INTOBJ(optlen) || !IS_STRING(optval) || !IS_STRING_REP(optval)) {
      SyClearErrorNo();
      return Fail;
  }
  olen = INT_INTOBJ(optlen);
  if (olen > GET_LEN_STRING(optval)) GrowString(optval,olen);
  res = (Int) getsockopt(INT_INTOBJ(fd),INT_INTOBJ(level),INT_INTOBJ(optname),
                         CSTR_STRING(optval),&olen);
  if (res < 0) {
      SySetErrorNo();
      return Fail;
  } else {
      SET_LEN_STRING(optval,olen);
      return True;
  }
}
#endif

#ifdef HAVE_SETSOCKOPT
static Obj FuncIO_setsockopt(Obj self,Obj fd,Obj level,Obj optname, Obj optval)
{
  int res;
  socklen_t olen;

  if (!IS_INTOBJ(fd) || !IS_INTOBJ(level) || !IS_INTOBJ(optname) ||
      !IS_STRING(optval) || !IS_STRING_REP(optval)) {
      SyClearErrorNo();
      return Fail;
  }
  olen = GET_LEN_STRING(optval);
  res = (Int) setsockopt(INT_INTOBJ(fd),INT_INTOBJ(level),INT_INTOBJ(optname),
                         CSTR_STRING(optval),olen);
  if (res < 0) {
      SySetErrorNo();
      return Fail;
  } else
      return True;
}
#endif

#ifdef HAVE_SELECT
static Obj FuncIO_select(Obj self, Obj inlist, Obj outlist, Obj exclist,
                  Obj timeoutsec, Obj timeoutusec)
{
  fd_set infds,outfds,excfds;
  struct timeval tv;
  int n,maxfd;
  Int i,j;
  Obj o;
  time_t t1,t2;

  if (!IS_PLIST(inlist))
    ErrorMayQuit(
           "<inlist> must be a list of small integers (not a %s)",
           (Int)TNAM_OBJ(inlist),0);
  if (!IS_PLIST(outlist))
    ErrorMayQuit(
           "<outlist> must be a list of small integers (not a %s)",
           (Int)TNAM_OBJ(outlist),0);
  if (!IS_PLIST(exclist))
    ErrorMayQuit(
           "<exclist> must be a list of small integers (not a %s)",
           (Int)TNAM_OBJ(exclist),0);

  FD_ZERO(&infds);
  FD_ZERO(&outfds);
  FD_ZERO(&excfds);
  maxfd = 0;
  /* Handle input file descriptors: */
  for (i = 1;i <= LEN_PLIST(inlist);i++) {
    o = ELM_PLIST(inlist,i);
    if (o != (Obj) 0 && IS_INTOBJ(o)) {
      j = INT_INTOBJ(o);  /* a UNIX file descriptor */
      FD_SET(j,&infds);
      if (j > maxfd) maxfd = j;
    }
  }
  /* Handle output file descriptors: */
  for (i = 1;i <= LEN_PLIST(outlist);i++) {
    o = ELM_PLIST(outlist,i);
    if (o != (Obj) 0 && IS_INTOBJ(o)) {
      j = INT_INTOBJ(o);  /* a UNIX file descriptor */
      FD_SET(j,&outfds);
      if (j > maxfd) maxfd = j;
    }
  }
  /* Handle exception file descriptors: */
  for (i = 1;i <= LEN_PLIST(exclist);i++) {
    o = ELM_PLIST(exclist,i);
    if (o != (Obj) 0 && IS_INTOBJ(o)) {
      j = INT_INTOBJ(o);  /* a UNIX file descriptor */
      FD_SET(j,&excfds);
      if (j > maxfd) maxfd = j;
    }
  }
  /* Handle the timeout: */
  if (timeoutsec != (Obj) 0 && IS_INTOBJ(timeoutsec) &&
      timeoutusec != (Obj) 0 && IS_INTOBJ(timeoutusec)) {
    tv.tv_sec = INT_INTOBJ(timeoutsec);
    tv.tv_usec = INT_INTOBJ(timeoutusec);
    while (1) {
        t1 = time(NULL);
        n = select(maxfd+1,&infds,&outfds,&excfds,&tv);
        if (n != -1 || errno != EINTR) break;
        t2 = time(NULL);
        tv.tv_sec -= (t2-t1);
        if (tv.tv_sec < 0) {
            tv.tv_sec = 0;
            tv.tv_usec = 0;
        }
    }
  } else {
    do {
        n = select(maxfd+1,&infds,&outfds,&excfds,NULL);
    } while (n == -1 && errno == EINTR);
  }

  if (n >= 0) {
    /* Now run through the lists and call functions if ready: */

    for (i = 1;i <= LEN_PLIST(inlist);i++) {
      o = ELM_PLIST(inlist,i);
      if (o != (Obj) 0 && IS_INTOBJ(o)) {
        j = INT_INTOBJ(o);  /* a UNIX file descriptor */
        if (!(FD_ISSET(j,&infds))) {
          SET_ELM_PLIST(inlist,i,Fail);
          CHANGED_BAG(inlist);
        }
      }
    }
    /* Handle output file descriptors: */
    for (i = 1;i <= LEN_PLIST(outlist);i++) {
      o = ELM_PLIST(outlist,i);
      if (o != (Obj) 0 && IS_INTOBJ(o)) {
        j = INT_INTOBJ(o);  /* a UNIX file descriptor */
        if (!(FD_ISSET(j,&outfds))) {
          SET_ELM_PLIST(outlist,i,Fail);
          CHANGED_BAG(outlist);
        }
      }
    }
    /* Handle exception file descriptors: */
    for (i = 1;i <= LEN_PLIST(exclist);i++) {
      o = ELM_PLIST(exclist,i);
      if (o != (Obj) 0 && IS_INTOBJ(o)) {
        j = INT_INTOBJ(o);  /* a UNIX file descriptor */
        if (!(FD_ISSET(j,&excfds))) {
          SET_ELM_PLIST(exclist,i,Fail);
          CHANGED_BAG(exclist);
        }
      }
    }
    return INTOBJ_INT(n);
  } else {
    SySetErrorNo();
    return Fail;
  }
}
#endif

#ifdef HAVE_FORK
static Obj FuncIO_fork(Obj self)
{
  int res;
  FuncIO_InstallSIGCHLDHandler(0);
  // Ensure files are flushed before forking
  fflush(0);
  res = fork();
  if (res == -1) {
      SySetErrorNo();
      return Fail;
  }
  #if GAP_KERNEL_MAJOR_VERSION >= 6
  if(res == 0) {
      /* In child */
      InformProfilingThatThisIsAForkedGAP();
  }
  #endif
  return INTOBJ_INT(res);
}
#endif

static Obj FuncIO_execv(Obj self,Obj path,Obj Argv)
{
    int argc;
    char *argv[1024];   /* Up to 1024 arguments */
    int i;
    Obj tmp;

    if (!IS_STRING(path) || !IS_STRING_REP(path) || !IS_PLIST(Argv)) {
        SyClearErrorNo();
        return Fail;
    }
    argv[0] = CSTR_STRING(path);
    argc = LEN_PLIST(Argv);
    if (argc > 1022) {
        Pr("#E Ignored arguments after the 1022th.\n",0,0);
        argc = 1022;
    }
    for (i = 1;i <= argc;i++) {
        tmp = ELM_PLIST(Argv,i);
        if (!IS_STRING(tmp) || !IS_STRING_REP(tmp)) {
            SyClearErrorNo();
            return Fail;
        }
        argv[i] = CSTR_STRING(tmp);
    }
    argv[i] = 0;
    i = execv(CSTR_STRING(path),argv);
    if (i == -1) {
        SySetErrorNo();
        return INTOBJ_INT(i);
    }
    /* This will never happen: */
    return Fail;
}

static Obj FuncIO_execvp(Obj self,Obj file,Obj Argv)
{
    int argc;
    char *argv[1024];   /* Up to 1024 arguments */
    int i;
    Obj tmp;

    if (!IS_STRING(file) || !IS_STRING_REP(file) || !IS_PLIST(Argv)) {
        SyClearErrorNo();
        return Fail;
    }
    argv[0] = CSTR_STRING(file);
    argc = LEN_PLIST(Argv);
    if (argc > 1022) {
        Pr("#E Ignored arguments after the 1022th.\n",0,0);
        argc = 1022;
    }
    for (i = 1;i <= argc;i++) {
        tmp = ELM_PLIST(Argv,i);
        if (!IS_STRING(tmp) || !IS_STRING_REP(tmp)) {
            SyClearErrorNo();
            return Fail;
        }
        argv[i] = CSTR_STRING(tmp);
    }
    argv[i] = 0;
    i = execvp(CSTR_STRING(file),argv);
    if (i == -1) {
        SySetErrorNo();
        return Fail;
    }
    /* This will never happen: */
    return Fail;
}

static Obj FuncIO_execve(Obj self,Obj path,Obj Argv,Obj Envp)
{
    int argc;
    char *argv[1024];   /* Up to 1024 arguments */
    char *envp[1024];   /* Up to 1024 environment entries */
    int i;
    Obj tmp;

    if (!IS_STRING(path) || !IS_STRING_REP(path) || !IS_PLIST(Argv) ||
        !IS_PLIST(Envp) ) {
        SyClearErrorNo();
        return Fail;
    }
    argv[0] = CSTR_STRING(path);
    argc = LEN_PLIST(Argv);
    if (argc > 1022) {
        Pr("#E Ignored arguments after the 1022th.\n",0,0);
        argc = 1022;
    }
    for (i = 1;i <= argc;i++) {
        tmp = ELM_PLIST(Argv,i);
        if (!IS_STRING(tmp) || !IS_STRING_REP(tmp)) {
            SyClearErrorNo();
            return Fail;
        }
        argv[i] = CSTR_STRING(tmp);
    }
    argv[i] = 0;
    argc = LEN_PLIST(Envp);
    if (argc > 1022) {
        Pr("#E Ignored environment strings after the 1022th.\n",0,0);
        argc = 1022;
    }
    for (i = 1;i <= argc;i++) {
        tmp = ELM_PLIST(Envp,i);
        if (!IS_STRING(tmp) || !IS_STRING_REP(tmp)) {
            SyClearErrorNo();
            return Fail;
        }
        envp[i-1] = CSTR_STRING(tmp);
    }
    envp[i-1] = 0;
    i = execve(CSTR_STRING(path),argv,envp);
    if (i == -1) {
        SySetErrorNo();
        return Fail;
    }
    /* This will never happen: */
    return Fail;
}

extern char **environ;

static Obj FuncIO_environ(Obj self)
{
    Int i,len;
    char **p;
    Obj tmp,tmp2;

    /* First count the entries: */
    for (len = 0,p = environ;*p;p++,len++) ;

    /* Now make a list: */
    tmp = NEW_PLIST(T_PLIST_DENSE,len);
    tmp2 = tmp;   /* Just to please the compiler */
    SET_LEN_PLIST(tmp2,len);
    for (i = 1, p = environ;i <= len;i++,p++) {
        tmp2 = MakeString(*p);
        SET_ELM_PLIST(tmp,i,tmp2);
        CHANGED_BAG(tmp);
    }
    return tmp;
}

static Obj FuncIO_pipe(Obj self)
{
    Obj tmp;
    int fds[2];
    int res;

    res = pipe(fds);
    if (res == -1) {
        SySetErrorNo();
        return Fail;
    }
    tmp = NEW_PREC(0);
    AssPRec(tmp,RNamName("toread"),INTOBJ_INT(fds[0]));
    AssPRec(tmp,RNamName("towrite"),INTOBJ_INT(fds[1]));
    return tmp;
}

static Obj FuncIO_exit(Obj self,Obj status)
{
    if (!IS_INTOBJ(status)) {
        SyClearErrorNo();
        return Fail;
    }
    exit(INT_INTOBJ(status));
    /* This never happens: */
    return True;
}

#ifdef HAVE_FCNTL_H
static Obj FuncIO_fcntl(Obj self, Obj fd, Obj cmd, Obj arg)
{
    int res;
    if (!IS_INTOBJ(fd) || !IS_INTOBJ(cmd) || !IS_INTOBJ(arg)) {
        SyClearErrorNo();
        return Fail;
    }
    res = fcntl(INT_INTOBJ(fd),INT_INTOBJ(cmd),INT_INTOBJ(arg));
    if (res == -1) {
        SySetErrorNo();
        return Fail;
    } else
        return INTOBJ_INT(res);
}
#endif

#ifdef HAVE_GETPID
static Obj FuncIO_getpid(Obj self)
{
    return INTOBJ_INT(getpid());
}
#endif

#ifdef HAVE_GETPPID
static Obj FuncIO_getppid(Obj self)
{
    return INTOBJ_INT(getppid());
}
#endif

#ifdef HAVE_KILL
static Obj FuncIO_kill(Obj self, Obj pid, Obj sig)
{
    int res;
    if (!IS_INTOBJ(pid) || !IS_INTOBJ(sig)) {
        SyClearErrorNo();
        return Fail;
    }
    res = kill((pid_t) INT_INTOBJ(pid),(int) INT_INTOBJ(sig));
    if (res == -1) {
        SySetErrorNo();
        return Fail;
    } else
        return True;
}
#endif

#ifdef HAVE_GETTIMEOFDAY
static Obj FuncIO_gettimeofday( Obj self )
{
   Obj tmp;
   struct timeval tv;
   gettimeofday(&tv, NULL);
   tmp = NEW_PREC(0);
   AssPRec(tmp, RNamName("tv_sec"), ObjInt_Int( tv.tv_sec ));
   AssPRec(tmp, RNamName("tv_usec"), ObjInt_Int( tv.tv_usec ));
   return tmp;
}
#endif

#ifdef HAVE_GMTIME
static Obj FuncIO_gmtime( Obj self, Obj time )
{
    Obj tmp;
    time_t t;
    struct tm *s;
    if (!IS_INTOBJ(time)) {
        tmp = QuoInt(time,INTOBJ_INT(256));
        if (!IS_INTOBJ(tmp)) return Fail;
        t = INT_INTOBJ(tmp)*256 + INT_INTOBJ(ModInt(time,INTOBJ_INT(256)));
    } else t = INT_INTOBJ(time);
    s = gmtime(&t);
    if (s == NULL) return Fail;
    tmp = NEW_PREC(0);
    AssPRec(tmp, RNamName("tm_sec"), INTOBJ_INT(s->tm_sec));
    AssPRec(tmp, RNamName("tm_min"), INTOBJ_INT(s->tm_min));
    AssPRec(tmp, RNamName("tm_hour"), INTOBJ_INT(s->tm_hour));
    AssPRec(tmp, RNamName("tm_mday"), INTOBJ_INT(s->tm_mday));
    AssPRec(tmp, RNamName("tm_mon"), INTOBJ_INT(s->tm_mon));
    AssPRec(tmp, RNamName("tm_year"), INTOBJ_INT(s->tm_year));
    AssPRec(tmp, RNamName("tm_wday"), INTOBJ_INT(s->tm_wday));
    AssPRec(tmp, RNamName("tm_yday"), INTOBJ_INT(s->tm_yday));
    AssPRec(tmp, RNamName("tm_isdst"), INTOBJ_INT(s->tm_isdst));
    return tmp;
}
#endif

#ifdef HAVE_LOCALTIME
static Obj FuncIO_localtime( Obj self, Obj time )
{
    Obj tmp;
    time_t t;
    struct tm *s;
    if (!IS_INTOBJ(time)) {
        tmp = QuoInt(time,INTOBJ_INT(256));
        if (!IS_INTOBJ(tmp)) return Fail;
        t = INT_INTOBJ(tmp)*256 + INT_INTOBJ(ModInt(time,INTOBJ_INT(256)));
    } else t = INT_INTOBJ(time);
    s = localtime(&t);
    if (s == NULL) return Fail;
    tmp = NEW_PREC(0);
    AssPRec(tmp, RNamName("tm_sec"), INTOBJ_INT(s->tm_sec));
    AssPRec(tmp, RNamName("tm_min"), INTOBJ_INT(s->tm_min));
    AssPRec(tmp, RNamName("tm_hour"), INTOBJ_INT(s->tm_hour));
    AssPRec(tmp, RNamName("tm_mday"), INTOBJ_INT(s->tm_mday));
    AssPRec(tmp, RNamName("tm_mon"), INTOBJ_INT(s->tm_mon));
    AssPRec(tmp, RNamName("tm_year"), INTOBJ_INT(s->tm_year));
    AssPRec(tmp, RNamName("tm_wday"), INTOBJ_INT(s->tm_wday));
    AssPRec(tmp, RNamName("tm_yday"), INTOBJ_INT(s->tm_yday));
    AssPRec(tmp, RNamName("tm_isdst"), INTOBJ_INT(s->tm_isdst));
    return tmp;
}
#endif

#ifdef HAVE_GETSOCKNAME
static Obj FuncIO_getsockname(Obj self, Obj fd)
{
  struct sockaddr_in sa;
  socklen_t sa_len;
  Obj res;
  if (!IS_INTOBJ(fd)) {
      SyClearErrorNo();
      return Fail;
  } else {
      sa_len = sizeof sa;
      getsockname (INT_INTOBJ(fd), (struct sockaddr *) (&sa), &sa_len);
      res = NEW_STRING(sa_len);
      memcpy(CHARS_STRING(res),&sa,sa_len);
      return res;
  }
}
#endif

#ifdef HAVE_GETHOSTNAME
static Obj FuncIO_gethostname(Obj self)
{
  char name[256];
  Obj res;
  int i,r;
  r = gethostname(name, 256);
  if (r < 0) {
      return Fail;
  }
  i = strlen(name);
  res = NEW_STRING(i);
  memcpy(CHARS_STRING(res),name,i);
  return res;
}
#endif



/*F * * * * * * * * * * * * * initialize package * * * * * * * * * * * * * * */

/******************************************************************************
*V  GVarFuncs . . . . . . . . . . . . . . . . . . list of functions to export
*/
static StructGVarFunc GVarFuncs [] = {

  GVAR_FUNC(IO_open, 3, "pathname, flags, mode"),
  GVAR_FUNC(IO_creat, 2, "pathname, mode"),
  GVAR_FUNC(IO_read, 4, "fd, st, offset, count"),
  GVAR_FUNC(IO_write, 4, "fd, st, offset, count"),
  GVAR_FUNC(IO_close, 1, "fd"),
  GVAR_FUNC(IO_lseek, 3, "fd, offset, whence"),
#ifdef HAVE_DIRENT_H

#ifdef HAVE_OPENDIR
  GVAR_FUNC(IO_opendir, 1, "name"),
#endif

#ifdef HAVE_READDIR
  GVAR_FUNC(IO_readdir, 0, ""),
#endif

#ifdef HAVE_REWINDDIR
  GVAR_FUNC(IO_rewinddir, 0, ""),
#endif

#ifdef HAVE_CLOSEDIR
  GVAR_FUNC(IO_closedir, 0, ""),
#endif

#ifdef HAVE_TELLDIR
  GVAR_FUNC(IO_telldir, 0, ""),
#endif

#ifdef HAVE_SEEKDIR
  GVAR_FUNC(IO_seekdir, 1, "offset"),
#endif

#endif   /* HAVE_DIRENT_H */

#ifdef HAVE_UNLINK
  GVAR_FUNC(IO_unlink, 1, "pathname"),
#endif

#ifdef HAVE_LINK
  GVAR_FUNC(IO_link, 2, "oldpath, newpath"),
#endif

#ifdef HAVE_RENAME
  GVAR_FUNC(IO_rename, 2, "oldpath, newpath"),
#endif

#ifdef HAVE_SYMLINK
  GVAR_FUNC(IO_symlink, 2, "oldpath, newpath"),
#endif

#ifdef HAVE_READLINK
  GVAR_FUNC(IO_readlink, 3, "path, buf, bufsize"),
#endif

  GVAR_FUNC(IO_realpath, 1, "path"),

#ifdef HAVE_MKDIR
  GVAR_FUNC(IO_mkdir, 2, "pathname, mode"),
#endif

  GVAR_FUNC(IO_chdir, 1, "path"),
  GVAR_FUNC(IO_getcwd, 0, ""),
#ifdef HAVE_RMDIR
  GVAR_FUNC(IO_rmdir, 1, "pathname"),
#endif

#ifdef HAVE_STAT
  GVAR_FUNC(IO_stat, 1, "pathname"),
#endif

#ifdef HAVE_FSTAT
  GVAR_FUNC(IO_fstat, 1, "fd"),
#endif

#ifdef HAVE_LSTAT
  GVAR_FUNC(IO_lstat, 1, "pathname"),
#endif

#ifdef HAVE_CHMOD
  GVAR_FUNC(IO_chmod, 2, "path, mode"),
#endif

#ifdef HAVE_FCHMOD
  GVAR_FUNC(IO_fchmod, 2, "fd, mode"),
#endif

#ifdef HAVE_CHOWN
  GVAR_FUNC(IO_chown, 3, "path, owner, group"),
#endif

#ifdef HAVE_FCHOWN
  GVAR_FUNC(IO_fchown, 3, "fd, owner, group"),
#endif

#ifdef HAVE_LCHOWN
  GVAR_FUNC(IO_lchown, 3, "path, owner, group"),
#endif

#ifdef HAVE_MKNOD
  GVAR_FUNC(IO_mknod, 3, "path, mode, dev"),
#endif

#ifdef HAVE_MKSTEMP
  GVAR_FUNC(IO_mkstemp, 1, "template"),
#endif

#ifdef HAVE_MKDTEMP
  GVAR_FUNC(IO_mkdtemp, 1, "template"),
#endif

#ifdef HAVE_MKFIFO
  GVAR_FUNC(IO_mkfifo, 2, "path, mode"),
#endif

#ifdef HAVE_DUP
  GVAR_FUNC(IO_dup, 1, "oldfd"),
#endif

#ifdef HAVE_DUP2
  GVAR_FUNC(IO_dup2, 2, "oldfd, newfd"),
#endif

#ifdef HAVE_SOCKET
  GVAR_FUNC(IO_socket, 3, "domain, type, protocol"),
#endif

#ifdef HAVE_BIND
  GVAR_FUNC(IO_bind, 2, "fd, my_addr"),
#endif

#ifdef HAVE_CONNECT
  GVAR_FUNC(IO_connect, 2, "fd, serv_addr"),
#endif

#ifdef HAVE_SOCKET
  GVAR_FUNC(IO_make_sockaddr_in, 2, "ip, port"),
#endif

#ifdef HAVE_GETHOSTBYNAME
  GVAR_FUNC(IO_gethostbyname, 1, "name"),
#endif

#ifdef HAVE_LISTEN
  GVAR_FUNC(IO_listen, 2, "s, backlog"),
#endif

#ifdef HAVE_ACCEPT
  GVAR_FUNC(IO_accept, 2, "fd, addr"),
#endif

#ifdef HAVE_RECV
  GVAR_FUNC(IO_recv, 5, "fd, st, offset, len, flags"),
#endif

#ifdef HAVE_RECVFROM
  GVAR_FUNC(IO_recvfrom, 6, "fd, st, offset, len, flags, from"),
#endif

#ifdef HAVE_SEND
  GVAR_FUNC(IO_send, 5, "fd, st, offset, len, flags"),
#endif

#ifdef HAVE_SENDTO
  GVAR_FUNC(IO_sendto, 6, "fd, st, offset, len, flags, to"),
#endif

#ifdef HAVE_GETSOCKOPT
  GVAR_FUNC(IO_getsockopt, 5, "fd, level, optname, optval, optlen"),
#endif

#ifdef HAVE_SETSOCKOPT
  GVAR_FUNC(IO_setsockopt, 4, "fd, level, optname, optval"),
#endif

#ifdef HAVE_SELECT
  GVAR_FUNC(IO_select, 5, "inlist, outlist, exclist, timeoutsec, timeoutusec"),
#endif

  GVAR_FUNC(IO_IgnorePid, 1, "pid"),
#if defined(HAVE_SIGACTION) || defined(HAVE_SIGNAL)
  GVAR_FUNC(IO_WaitPid, 2, "pid, wait"),
#endif

#ifdef HAVE_FORK
  GVAR_FUNC(IO_fork, 0, ""),
#endif

  GVAR_FUNC(IO_execv, 2, "path, argv"),
  GVAR_FUNC(IO_execvp, 2, "path, argv"),
  GVAR_FUNC(IO_execve, 3, "path, argv, envp"),
  GVAR_FUNC(IO_environ, 0, ""),
#ifdef HAVE_SIGNAL
  GVAR_FUNC(IO_InstallSIGCHLDHandler, 0, ""),
  GVAR_FUNC(IO_RestoreSIGCHLDHandler, 0, ""),
#endif

  GVAR_FUNC(IO_pipe, 0, ""),
  GVAR_FUNC(IO_exit, 1, "status"),
#ifdef HAVE_FCNTL_H
  GVAR_FUNC(IO_fcntl, 3, "fd, cmd, arg"),
#endif

#ifdef HAVE_GETPID
  GVAR_FUNC(IO_getpid, 0, ""),
#endif

#ifdef HAVE_GETPPID
  GVAR_FUNC(IO_getppid, 0, ""),
#endif

#ifdef HAVE_KILL
  GVAR_FUNC(IO_kill, 2, "pid, sig"),
#endif

#ifdef HAVE_GETTIMEOFDAY
  GVAR_FUNC(IO_gettimeofday, 0, ""),
#endif

#ifdef HAVE_GMTIME
  GVAR_FUNC(IO_gmtime, 1, "seconds"),
#endif

#ifdef HAVE_LOCALTIME
  GVAR_FUNC(IO_localtime, 1, "seconds"),
#endif

#ifdef HAVE_GETSOCKNAME
  GVAR_FUNC(IO_getsockname, 1, "fd"),
#endif

#ifdef HAVE_GETHOSTNAME
  GVAR_FUNC(IO_gethostname, 0, ""),
#endif

  { 0 }

};

/******************************************************************************
*F  InitKernel( <module> )  . . . . . . . . initialise kernel data structures
*/
static Int InitKernel ( StructInitInfo *module )
{
    /* init filters and functions                                          */
    InitHdlrFuncsFromTable( GVarFuncs );

    /* return success                                                      */
    return 0;
}

/******************************************************************************
*F  InitLibrary( <module> ) . . . . . . .  initialise library data structures
*/
static Int InitLibrary ( StructInitInfo *module )
{
    Int             gvar;
    Obj             tmp;

    /* init filters and functions
       we assign the functions to components of a record "IO"         */
    InitGVarFuncsFromTable(GVarFuncs);

    tmp = NEW_PREC(0);
    /* Constants for the flags: */
    AssPRec(tmp, RNamName("O_RDONLY"), INTOBJ_INT((Int) O_RDONLY));
    AssPRec(tmp, RNamName("O_WRONLY"), INTOBJ_INT((Int) O_WRONLY));
    AssPRec(tmp, RNamName("O_RDWR"), INTOBJ_INT((Int) O_RDWR));
#ifdef O_CREAT
    AssPRec(tmp, RNamName("O_CREAT"), INTOBJ_INT((Int) O_CREAT));
#endif
#ifdef O_APPEND
    AssPRec(tmp, RNamName("O_APPEND"), INTOBJ_INT((Int) O_APPEND));
#endif
#ifdef O_ASYNC
    AssPRec(tmp, RNamName("O_ASYNC"), INTOBJ_INT((Int) O_ASYNC));
#endif
#ifdef O_DIRECT
    AssPRec(tmp, RNamName("O_DIRECT"), INTOBJ_INT((Int) O_DIRECT));
#endif
#ifdef O_DIRECTORY
    AssPRec(tmp, RNamName("O_DIRECTORY"), INTOBJ_INT((Int) O_DIRECTORY));
#endif
#ifdef O_EXCL
    AssPRec(tmp, RNamName("O_EXCL"), INTOBJ_INT((Int) O_EXCL));
#endif
#ifdef O_LARGEFILE
    AssPRec(tmp, RNamName("O_LARGEFILE"), INTOBJ_INT((Int) O_LARGEFILE));
#endif
#ifdef O_NOATIME
    AssPRec(tmp, RNamName("O_NOATIME"), INTOBJ_INT((Int) O_NOATIME));
#endif
#ifdef O_NOCTTY
    AssPRec(tmp, RNamName("O_NOCTTY"), INTOBJ_INT((Int) O_NOCTTY));
#endif
#ifdef O_NOFOLLOW
    AssPRec(tmp, RNamName("O_NOFOLLOW"), INTOBJ_INT((Int) O_NOFOLLOW));
#endif
#ifdef O_NONBLOCK
    AssPRec(tmp, RNamName("O_NONBLOCK"), INTOBJ_INT((Int) O_NONBLOCK));
#endif
#ifdef O_NDELAY
    AssPRec(tmp, RNamName("O_NDELAY"), INTOBJ_INT((Int) O_NDELAY));
#endif
#ifdef O_SYNC
    AssPRec(tmp, RNamName("O_SYNC"), INTOBJ_INT((Int) O_SYNC));
#endif
#ifdef O_TRUNC
    AssPRec(tmp, RNamName("O_TRUNC"), INTOBJ_INT((Int) O_TRUNC));
#endif
#ifdef SEEK_SET
    AssPRec(tmp, RNamName("SEEK_SET"), INTOBJ_INT((Int) SEEK_SET));
#endif
#ifdef SEEK_CUR
    AssPRec(tmp, RNamName("SEEK_CUR"), INTOBJ_INT((Int) SEEK_CUR));
#endif
#ifdef SEEK_END
    AssPRec(tmp, RNamName("SEEK_END"), INTOBJ_INT((Int) SEEK_END));
#endif

    /* Constants for the mode: */
#ifdef S_IRWXU
    AssPRec(tmp, RNamName("S_IRWXU"), INTOBJ_INT((Int) S_IRWXU));
#endif
#ifdef S_IRUSR
    AssPRec(tmp, RNamName("S_IRUSR"), INTOBJ_INT((Int) S_IRUSR));
#endif
#ifdef S_IWUSR
    AssPRec(tmp, RNamName("S_IWUSR"), INTOBJ_INT((Int) S_IWUSR));
#endif
#ifdef S_IXUSR
    AssPRec(tmp, RNamName("S_IXUSR"), INTOBJ_INT((Int) S_IXUSR));
#endif
#ifdef S_IRWXG
    AssPRec(tmp, RNamName("S_IRWXG"), INTOBJ_INT((Int) S_IRWXG));
#endif
#ifdef S_IRGRP
    AssPRec(tmp, RNamName("S_IRGRP"), INTOBJ_INT((Int) S_IRGRP));
#endif
#ifdef S_IWGRP
    AssPRec(tmp, RNamName("S_IWGRP"), INTOBJ_INT((Int) S_IWGRP));
#endif
#ifdef S_IXGRP
    AssPRec(tmp, RNamName("S_IXGRP"), INTOBJ_INT((Int) S_IXGRP));
#endif
#ifdef S_IRWXO
    AssPRec(tmp, RNamName("S_IRWXO"), INTOBJ_INT((Int) S_IRWXO));
#endif
#ifdef S_IROTH
    AssPRec(tmp, RNamName("S_IROTH"), INTOBJ_INT((Int) S_IROTH));
#endif
#ifdef S_IWOTH
    AssPRec(tmp, RNamName("S_IWOTH"), INTOBJ_INT((Int) S_IWOTH));
#endif
#ifdef S_IXOTH
    AssPRec(tmp, RNamName("S_IXOTH"), INTOBJ_INT((Int) S_IXOTH));
#endif
#ifdef S_IFMT
    AssPRec(tmp, RNamName("S_IFMT"), INTOBJ_INT((Int) S_IFMT));
#endif
#ifdef S_IFSOCK
    AssPRec(tmp, RNamName("S_IFSOCK"), INTOBJ_INT((Int) S_IFSOCK));
#endif
#ifdef S_IFLNK
    AssPRec(tmp, RNamName("S_IFLNK"), INTOBJ_INT((Int) S_IFLNK));
#endif
#ifdef S_IFREG
    AssPRec(tmp, RNamName("S_IFREG"), INTOBJ_INT((Int) S_IFREG));
#endif
#ifdef S_IFBLK
    AssPRec(tmp, RNamName("S_IFBLK"), INTOBJ_INT((Int) S_IFBLK));
#endif
#ifdef S_IFDIR
    AssPRec(tmp, RNamName("S_IFDIR"), INTOBJ_INT((Int) S_IFDIR));
#endif
#ifdef S_IFCHR
    AssPRec(tmp, RNamName("S_IFCHR"), INTOBJ_INT((Int) S_IFCHR));
#endif
#ifdef S_IFIFO
    AssPRec(tmp, RNamName("S_IFIFO"), INTOBJ_INT((Int) S_IFIFO));
#endif
#ifdef S_ISUID
    AssPRec(tmp, RNamName("S_ISUID"), INTOBJ_INT((Int) S_ISUID));
#endif
#ifdef S_ISGID
    AssPRec(tmp, RNamName("S_ISGID"), INTOBJ_INT((Int) S_ISGID));
#endif
#ifdef S_ISVTX
    AssPRec(tmp, RNamName("S_ISVTX"), INTOBJ_INT((Int) S_ISVTX));
#endif

    /* Constants for the errors: */
#ifdef EACCES
    AssPRec(tmp, RNamName("EACCES"), INTOBJ_INT((Int) EACCES));
#endif
#ifdef EEXIST
    AssPRec(tmp, RNamName("EEXIST"), INTOBJ_INT((Int) EEXIST));
#endif
#ifdef EFAULT
    AssPRec(tmp, RNamName("EFAULT"), INTOBJ_INT((Int) EFAULT));
#endif
#ifdef EISDIR
    AssPRec(tmp, RNamName("EISDIR"), INTOBJ_INT((Int) EISDIR));
#endif
#ifdef ELOOP
    AssPRec(tmp, RNamName("ELOOP"), INTOBJ_INT((Int) ELOOP));
#endif
#ifdef EMFILE
    AssPRec(tmp, RNamName("EMFILE"), INTOBJ_INT((Int) EMFILE));
#endif
#ifdef ENAMETOOLONG
    AssPRec(tmp, RNamName("ENAMETOOLONG"), INTOBJ_INT((Int) ENAMETOOLONG));
#endif
#ifdef ENFILE
    AssPRec(tmp, RNamName("ENFILE"), INTOBJ_INT((Int) ENFILE));
#endif
#ifdef ENODEV
    AssPRec(tmp, RNamName("ENODEV"), INTOBJ_INT((Int) ENODEV));
#endif
#ifdef ENOENT
    AssPRec(tmp, RNamName("ENOENT"), INTOBJ_INT((Int) ENOENT));
#endif
#ifdef ENOMEM
    AssPRec(tmp, RNamName("ENOMEM"), INTOBJ_INT((Int) ENOMEM));
#endif
#ifdef ENOSPC
    AssPRec(tmp, RNamName("ENOSPC"), INTOBJ_INT((Int) ENOSPC));
#endif
#ifdef ENOTDIR
    AssPRec(tmp, RNamName("ENOTDIR"), INTOBJ_INT((Int) ENOTDIR));
#endif
#ifdef ENXIO
    AssPRec(tmp, RNamName("ENXIO"), INTOBJ_INT((Int) ENXIO));
#endif
#ifdef EOVERFLOW
    AssPRec(tmp, RNamName("EOVERFLOW"), INTOBJ_INT((Int) EOVERFLOW));
#endif
#ifdef EPERM
    AssPRec(tmp, RNamName("EPERM"), INTOBJ_INT((Int) EPERM));
#endif
#ifdef EROFS
    AssPRec(tmp, RNamName("EROFS"), INTOBJ_INT((Int) EROFS));
#endif
#ifdef ETXTBSY
    AssPRec(tmp, RNamName("ETXTBSY"), INTOBJ_INT((Int) ETXTBSY));
#endif
#ifdef EAGAIN
    AssPRec(tmp, RNamName("EAGAIN"), INTOBJ_INT((Int) EAGAIN));
#endif
#ifdef EBADF
    AssPRec(tmp, RNamName("EBADF"), INTOBJ_INT((Int) EBADF));
#endif
#ifdef EINTR
    AssPRec(tmp, RNamName("EINTR"), INTOBJ_INT((Int) EINTR));
#endif
#ifdef EINVAL
    AssPRec(tmp, RNamName("EINVAL"), INTOBJ_INT((Int) EINVAL));
#endif
#ifdef EIO
    AssPRec(tmp, RNamName("EIO"), INTOBJ_INT((Int) EIO));
#endif
#ifdef EFBIG
    AssPRec(tmp, RNamName("EFBIG"), INTOBJ_INT((Int) EFBIG));
#endif
#ifdef ENOSPC
    AssPRec(tmp, RNamName("ENOSPC"), INTOBJ_INT((Int) ENOSPC));
#endif
#ifdef EPIPE
    AssPRec(tmp, RNamName("EPIPE"), INTOBJ_INT((Int) EPIPE));
#endif
#ifdef EBUSY
    AssPRec(tmp, RNamName("EBUSY"), INTOBJ_INT((Int) EBUSY));
#endif
#ifdef ESPIPE
    AssPRec(tmp, RNamName("ESPIPE"), INTOBJ_INT((Int) ESPIPE));
#endif
#ifdef EMLINK
    AssPRec(tmp, RNamName("EMLINK"), INTOBJ_INT((Int) EMLINK));
#endif
#ifdef EXDEV
    AssPRec(tmp, RNamName("EXDEV"), INTOBJ_INT((Int) EXDEV));
#endif
#ifdef ENOTEMPTY
    AssPRec(tmp, RNamName("ENOTEMPTY"), INTOBJ_INT((Int) ENOTEMPTY));
#endif
#ifdef EAFNOSUPPORT
    AssPRec(tmp, RNamName("EAFNOSUPPORT"), INTOBJ_INT((Int) EAFNOSUPPORT));
#endif
#ifdef ENOBUGS
    AssPRec(tmp, RNamName("ENOBUGS"), INTOBJ_INT((Int) ENOBUGS));
#endif
#ifdef EPROTONOSUPPORT
    AssPRec(tmp, RNamName("EPROTONOSUPPORT"),INTOBJ_INT((Int) EPROTONOSUPPORT));
#endif
#ifdef ENOTSOCK
    AssPRec(tmp, RNamName("ENOTSOCK"),INTOBJ_INT((Int) ENOTSOCK));
#endif
#ifdef EADDRINUSE
    AssPRec(tmp, RNamName("EADDRINUSE"), INTOBJ_INT((Int) EADDRINUSE));
#endif
#ifdef EALREADY
    AssPRec(tmp, RNamName("EALREADY"), INTOBJ_INT((Int) EALREADY));
#endif
#ifdef ECONNREFUSED
    AssPRec(tmp, RNamName("ECONNREFUSED"), INTOBJ_INT((Int) ECONNREFUSED));
#endif
#ifdef EINPROGRESS
    AssPRec(tmp, RNamName("EINPROGRESS"), INTOBJ_INT((Int) EINPROGRESS));
#endif
#ifdef EISCONN
    AssPRec(tmp, RNamName("EISCONN"), INTOBJ_INT((Int) EISCONN));
#endif
#ifdef ETIMEDOUT
    AssPRec(tmp, RNamName("ETIMEDOUT"), INTOBJ_INT((Int) ETIMEDOUT));
#endif
#ifdef EOPNOTSUPP
    AssPRec(tmp, RNamName("EOPNOTSUPP"), INTOBJ_INT((Int) EOPNOTSUPP));
#endif
#ifdef EPROTO
    AssPRec(tmp, RNamName("EPROTO"), INTOBJ_INT((Int) EPROTO));
#endif
#ifdef ECONNABORTED
    AssPRec(tmp, RNamName("ECONNABORTED"), INTOBJ_INT((Int) ECONNABORTED));
#endif
#ifdef ECHILD
    AssPRec(tmp, RNamName("ECHILD"), INTOBJ_INT((Int) ECHILD));
#endif
#ifdef EWOULDBLOCK
    AssPRec(tmp, RNamName("EWOULDBLOCK"), INTOBJ_INT((Int) EWOULDBLOCK));
#endif
#ifdef HOST_NOT_FOUND
    AssPRec(tmp, RNamName("HOST_NOT_FOUND"), INTOBJ_INT((Int) HOST_NOT_FOUND));
#endif
#ifdef NO_ADDRESS
    AssPRec(tmp, RNamName("NO_ADDRESS"), INTOBJ_INT((Int) NO_ADDRESS));
#endif
#ifdef NO_DATA
    AssPRec(tmp, RNamName("NO_DATA"), INTOBJ_INT((Int) NO_DATA));
#endif
#ifdef NO_RECOVERY
    AssPRec(tmp, RNamName("NO_RECOVERY"), INTOBJ_INT((Int) NO_RECOVERY));
#endif
#ifdef TRY_AGAIN
    AssPRec(tmp, RNamName("TRY_AGAIN"), INTOBJ_INT((Int) TRY_AGAIN));
#endif

    /* Constants for networking: */
#ifdef AF_APPLETALK
    AssPRec(tmp, RNamName("AF_APPLETALK"), INTOBJ_INT((Int) AF_APPLETALK));
#endif
#ifdef AF_ASH
    AssPRec(tmp, RNamName("AF_ASH"), INTOBJ_INT((Int) AF_ASH));
#endif
#ifdef AF_ATMPVC
    AssPRec(tmp, RNamName("AF_ATMPVC"), INTOBJ_INT((Int) AF_ATMPVC));
#endif
#ifdef AF_ATMSVC
    AssPRec(tmp, RNamName("AF_ATMSVC"), INTOBJ_INT((Int) AF_ATMSVC));
#endif
#ifdef AF_AX25
    AssPRec(tmp, RNamName("AF_AX25"), INTOBJ_INT((Int) AF_AX25));
#endif
#ifdef AF_BLUETOOTH
    AssPRec(tmp, RNamName("AF_BLUETOOTH"), INTOBJ_INT((Int) AF_BLUETOOTH));
#endif
#ifdef AF_BRIDGE
    AssPRec(tmp, RNamName("AF_BRIDGE"), INTOBJ_INT((Int) AF_BRIDGE));
#endif
#ifdef AF_DECnet
    AssPRec(tmp, RNamName("AF_DECnet"), INTOBJ_INT((Int) AF_DECnet));
#endif
#ifdef AF_ECONET
    AssPRec(tmp, RNamName("AF_ECONET"), INTOBJ_INT((Int) AF_ECONET));
#endif
#ifdef AF_FILE
    AssPRec(tmp, RNamName("AF_FILE"), INTOBJ_INT((Int) AF_FILE));
#endif
#ifdef AF_INET
    AssPRec(tmp, RNamName("AF_INET"), INTOBJ_INT((Int) AF_INET));
#endif
#ifdef AF_INET6
    AssPRec(tmp, RNamName("AF_INET6"), INTOBJ_INT((Int) AF_INET6));
#endif
#ifdef AF_IPX
    AssPRec(tmp, RNamName("AF_IPX"), INTOBJ_INT((Int) AF_IPX));
#endif
#ifdef AF_IRDA
    AssPRec(tmp, RNamName("AF_IRDA"), INTOBJ_INT((Int) AF_IRDA));
#endif
#ifdef AF_KEY
    AssPRec(tmp, RNamName("AF_KEY"), INTOBJ_INT((Int) AF_KEY));
#endif
#ifdef AF_LOCAL
    AssPRec(tmp, RNamName("AF_LOCAL"), INTOBJ_INT((Int) AF_LOCAL));
#endif
#ifdef AF_MAX
    AssPRec(tmp, RNamName("AF_MAX"), INTOBJ_INT((Int) AF_MAX));
#endif
#ifdef AF_NETBEUI
    AssPRec(tmp, RNamName("AF_NETBEUI"), INTOBJ_INT((Int) AF_NETBEUI));
#endif
#ifdef AF_NETLINK
    AssPRec(tmp, RNamName("AF_NETLINK"), INTOBJ_INT((Int) AF_NETLINK));
#endif
#ifdef AF_NETROM
    AssPRec(tmp, RNamName("AF_NETROM"), INTOBJ_INT((Int) AF_NETROM));
#endif
#ifdef AF_PACKET
    AssPRec(tmp, RNamName("AF_PACKET"), INTOBJ_INT((Int) AF_PACKET));
#endif
#ifdef AF_PPPOX
    AssPRec(tmp, RNamName("AF_PPPOX"), INTOBJ_INT((Int) AF_PPPOX));
#endif
#ifdef AF_ROSE
    AssPRec(tmp, RNamName("AF_ROSE"), INTOBJ_INT((Int) AF_ROSE));
#endif
#ifdef AF_ROUTE
    AssPRec(tmp, RNamName("AF_ROUTE"), INTOBJ_INT((Int) AF_ROUTE));
#endif
#ifdef AF_SECURITY
    AssPRec(tmp, RNamName("AF_SECURITY"), INTOBJ_INT((Int) AF_SECURITY));
#endif
#ifdef AF_SNA
    AssPRec(tmp, RNamName("AF_SNA"), INTOBJ_INT((Int) AF_SNA));
#endif
#ifdef AF_UNIX
    AssPRec(tmp, RNamName("AF_UNIX"), INTOBJ_INT((Int) AF_UNIX));
#endif
#ifdef AF_UNSPEC
    AssPRec(tmp, RNamName("AF_UNSPEC"), INTOBJ_INT((Int) AF_UNSPEC));
#endif
#ifdef AF_WANPIPE
    AssPRec(tmp, RNamName("AF_WANPIPE"), INTOBJ_INT((Int) AF_WANPIPE));
#endif
#ifdef AF_X25
    AssPRec(tmp, RNamName("AF_X25"), INTOBJ_INT((Int) AF_X25));
#endif
#ifdef PF_APPLETALK
    AssPRec(tmp, RNamName("PF_APPLETALK"), INTOBJ_INT((Int) PF_APPLETALK));
#endif
#ifdef PF_ASH
    AssPRec(tmp, RNamName("PF_ASH"), INTOBJ_INT((Int) PF_ASH));
#endif
#ifdef PF_ATMPVC
    AssPRec(tmp, RNamName("PF_ATMPVC"), INTOBJ_INT((Int) PF_ATMPVC));
#endif
#ifdef PF_ATMSVC
    AssPRec(tmp, RNamName("PF_ATMSVC"), INTOBJ_INT((Int) PF_ATMSVC));
#endif
#ifdef PF_AX25
    AssPRec(tmp, RNamName("PF_AX25"), INTOBJ_INT((Int) PF_AX25));
#endif
#ifdef PF_BLUETOOTH
    AssPRec(tmp, RNamName("PF_BLUETOOTH"), INTOBJ_INT((Int) PF_BLUETOOTH));
#endif
#ifdef PF_BRIDGE
    AssPRec(tmp, RNamName("PF_BRIDGE"), INTOBJ_INT((Int) PF_BRIDGE));
#endif
#ifdef PF_DECnet
    AssPRec(tmp, RNamName("PF_DECnet"), INTOBJ_INT((Int) PF_DECnet));
#endif
#ifdef PF_ECONET
    AssPRec(tmp, RNamName("PF_ECONET"), INTOBJ_INT((Int) PF_ECONET));
#endif
#ifdef PF_FILE
    AssPRec(tmp, RNamName("PF_FILE"), INTOBJ_INT((Int) PF_FILE));
#endif
#ifdef PF_INET
    AssPRec(tmp, RNamName("PF_INET"), INTOBJ_INT((Int) PF_INET));
#endif
#ifdef PF_INET6
    AssPRec(tmp, RNamName("PF_INET6"), INTOBJ_INT((Int) PF_INET6));
#endif
#ifdef PF_IPX
    AssPRec(tmp, RNamName("PF_IPX"), INTOBJ_INT((Int) PF_IPX));
#endif
#ifdef PF_IRDA
    AssPRec(tmp, RNamName("PF_IRDA"), INTOBJ_INT((Int) PF_IRDA));
#endif
#ifdef PF_KEY
    AssPRec(tmp, RNamName("PF_KEY"), INTOBJ_INT((Int) PF_KEY));
#endif
#ifdef PF_LOCAL
    AssPRec(tmp, RNamName("PF_LOCAL"), INTOBJ_INT((Int) PF_LOCAL));
#endif
#ifdef PF_MAX
    AssPRec(tmp, RNamName("PF_MAX"), INTOBJ_INT((Int) PF_MAX));
#endif
#ifdef PF_NETBEUI
    AssPRec(tmp, RNamName("PF_NETBEUI"), INTOBJ_INT((Int) PF_NETBEUI));
#endif
#ifdef PF_NETLINK
    AssPRec(tmp, RNamName("PF_NETLINK"), INTOBJ_INT((Int) PF_NETLINK));
#endif
#ifdef PF_NETROM
    AssPRec(tmp, RNamName("PF_NETROM"), INTOBJ_INT((Int) PF_NETROM));
#endif
#ifdef PF_PACKET
    AssPRec(tmp, RNamName("PF_PACKET"), INTOBJ_INT((Int) PF_PACKET));
#endif
#ifdef PF_PPPOX
    AssPRec(tmp, RNamName("PF_PPPOX"), INTOBJ_INT((Int) PF_PPPOX));
#endif
#ifdef PF_ROSE
    AssPRec(tmp, RNamName("PF_ROSE"), INTOBJ_INT((Int) PF_ROSE));
#endif
#ifdef PF_ROUTE
    AssPRec(tmp, RNamName("PF_ROUTE"), INTOBJ_INT((Int) PF_ROUTE));
#endif
#ifdef PF_SECURITY
    AssPRec(tmp, RNamName("PF_SECURITY"), INTOBJ_INT((Int) PF_SECURITY));
#endif
#ifdef PF_SNA
    AssPRec(tmp, RNamName("PF_SNA"), INTOBJ_INT((Int) PF_SNA));
#endif
#ifdef PF_UNIX
    AssPRec(tmp, RNamName("PF_UNIX"), INTOBJ_INT((Int) PF_UNIX));
#endif
#ifdef PF_WANPIPE
    AssPRec(tmp, RNamName("PF_WANPIPE"), INTOBJ_INT((Int) PF_WANPIPE));
#endif
#ifdef PF_X25
    AssPRec(tmp, RNamName("PF_X25"), INTOBJ_INT((Int) PF_X25));
#endif
#ifdef SOCK_DGRAM
    AssPRec(tmp, RNamName("SOCK_DGRAM"), INTOBJ_INT((Int) SOCK_DGRAM));
#endif
#ifdef SOCK_PACKET
    AssPRec(tmp, RNamName("SOCK_PACKET"), INTOBJ_INT((Int) SOCK_PACKET));
#endif
#ifdef SOCK_RAW
    AssPRec(tmp, RNamName("SOCK_RAW"), INTOBJ_INT((Int) SOCK_RAW));
#endif
#ifdef SOCK_RDM
    AssPRec(tmp, RNamName("SOCK_RDM"), INTOBJ_INT((Int) SOCK_RDM));
#endif
#ifdef SOCK_SEQPACKET
    AssPRec(tmp, RNamName("SOCK_SEQPACKET"), INTOBJ_INT((Int) SOCK_SEQPACKET));
#endif
#ifdef SOCK_STREAM
    AssPRec(tmp, RNamName("SOCK_STREAM"), INTOBJ_INT((Int) SOCK_STREAM));
#endif
#ifdef SOL_SOCKET
    AssPRec(tmp, RNamName("SOL_SOCKET"), INTOBJ_INT((Int) SOL_SOCKET));
#endif
#ifdef IP_OPTIONS
    AssPRec(tmp, RNamName("IP_OPTIONS"), INTOBJ_INT((Int) IP_OPTIONS));
#endif
#ifdef IP_PKTINFO
    AssPRec(tmp, RNamName("IP_PKTINFO"), INTOBJ_INT((Int) IP_PKTINFO));
#endif
#ifdef IP_RECVTOS
    AssPRec(tmp, RNamName("IP_RECVTOS"), INTOBJ_INT((Int) IP_RECVTOS));
#endif
#ifdef IP_RECVTTL
    AssPRec(tmp, RNamName("IP_RECVTTL"), INTOBJ_INT((Int) IP_RECVTTL));
#endif
#ifdef IP_RECVOPTS
    AssPRec(tmp, RNamName("IP_RECVOPTS"), INTOBJ_INT((Int) IP_RECVOPTS));
#endif
#ifdef IP_RETOPTS
    AssPRec(tmp, RNamName("IP_RETOPTS"), INTOBJ_INT((Int) IP_RETOPTS));
#endif
#ifdef IP_TOS
    AssPRec(tmp, RNamName("IP_TOS"), INTOBJ_INT((Int) IP_TOS));
#endif
#ifdef IP_TTL
    AssPRec(tmp, RNamName("IP_TTL"), INTOBJ_INT((Int) IP_TTL));
#endif
#ifdef IP_HDRINCL
    AssPRec(tmp, RNamName("IP_HDRINCL"), INTOBJ_INT((Int) IP_HDRINCL));
#endif
#ifdef IP_RECVERR
    AssPRec(tmp, RNamName("IP_RECVERR"), INTOBJ_INT((Int) IP_RECVERR));
#endif
#ifdef IP_MTU_DISCOVER
    AssPRec(tmp, RNamName("IP_MTU_DISCOVER"),
                 INTOBJ_INT((Int) IP_MTU_DISCOVER));
#endif
#ifdef IP_MTU
    AssPRec(tmp, RNamName("IP_MTU"), INTOBJ_INT((Int) IP_MTU));
#endif
#ifdef IP_ROUTER_ALERT
    AssPRec(tmp, RNamName("IP_ROUTER_ALERT"),
                 INTOBJ_INT((Int) IP_ROUTER_ALERT));
#endif
#ifdef IP_MULTICAST_TTL
    AssPRec(tmp, RNamName("IP_MULTICAST_TTL"),
                 INTOBJ_INT((Int) IP_MULTICAST_TTL));
#endif
#ifdef IP_MULTICAST_LOOP
    AssPRec(tmp, RNamName("IP_MULTICAST_LOOP"),
                 INTOBJ_INT((Int) IP_MULTICAST_LOOP));
#endif
#ifdef IP_ADD_MEMBERSHIP
    AssPRec(tmp, RNamName("IP_ADD_MEMBERSHIP"),
                 INTOBJ_INT((Int) IP_ADD_MEMBERSHIP));
#endif
#ifdef IP_DROP_MEMBERSHIP
    AssPRec(tmp, RNamName("IP_DROP_MEMBERSHIP"),
                 INTOBJ_INT((Int)IP_DROP_MEMBERSHIP));
#endif
#ifdef IP_MULTICAST_IF
    AssPRec(tmp, RNamName("IP_MULTICAST_IF"),INTOBJ_INT((Int) IP_MULTICAST_IF));
#endif
#ifdef SO_RCVBUF
    AssPRec(tmp, RNamName("SO_RCVBUF"), INTOBJ_INT((Int) SO_RCVBUF));
#endif
#ifdef SO_SNDBUF
    AssPRec(tmp, RNamName("SO_SNDBUF"), INTOBJ_INT((Int) SO_SNDBUF));
#endif
#ifdef SO_SNDLOWAT
    AssPRec(tmp, RNamName("SO_SNDLOWAT"), INTOBJ_INT((Int) SO_SNDLOWAT));
#endif
#ifdef SO_RCVLOWAT
    AssPRec(tmp, RNamName("SO_RCVLOWAT"), INTOBJ_INT((Int) SO_RCVLOWAT));
#endif
#ifdef SO_SNDTIMEO
    AssPRec(tmp, RNamName("SO_SNDTIMEO"), INTOBJ_INT((Int) SO_SNDTIMEO));
#endif
#ifdef SO_RCVTIMEO
    AssPRec(tmp, RNamName("SO_RCVTIMEO"), INTOBJ_INT((Int) SO_RCVTIMEO));
#endif
#ifdef SO_REUSEADDR
    AssPRec(tmp, RNamName("SO_REUSEADDR"), INTOBJ_INT((Int) SO_REUSEADDR));
#endif
#ifdef SO_KEEPALIVE
    AssPRec(tmp, RNamName("SO_KEEPALIVE"), INTOBJ_INT((Int) SO_KEEPALIVE));
#endif
#ifdef SO_OOBINLINE
    AssPRec(tmp, RNamName("SO_OOBINLINE"), INTOBJ_INT((Int) SO_OOBINLINE));
#endif
#ifdef SO_BSDCOMPAT
    AssPRec(tmp, RNamName("SO_BSDCOMPAT"), INTOBJ_INT((Int) SO_BSDCOMPAT));
#endif
#ifdef SO_PASSCRED
    AssPRec(tmp, RNamName("SO_PASSCRED"), INTOBJ_INT((Int) SO_PASSCRED));
#endif
#ifdef SO_PEERCRED
    AssPRec(tmp, RNamName("SO_PEERCRED"), INTOBJ_INT((Int) SO_PEERCRED));
#endif
#ifdef SO_BINDTODEVICE
    AssPRec(tmp, RNamName("SO_BINDTODEVICE"),INTOBJ_INT((Int) SO_BINDTODEVICE));
#endif
#ifdef SO_DEBUG
    AssPRec(tmp, RNamName("SO_DEBUG"), INTOBJ_INT((Int) SO_DEBUG));
#endif
#ifdef SO_TYPE
    AssPRec(tmp, RNamName("SO_TYPE"), INTOBJ_INT((Int) SO_TYPE));
#endif
#ifdef SO_ACCEPTCONN
    AssPRec(tmp, RNamName("SO_ACCEPTCONN"), INTOBJ_INT((Int) SO_ACCEPTCONN));
#endif
#ifdef SO_DONTROUTE
    AssPRec(tmp, RNamName("SO_DONTROUTE"), INTOBJ_INT((Int) SO_DONTROUTE));
#endif
#ifdef SO_BROADCAST
    AssPRec(tmp, RNamName("SO_BROADCAST"), INTOBJ_INT((Int) SO_BROADCAST));
#endif
#ifdef SO_LINGER
    AssPRec(tmp, RNamName("SO_LINGER"), INTOBJ_INT((Int) SO_LINGER));
#endif
#ifdef SO_PRIORITY
    AssPRec(tmp, RNamName("SO_PRIORITY"), INTOBJ_INT((Int) SO_PRIORITY));
#endif
#ifdef SO_ERROR
    AssPRec(tmp, RNamName("SO_ERROR"), INTOBJ_INT((Int) SO_ERROR));
#endif

#ifdef TCP_CORK
    AssPRec(tmp, RNamName("TCP_CORK"), INTOBJ_INT((Int) TCP_CORK));
#endif
#ifdef TCP_DEFER_ACCEPT
    AssPRec(tmp,RNamName("TCP_DEFER_ACCEPT"),INTOBJ_INT((Int)TCP_DEFER_ACCEPT));
#endif
#ifdef TCP_INFO
    AssPRec(tmp, RNamName("TCP_INFO"), INTOBJ_INT((Int) TCP_INFO));
#endif
#ifdef TCP_KEEPCNT
    AssPRec(tmp, RNamName("TCP_KEEPCNT"), INTOBJ_INT((Int) TCP_KEEPCNT));
#endif
#ifdef TCP_KEEPIDLE
    AssPRec(tmp, RNamName("TCP_KEEPIDLE"), INTOBJ_INT((Int) TCP_KEEPIDLE));
#endif
#ifdef TCP_KEEPINTVL
    AssPRec(tmp, RNamName("TCP_KEEPINTVL"), INTOBJ_INT((Int) TCP_KEEPINTVL));
#endif
#ifdef TCP_LINGER2
    AssPRec(tmp, RNamName("TCP_LINGER2"), INTOBJ_INT((Int) TCP_LINGER2));
#endif
#ifdef TCP_MAXSEG
    AssPRec(tmp, RNamName("TCP_MAXSEG"), INTOBJ_INT((Int) TCP_MAXSEG));
#endif
#ifdef TCP_NODELAY
    AssPRec(tmp, RNamName("TCP_NODELAY"), INTOBJ_INT((Int) TCP_NODELAY));
#endif
#ifdef TCP_QUICKACK
    AssPRec(tmp, RNamName("TCP_QUICKACK"), INTOBJ_INT((Int) TCP_QUICKACK));
#endif
#ifdef TCP_SYNCNT
    AssPRec(tmp, RNamName("TCP_SYNCNT"), INTOBJ_INT((Int) TCP_SYNCNT));
#endif
#ifdef TCP_WINDOW_CLAMP
    AssPRec(tmp,RNamName("TCP_WINDOW_CLAMP"),INTOBJ_INT((Int)TCP_WINDOW_CLAMP));
#endif
#ifdef ICMP_FILTER
    AssPRec(tmp, RNamName("ICMP_FILTER"), INTOBJ_INT((Int) ICMP_FILTER));
#endif

    /* Constants for messages for recv and send: */
#ifdef MSG_OOB
    AssPRec(tmp, RNamName("MSG_OOB"), INTOBJ_INT((Int) MSG_OOB));
#endif
#ifdef MSG_PEEK
    AssPRec(tmp, RNamName("MSG_PEEK"), INTOBJ_INT((Int) MSG_PEEK));
#endif
#ifdef MSG_WAITALL
    AssPRec(tmp, RNamName("MSG_WAITALL"), INTOBJ_INT((Int) MSG_WAITALL));
#endif
#ifdef MSG_TRUNC
    AssPRec(tmp, RNamName("MSG_TRUNC"), INTOBJ_INT((Int) MSG_TRUNC));
#endif
#ifdef MSG_ERRQUEUE
    AssPRec(tmp, RNamName("MSG_ERRQUEUE"), INTOBJ_INT((Int) MSG_ERRQUEUE));
#endif
#ifdef MSG_EOR
    AssPRec(tmp, RNamName("MSG_EOR"), INTOBJ_INT((Int) MSG_EOR));
#endif
#ifdef MSG_CTRUNC
    AssPRec(tmp, RNamName("MSG_CTRUNC"), INTOBJ_INT((Int) MSG_CTRUNC));
#endif
#ifdef MSG_OOB
    AssPRec(tmp, RNamName("MSG_OOB"), INTOBJ_INT((Int) MSG_OOB));
#endif
#ifdef MSG_ERRQUEUE
    AssPRec(tmp, RNamName("MSG_ERRQUEUE"), INTOBJ_INT((Int) MSG_ERRQUEUE));
#endif
#ifdef MSG_DONTWAIT
    AssPRec(tmp, RNamName("MSG_DONTWAIT"), INTOBJ_INT((Int) MSG_DONTWAIT));
#endif
#ifdef PIPE_BUF
    AssPRec(tmp, RNamName("PIPE_BUF"), INTOBJ_INT((Int) PIPE_BUF));
#endif
#ifdef F_DUPFD
    AssPRec(tmp, RNamName("F_DUPFD"), INTOBJ_INT((Int) F_DUPFD));
#endif
#ifdef F_GETFD
    AssPRec(tmp, RNamName("F_GETFD"), INTOBJ_INT((Int) F_GETFD));
#endif
#ifdef F_SETFD
    AssPRec(tmp, RNamName("F_SETFD"), INTOBJ_INT((Int) F_SETFD));
#endif
#ifdef FD_CLOEXEC
    AssPRec(tmp, RNamName("FD_CLOEXEC"), INTOBJ_INT((Int) FD_CLOEXEC));
#endif
#ifdef F_GETFL
    AssPRec(tmp, RNamName("F_GETFL"), INTOBJ_INT((Int) F_GETFL));
#endif
#ifdef F_SETFL
    AssPRec(tmp, RNamName("F_SETFL"), INTOBJ_INT((Int) F_SETFL));
#endif
#ifdef F_GETOWN
    AssPRec(tmp, RNamName("F_GETOWN"), INTOBJ_INT((Int) F_GETOWN));
#endif
#ifdef F_SETOWN
    AssPRec(tmp, RNamName("F_SETOWN"), INTOBJ_INT((Int) F_SETOWN));
#endif
#ifdef F_GETSIG
    AssPRec(tmp, RNamName("F_GETSIG"), INTOBJ_INT((Int) F_GETSIG));
#endif
#ifdef F_SETSIG
    AssPRec(tmp, RNamName("F_SETSIG"), INTOBJ_INT((Int) F_SETSIG));
#endif
#ifdef F_GETLEASE
    AssPRec(tmp, RNamName("F_GETLEASE"), INTOBJ_INT((Int) F_GETLEASE));
#endif
#ifdef F_SETLEASE
    AssPRec(tmp, RNamName("F_SETLEASE"), INTOBJ_INT((Int) F_SETLEASE));
#endif
#ifdef F_RDLCK
    AssPRec(tmp, RNamName("F_RDLCK"), INTOBJ_INT((Int) F_RDLCK));
#endif
#ifdef F_WRLCK
    AssPRec(tmp, RNamName("F_WRLCK"), INTOBJ_INT((Int) F_WRLCK));
#endif
#ifdef F_UNLCK
    AssPRec(tmp, RNamName("F_UNLCK"), INTOBJ_INT((Int) F_UNLCK));
#endif
#ifdef __GNUC__
    AssPRec(tmp, RNamName("__GNUC__"), INTOBJ_INT((Int) __GNUC__));
#endif
#ifdef __GNUC_MINOR__
    AssPRec(tmp, RNamName("__GNUC_MINOR__"), INTOBJ_INT((Int) __GNUC_MINOR__));
#endif
#ifdef SIGHUP
    AssPRec(tmp, RNamName("SIGHUP"), INTOBJ_INT((Int) SIGHUP));
#endif
#ifdef SIGINT
    AssPRec(tmp, RNamName("SIGINT"), INTOBJ_INT((Int) SIGINT));
#endif
#ifdef SIGQUIT
    AssPRec(tmp, RNamName("SIGQUIT"), INTOBJ_INT((Int) SIGQUIT));
#endif
#ifdef SIGILL
    AssPRec(tmp, RNamName("SIGILL"), INTOBJ_INT((Int) SIGILL));
#endif
#ifdef SIGABRT
    AssPRec(tmp, RNamName("SIGABRT"), INTOBJ_INT((Int) SIGABRT));
#endif
#ifdef SIGFPE
    AssPRec(tmp, RNamName("SIGFPE"), INTOBJ_INT((Int) SIGFPE));
#endif
#ifdef SIGKILL
    AssPRec(tmp, RNamName("SIGKILL"), INTOBJ_INT((Int) SIGKILL));
#endif
#ifdef SIGSEGV
    AssPRec(tmp, RNamName("SIGSEGV"), INTOBJ_INT((Int) SIGSEGV));
#endif
#ifdef SIGPIPE
    AssPRec(tmp, RNamName("SIGPIPE"), INTOBJ_INT((Int) SIGPIPE));
#endif
#ifdef SIGALRM
    AssPRec(tmp, RNamName("SIGALRM"), INTOBJ_INT((Int) SIGALRM));
#endif
#ifdef SIGTERM
    AssPRec(tmp, RNamName("SIGTERM"), INTOBJ_INT((Int) SIGTERM));
#endif
#ifdef SIGUSR1
    AssPRec(tmp, RNamName("SIGUSR1"), INTOBJ_INT((Int) SIGUSR1));
#endif
#ifdef SIGUSR2
    AssPRec(tmp, RNamName("SIGUSR2"), INTOBJ_INT((Int) SIGUSR2));
#endif
#ifdef SIGCHLD
    AssPRec(tmp, RNamName("SIGCHLD"), INTOBJ_INT((Int) SIGCHLD));
#endif
#ifdef SIGCONT
    AssPRec(tmp, RNamName("SIGCONT"), INTOBJ_INT((Int) SIGCONT));
#endif
#ifdef SIGSTOP
    AssPRec(tmp, RNamName("SIGSTOP"), INTOBJ_INT((Int) SIGSTOP));
#endif
#ifdef SIGTSTP
    AssPRec(tmp, RNamName("SIGTSTP"), INTOBJ_INT((Int) SIGTSTP));
#endif
#ifdef SIGTTIN
    AssPRec(tmp, RNamName("SIGTTIN"), INTOBJ_INT((Int) SIGTTIN));
#endif
#ifdef SIGTTOU
    AssPRec(tmp, RNamName("SIGTTOU"), INTOBJ_INT((Int) SIGTTOU));
#endif
#ifdef SIGBUS
    AssPRec(tmp, RNamName("SIGBUS"), INTOBJ_INT((Int) SIGBUS));
#endif
#ifdef SIGPOLL
    AssPRec(tmp, RNamName("SIGPOLL"), INTOBJ_INT((Int) SIGPOLL));
#endif
#ifdef SIGPROF
    AssPRec(tmp, RNamName("SIGPROF"), INTOBJ_INT((Int) SIGPROF));
#endif
#ifdef SIGSYS
    AssPRec(tmp, RNamName("SIGSYS"), INTOBJ_INT((Int) SIGSYS));
#endif
#ifdef SIGTRAP
    AssPRec(tmp, RNamName("SIGTRAP"), INTOBJ_INT((Int) SIGTRAP));
#endif
#ifdef SIGURG
    AssPRec(tmp, RNamName("SIGURG"), INTOBJ_INT((Int) SIGURG));
#endif
#ifdef SIGVTALRM
    AssPRec(tmp, RNamName("SIGVTALRM"), INTOBJ_INT((Int) SIGVTALRM));
#endif
#ifdef SIGXCPU
    AssPRec(tmp, RNamName("SIGXCPU"), INTOBJ_INT((Int) SIGXCPU));
#endif
#ifdef SIGXFSZ
    AssPRec(tmp, RNamName("SIGXFSZ"), INTOBJ_INT((Int) SIGXFSZ));
#endif
#ifdef SIGIOT
    AssPRec(tmp, RNamName("SIGIOT"), INTOBJ_INT((Int) SIGIOT));
#endif
#ifdef SIGEMT
    AssPRec(tmp, RNamName("SIGEMT"), INTOBJ_INT((Int) SIGEMT));
#endif
#ifdef SIGSTKFLT
    AssPRec(tmp, RNamName("SIGSTKFLT"), INTOBJ_INT((Int) SIGSTKFLT));
#endif
#ifdef SIGIO
    AssPRec(tmp, RNamName("SIGIO"), INTOBJ_INT((Int) SIGIO));
#endif
#ifdef SIGCLD
    AssPRec(tmp, RNamName("SIGCLD"), INTOBJ_INT((Int) SIGCLD));
#endif
#ifdef SIGPWR
    AssPRec(tmp, RNamName("SIGPWR"), INTOBJ_INT((Int) SIGPWR));
#endif
#ifdef SIGINFO
    AssPRec(tmp, RNamName("SIGINFO"), INTOBJ_INT((Int) SIGINFO));
#endif
#ifdef SIGLOST
    AssPRec(tmp, RNamName("SIGLOST"), INTOBJ_INT((Int) SIGLOST));
#endif
#ifdef SIGWINCH
    AssPRec(tmp, RNamName("SIGWINCH"), INTOBJ_INT((Int) SIGWINCH));
#endif
#ifdef SIGUNUSED
    AssPRec(tmp, RNamName("SIGUNUSED"), INTOBJ_INT((Int) SIGUNUSED));
#endif

    gvar = GVarName("IO");
    MakeReadWriteGVar( gvar);
    AssGVar( gvar, tmp );
    MakeReadOnlyGVar(gvar);
    /* return success                                                      */
    return 0;
}

/******************************************************************************
*F  InitInfopl()  . . . . . . . . . . . . . . . . . table of init functions
*/
static StructInitInfo module = {
#ifdef IOSTATIC
    .type = MODULE_STATIC,
#else
    .type = MODULE_DYNAMIC,
#endif
    .name = "io",
    .initKernel = InitKernel,
    .initLibrary = InitLibrary,
};

#ifndef IOSTATIC
StructInitInfo * Init__Dynamic ( void )
{
  return &module;
}
#endif

StructInitInfo * Init__io ( void )
{
  return &module;
}


/*
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */
