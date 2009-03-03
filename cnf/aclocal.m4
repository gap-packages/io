dnl #########################################################################
dnl ##
dnl ## check what unaligned access is still save
dnl ##

AC_DEFUN(GP_C_LONG_ALIGN,
[AC_CACHE_CHECK(unaligned access, gp_cv_c_long_align,
[
case "$host" in
   alpha* )
	gp_cv_c_long_align=8;;
   mips-* | sparc-* )
        gp_cv_c_long_align=$ac_cv_sizeof_void_p;;
   i586-* | i686-* )
        gp_cv_c_long_align=2;;
        * )

case "$host" in 
   *OSF* | *osf* )
    uac p sigbus;;
esac
 AC_TRY_RUN( [char buf[32];main(){long i= *(long*)(buf+1);buf[1]=(char)i;exit(0);}],
 gp_cv_c_long_align=1,
 [
  AC_TRY_RUN( [char buf[32];main(){long i= *(long*)(buf+2);buf[1]=(char)i;exit(0);}],
  gp_cv_c_long_align=2,
  [
   AC_TRY_RUN( [char buf[32];main(){long i= *(long*)(buf+4);buf[1]=(char)i;exit(0);}],
   gp_cv_c_long_align=4,
   [
    AC_TRY_RUN( [char buf[32];main(){long i= *(long*)(buf+8);buf[1]=(char)i;exit(0);}],
    gp_cv_c_long_align=8 )
   ] )
  ] )
 ] )
 rm -f core core.* *.core
esac
] )
AC_DEFINE_UNQUOTED( C_LONG_ALIGN, $gp_cv_c_long_align, long alignment )
] )


dnl #########################################################################
dnl ##
dnl ## choose CFLAGS more carefully
dnl ##
dnl ##  For alpha/cc (or some flavours of this at least) -O3 is faster
dnl ##  but seems to reveal a compiler bug applying to stats.c and causing
dnl ##  SyCompileInput to be clobbered while PrintStatFuncs is being
dnl ##  initialized
dnl ##
AC_DEFUN(GP_CFLAGS,
[AC_CACHE_CHECK(C compiler default flags, gp_cv_cflags,
 [ case "$host-$CC" in
    *-gcc | *-linux*-cc )
     	gp_cv_cflags="-Wall -g -O2";;
    i686-*-egcs )
        gp_cv_cflags="-Wall -g -O2 -mcpu=i686";;
    i586-*-egcs )
        gp_cv_cflags="-Wall -g -O2 -mcpu=i586";;
    i486-*-egcs )
        gp_cv_cflags="-Wall -g -O2 -mcpu=i486";;
    i386-*-egcs )
        gp_cv_cflags="-Wall -g -O2 -mcpu=i386";;
    alphaev6-*-osf4*-cc )
	gp_cv_cflags="-g3 -arch ev6 -O1 ";;
    alphaev56-*-osf4*-cc )
	gp_cv_cflags="-g3 -arch ev56 -O1";;
    alphaev5-*-osf4*-cc )
	gp_cv_cflags="-g3 -arch ev5 -O1";;
    alpha*-*-osf4*-cc )
	gp_cv_cflags="-g3 -O1";;
    *aix*cc )
	gp_cv_cflags="-g -O3";;
    *-solaris*-cc )
	gp_cv_cflags="-fast -erroff=E_STATEMENT_NOT_REACHED";;
    *-irix*-cc )
	gp_cv_cflags="-O3 -woff 1110,1167,1174,1552";;
    * )
        gp_cv_cflags="-O";;
   esac 
 ])
CFLAGS=$gp_cv_cflags
AC_SUBST(CFLAGS)])

dnl #########################################################################
dnl ##
dnl ## choose LDFLAGS more carefully
dnl ##

AC_DEFUN(GP_LDFLAGS,
[AC_CACHE_CHECK(Linker default flags, gp_cv_ldflags,
 [ case "$host-$CC" in
    *-gcc | *-linux*-cc | *-egcs )
     	gp_cv_ldflags="-g";;
    alpha*-*-osf4*-cc )
	gp_cv_ldflags="-g3 ";;
    *-solaris*-cc )
	gp_cv_ldflags="";;
    *aix*cc )
	gp_cv_ldflags="-g";;
    *-irix*-cc )
	gp_cv_ldflags="-O3";;
    * )
        gp_cv_ldflags="";;
   esac 
 ])
