# from: mksh/Build.sh,v 1.863
# © mirabilos Ⓕ MirBSD

switchgroup() {
	echo "::endgroup::
::group::$*"
}
switchgroup sysinfo general

LC_ALL=C; LANGUAGE=C
export LC_ALL; unset LANGUAGE

case $ZSH_VERSION:$VERSION in
:zsh*) ZSH_VERSION=2 ;;
esac

if test -n "${ZSH_VERSION+x}" && (emulate sh) >/dev/null 2>&1; then
	emulate sh
	NULLCMD=:
fi

if test -d /usr/xpg4/bin/. >/dev/null 2>&1; then
	# Solaris: some of the tools have weird behaviour, use portable ones
	PATH=/usr/xpg4/bin:$PATH
	export PATH
fi

if test x"$1" = x"-cxx"; then
	shift
	CC= CFLAGS=
fi

cat <<EOF
Flags on entry:
- CC        <$CC>
- CFLAGS    <$CFLAGS>
- CXX       <$CXX>
- CXXFLAGS  <$CXXFLAGS>
- CPPFLAGS  <$CPPFLAGS>
- LDFLAGS   <$LDFLAGS>
- TARGET_OS <$TARGET_OS>

EOF

e=echo

v() {
	$e "$*"
	eval "$@"
}

vv() {
	_c=$1
	shift
	$e "\$ $*" 2>&1
	eval "$@" >vv.out 2>&1
	sed "s^${_c} " <vv.out
}

vq() {
	eval "$@"
}

test_n() {
	test x"$1" = x"" || return 0
	return 1
}

test_z() {
	test x"$1" = x""
}

if test_z "$TARGET_OS"; then
	x=`uname -s 2>/dev/null || uname`
	case $x in
	scosysv)
		# SVR4 Unix with uname -s = uname -n, whitelist
		TARGET_OS=$x
		;;
	syllable)
		# other OS with uname -s = uname = uname -n, whitelist
		TARGET_OS=$x
		;;
	*)
		test x"$x" = x"`uname -n 2>/dev/null`" || TARGET_OS=$x
		;;
	esac
fi
if test_z "$TARGET_OS"; then
	echo "::warning::Set TARGET_OS, your uname is broken!"
fi

echo "::notice::Running on $TARGET_OS"

case $TARGET_OS in
AIX)
	vv '|' "oslevel >&2"
	vv '|' "uname -a >&2"
	;;
Darwin)
	vv '|' "hwprefs machine_type os_type os_class >&2"
	vv '|' "sw_vers >&2"
	vv '|' "system_profiler -detailLevel mini SPSoftwareDataType SPHardwareDataType >&2"
	vv '|' "/bin/sh --version >&2"
	vv '|' "xcodebuild -version >&2"
	vv '|' "uname -a >&2"
	vv '|' "sysctl kern.version hw.machine hw.model hw.memsize hw.availcpu hw.ncpu hw.cpufrequency hw.byteorder hw.cpu64bit_capable >&2"
	vv '|' "sysctl hw.cpufrequency hw.byteorder hw.cpu64bit_capable hw.ncpu >&2"
	;;
IRIX*)
	vv '|' "uname -a >&2"
	vv '|' "hinv -v >&2"
	;;
OSF1)
	vv '|' "uname -a >&2"
	vv '|' "/usr/sbin/sizer -v >&2"
	;;
scosysv|SCO_SV|UnixWare|UNIX_SV|XENIX)
	vv '|' "uname -a >&2"
	vv '|' "uname -X >&2"
	;;
*)
	vv '|' "uname -a >&2"
	;;
esac

cat_h_blurb() {
	echo '#ifdef MKSH_USE_AUTOCONF_H
/* things that "should" have been on the command line */
#include "autoconf.h"
#undef MKSH_USE_AUTOCONF_H
#endif

'
	cat
}

