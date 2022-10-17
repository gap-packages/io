# IO_accept(fd, addr)
gap> IO_accept(fail, fail);
fail

# IO_bind(fd, my_addr)
gap> IO_bind(fail, fail);
fail

# IO_chdir(path)
gap> IO_chdir(fail);
fail

# IO_chmod(path, mode)
gap> IO_chmod(fail, fail);
fail

# IO_chown(path, owner, group)
gap> IO_chown(fail, fail, fail);
fail

# IO_close(fd)
gap> IO_close(fail);
fail

# IO_closedir()
gap> IO_closedir();
fail

# IO_connect(fd, serv_addr)
gap> IO_connect(fail, fail);
fail

# IO_creat(pathname, mode)
gap> IO_creat(fail, fail);
fail

# IO_dup(oldfd)
gap> IO_dup(fail);
fail

# IO_dup2(oldfd, newfd)
gap> IO_dup2(fail, fail);
fail

# IO_environ()
gap> env:=IO_environ();; IsList(env); ForAll(env, IsString);
true
true

# IO_execv(path, argv)
gap> IO_execv(fail, fail);
fail

# IO_execve(path, argv, envp)
gap> IO_execve(fail, fail, fail);
fail

# IO_execvp(path, argv)
gap> IO_execvp(fail, fail);
fail

# IO_exit(status)
gap> IO_exit(fail);
fail

# IO_fchmod(fd, mode)
gap> IO_fchmod(fail, fail);
fail

# IO_fchown(fd, owner, group)
gap> IO_fchown(fail, fail, fail);
fail

# IO_fcntl(fd, cmd, arg)
gap> IO_fcntl(fail, fail, fail);
fail

# IO_fork()
gap> #IO_fork(); # TODO: test this

# IO_fstat(fd)
gap> IO_fstat(fail);
fail

# IO_getcwd()
gap> IsString(IO_getcwd());
true

# IO_getenv(name)
gap> IO_getenv(fail);
fail

# IO_gethostbyname(name)
gap> IO_gethostbyname(fail);
fail

# IO_gethostname()
gap> IsString(IO_gethostname());
true

# IO_getpid()
gap> IsInt(IO_getpid());
true

# IO_getppid()
gap> IsInt(IO_getppid());
true

# IO_getsockname(fd)
gap> IO_getsockname(fail);
fail

# IO_getsockopt(fd, level, optname, optval, optlen)
gap> IO_getsockopt(fail, fail, fail, fail, fail);
fail

# IO_gettimeofday()
gap> timeofday:=IO_gettimeofday();; Set(RecNames(timeofday));
[ "tv_sec", "tv_usec" ]

# IO_gmtime(seconds)
gap> IO_gmtime(fail);
fail

# IO_IgnorePid(pid)
gap> IO_IgnorePid(fail);
fail

# IO_kill(pid, sig)
gap> IO_kill(fail, fail);
fail

# IO_lchown(path, owner, group)
gap> IO_lchown(fail, fail, fail);
fail

# IO_link(oldpath, newpath)
gap> IO_link(fail, fail);
fail

# IO_listen(s, backlog)
gap> IO_listen(fail, fail);
fail

# IO_localtime(seconds)
gap> IO_localtime(fail);
fail

# IO_lseek(fd, offset, whence)
gap> IO_lseek(fail, fail, fail);
fail

# IO_lstat(pathname)
gap> IO_lstat(fail);
fail

# IO_make_sockaddr_in(ip, port)
gap> IO_make_sockaddr_in(fail, fail);
fail

# IO_mkdir(pathname, mode)
gap> IO_mkdir(fail, fail);
fail

# IO_mkdtemp(template)
gap> IO_mkdtemp(fail);
fail

# IO_mkfifo(path, mode)
gap> IO_mkfifo(fail, fail);
fail

# IO_mknod(path, mode, dev)
gap> IO_mknod(fail, fail, fail);
fail

# IO_mkstemp(template)
gap> IO_mkstemp(fail);
fail

# IO_open(pathname, flags, mode)
gap> IO_open(fail, fail, fail);
fail

# IO_opendir(name)
gap> IO_opendir(fail);
fail

# IO_pipe()
gap> # IO_pipe(); # TODO: test this

# IO_read(fd, st, offset, count)
gap> IO_read(fail, fail, fail, fail);
fail

# IO_readdir()
gap> # IO_readdir(); # TODO: test this

# IO_readlink(path, buf, bufsize)
gap> IO_readlink(fail, fail, fail);
fail

# IO_realpath(path)
gap> IO_realpath(fail);
fail
gap> IO_realpath("/");
"/"
gap> IO_getcwd() = IO_realpath(".");
true

# IO_recv(fd, st, offset, len, flags)
gap> IO_recv(fail, fail, fail, fail, fail);
fail

# IO_recvfrom(fd, st, offset, len, flags, from)
gap> IO_recvfrom(fail, fail, fail, fail, fail, fail);
fail

# IO_rename(oldpath, newpath)
gap> IO_rename(fail, fail);
fail

# IO_rewinddir()
gap> #IO_rewinddir(); # TODO: test this

# IO_rmdir(pathname)
gap> IO_rmdir(fail);
fail

# IO_seekdir(offset)
gap> IO_seekdir(fail);
fail

# IO_select(inlist, outlist, exclist, timeoutsec, timeoutusec)
gap> IO_select(fail, fail, fail, fail, fail);
Error, <inlist> must be a list of small integers (not a boolean or fail)

# IO_send(fd, st, offset, len, flags)
gap> IO_send(fail, fail, fail, fail, fail);
fail

# IO_sendto(fd, st, offset, len, flags, to)
gap> IO_sendto(fail, fail, fail, fail, fail, fail);
fail

# IO_setenv(name, value, overwrite)
gap> IO_setenv(fail, fail, fail);
fail

# IO_setsockopt(fd, level, optname, optval)
gap> IO_setsockopt(fail, fail, fail, fail);
fail

# IO_socket(domain, type, protocol)
gap> IO_socket(fail, fail, fail);
fail

# IO_stat(pathname)
gap> IO_stat(fail);
fail

# IO_symlink(oldpath, newpath)
gap> IO_symlink(fail, fail);
fail

# IO_telldir()
gap> #IO_telldir(); # TODO: test this

# IO_unlink(pathname)
gap> IO_unlink(fail);
fail

# IO_unsetenv(name)
gap> IO_unsetenv(fail);
fail

# IO_WaitPid(pid, wait)
gap> IO_WaitPid(fail, fail);
fail

# IO_write(fd, st, offset, count)
gap> IO_write(fail, fail, fail, fail);
fail