LDFLAGS=$gp_cv_ldflags
AC_SUBST(LDFLAGS)])
              
dnl #########################################################################
dnl ##
dnl ## flags for dynamic linking
dnl ##
AC_DEFUN(GP_PROG_CC_DYNFLAGS,
[AC_CACHE_CHECK(dynamic module compile options, gp_cv_prog_cc_cdynoptions,
 [ case "$host-$CC" in
    i686-pc-cygwin-gcc )
        gp_cv_prog_cc_cdynoptions="";;
    *-apple-darwin*gcc* )
        gp_cv_prog_cc_cdynoptions="-fPIC";;
    *-hpux-gcc )
        gp_cv_prog_cc_cdynoptions="-fpic";;
    *-gcc | *-egcs )
     	gp_cv_prog_cc_cdynoptions="-fpic -Wall -O2";;
    *-next-nextstep-cc )
        gp_cv_prog_cc_cdynoptions=" -Wall -O2 -arch $hostcpu";;
    *-osf*-cc )
	gp_cv_prog_cc_cdynoptions=" -shared -x -O2";;
    *-irix* )
        gp_cv_prog_cc_cdynoptions=" -O3 -woff 1110,1167,1174,1552";;
   
    * )
        gp_cv_prog_cc_cdynoptions="UNSUPPORTED";;
   esac 
 ])
 AC_CACHE_CHECK(dynamic linker, gp_cv_prog_cc_cdynlinker,
 [ case "$host-$CC" in
    i686-pc-cygwin-gcc )
        gp_cv_prog_cc_cdynlinker="gcc";;
    *-apple-darwin*gcc* )
        gp_cv_prog_cc_cdynlinker="ld";;
    *-gcc | *-egcs )
        gp_cv_prog_cc_cdynlinker="ld";;
    *-next-nextstep-cc )
        gp_cv_prog_cc_cdynlinker="cc";;
    *-osf*-cc )
	gp_cv_prog_cc_cdynlinker="cc";;
    *-irix* )
        gp_cv_prog_cc_cdynlinker="ld";;
    * )
        gp_cv_prog_cc_cdynlinker="echo";;
   esac 
 ])
 AC_CACHE_CHECK(dynamic module link flags, gp_cv_prog_cc_cdynlinking,
 [ case "$host-$CC" in
    *linux* )
        gp_cv_prog_cc_cdynlinking="-Bshareable -x";;
    *freebsd* )
        gp_cv_prog_cc_cdynlinking="-Bshareable -x";;
    *netbsd* )
        gp_cv_prog_cc_cdynlinking="-shared";;
    *hpux* )
        gp_cv_prog_cc_cdynlinking="-b +e Init__Dynamic";;
    alpha*osf*cc )
	gp_cv_prog_cc_cdynlinking="-shared";;
    *osf*cc )
	gp_cv_prog_cc_cdynlinking="-shared -r";;
    *-irix* )
       gp_cv_prog_cc_cdynlinking="-shared";;  
    *-nextstep*cc )
        gp_cv_prog_cc_cdynlinking="-arch $hostcpu -Xlinker -r -Xlinker -x -nostdlib";;
    *solaris* )
        gp_cv_prog_cc_cdynlinking="-G -Bdynamic";;
    *sunos* )
        gp_cv_prog_cc_cdynlinking="-assert pure-text -Bdynamic -x";;
    *-apple-darwin*gcc* )
        gp_cv_prog_cc_cdynlinking='-bundle -bundle_loader ${gap_bin}/gap -lc -lm';;
    i686-pc-cygwin-gcc )
        gp_cv_prog_cc_cdynlinking='-shared ${gap_bin}/gap.dll';;
    * )
        gp_cv_prog_cc_cdynlinking="UNSUPPORTED";;
   esac 
 ])

CDYNOPTIONS=$gp_cv_prog_cc_cdynoptions 
CDYNLINKER=$gp_cv_prog_cc_cdynlinker
CDYNLINKING=$gp_cv_prog_cc_cdynlinking

AC_SUBST(CDYNOPTIONS)
AC_SUBST(CDYNLINKER)
AC_SUBST(CDYNLINKING)

])