doone() {
	switchgroup sysinfo "$1"
	cat_h_blurb >conftest.c <<'EOF'
const char *
#if defined(__ICC) || defined(__INTEL_COMPILER)
ct="icc"
#elif defined(__xlC__) || defined(__IBMC__)
ct="xlc"
#elif defined(__SUNPRO_C)
ct="sunpro"
#elif defined(__neatcc__)
ct="neatcc"
#elif defined(__lacc__)
ct="lacc"
#elif defined(__ACK__)
ct="ack"
#elif defined(__BORLANDC__)
ct="bcc"
#elif defined(__WATCOMC__)
ct="watcom"
#elif defined(__MWERKS__)
ct="metrowerks"
#elif defined(__HP_cc)
ct="hpcc"
#elif defined(__DECC) || (defined(__osf__) && !defined(__GNUC__))
ct="dec"
#elif defined(__PGI)
ct="pgi"
#elif defined(__DMC__)
ct="dmc"
#elif defined(_MSC_VER)
ct="msc"
#elif defined(__ADSPBLACKFIN__) || defined(__ADSPTS__) || defined(__ADSP21000__)
ct="adsp"
#elif defined(__IAR_SYSTEMS_ICC__)
ct="iar"
#elif defined(SDCC)
ct="sdcc"
#elif defined(__PCC__)
ct="pcc"
#elif defined(__TenDRA__)
ct="tendra"
#elif defined(__TINYC__)
ct="tcc"
#elif defined(__llvm__) && defined(__clang__)
ct="clang"
#elif defined(__NWCC__)
ct="nwcc"
#elif defined(__GNUC__) && ((__GNUC__) < 2)
ct="gcc1"
#elif defined(__GNUC__)
ct="gcc"
#elif defined(_COMPILER_VERSION)
ct="mipspro"
#elif defined(__sgi)
ct="mipspro"
#elif defined(__hpux) || defined(__hpua)
ct="hpcc"
#elif defined(__ultrix)
ct="ucode"
#elif defined(__USLC__)
ct="uslc"
#elif defined(__LCC__)
ct="lcc"
#elif defined(MKSH_MAYBE_QUICK_C) && defined(_M_BITFIELDS)
ct="quickc"
#elif defined(MKSH_MAYBE_KENCC)
/* and none of the above matches */
ct="kencc"
#elif defined(MKSH_MAYBE_SCDE)
ct="tryscde"
#else
ct="unknown"
#endif
;
const char *
#if defined(__KLIBC__) && !defined(__OS2__)
et="klibc"
#elif defined(__dietlibc__)
et="dietlibc"
#else
et="unknown"
#endif
;
EOF
	ct=untested
	et=untested
	vv ']' "$CPP $CFLAGS $CPPFLAGS $NOWARN $cmplrflgs conftest.c | \
	    sed -n '/^ *[ce]t *= */s/^ *\([ce]t\) *= */\1=/p' | tr -d \\\\015 >x"
	sed 's/^/[ /' x
	eval `cat x`
	rm -f x vv.out
	cat_h_blurb >conftest.c <<'EOF'
int main(void) { return (0); }
EOF
	case $ct:$TARGET_OS in
	tryscde:*)
		case `LC_ALL=C; export LC_ALL; $CC -V 2>&1` in
		*'Standard C Development Environment'*)
			ct=scde ;;
		*)
			ct=unknown ;;
		esac
		;;
	gcc:_svr4)
		# weirdly needed to find NSIG
		case $CC$CPPFLAGS in
		*STDC*) ;;
		*) CC="$CC -U__STDC__ -D__STDC__=0" ;;
		esac
		;;
	esac
	case $ct in
	clang)
		# does not work with current "ccc" compiler driver
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS --version"
		# one of these two works, for now
		vv '|' "${CLANG-clang} -version"
		;;
	dec)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS -V"
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN -Wl,-V conftest.c $LIBS"
		;;
	gcc1)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN -v conftest.c $LIBS"
		vv '|' 'eval echo "\`$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS -dumpmachine\`" \
			 "gcc\`$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS -dumpversion\`"'
		;;
	gcc)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN -v conftest.c $LIBS"
		vv '|' 'eval echo "\`$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS -dumpmachine\`" \
			 "gcc\`$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS -dumpversion\`"'
		;;
	hpcc)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN -V conftest.c $LIBS"
		;;
	icc)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS -V"
		;;
	kencc)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN -v conftest.c $LIBS"
		;;
	lacc)
		# no version information
		;;
	lcc)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN -v conftest.c $LIBS"
		;;
	mipspro)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS -version"
		;;
	msc)
		case $TARGET_OS in
		Interix)
			if test_z "$C89_COMPILER"; then
				C89_COMPILER=CL.EXE
			else
				C89_COMPILER=`ntpath2posix -c "$C89_COMPILER"`
			fi
			if test_z "$C89_LINKER"; then
				C89_LINKER=LINK.EXE
			else
				C89_LINKER=`ntpath2posix -c "$C89_LINKER"`
			fi
			vv '|' "$C89_COMPILER /HELP >&2"
			vv '|' "$C89_LINKER /LINK >&2"
			;;
		esac
		;;
	neatcc)
		vv '|' "$CC"
		;;
	nwcc)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS -version"
		;;
	pcc)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS -v"
		;;
	quickc)
		# no version information
		;;
	scde)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN -V conftest.c $LIBS"
		;;
	sunpro)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN -V conftest.c $LIBS"
		;;
	tcc)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS -v"
		;;
	tendra)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS -V 2>&1 | \
		    grep -i -e version -e release"
		;;
	ucode)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS -V"
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN -Wl,-V conftest.c $LIBS"
		;;
	uslc)
		test_n "$TARGET_OSREV" || TARGET_OSREV=`uname -r`
		case $TARGET_OS:$TARGET_OSREV in
		SCO_SV:3.2*)
			# SCO OpenServer 5
			CFLAGS="$CFLAGS -g"
			;;
		esac
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN -V conftest.c $LIBS"
		;;
	watcom)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN -v conftest.c $LIBS"
		;;
	xlc)
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS -qversion"
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN $LIBS -qversion=verbose"
		vv '|' "ld -V"
		;;
	*)
		test x"$ct" = x"untested" && $e "!!! detecting preprocessor failed"
		vv '|' "$CC --version"
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN -v conftest.c $LIBS"
		vv '|' "$CC $CFLAGS $Cg $CPPFLAGS $LDFLAGS $NOWARN -V conftest.c $LIBS"
		;;
	esac
	echo "::notice::Using $ct on $et"
}

ext=c
if test -n "$CC"; then
	doone "C"
	if test x"$1" = x"-m32"; then
		CFLAGS="$CFLAGS -m32"
		doone "ILP32 C"
	fi
fi
ext=cc
CC=$CXX
CFLAGS=$CXXFLAGS
if test -n "$CC"; then
	doone "C++"
	if test x"$1" = x"-m32"; then
		CFLAGS="$CFLAGS -m32"
		doone "ILP32 C++"
	fi
fi
