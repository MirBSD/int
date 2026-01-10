#!/bin/sh
#-
# © mirabilos Ⓕ MirBSD or CC0

switchgroup() {
	echo "::endgroup::
::group::$*"
}
exec 2>&1
set -ex
LC_ALL=C.UTF-8 LANGUAGE=C DEBIAN_FRONTEND=noninteractive
export LC_ALL DEBIAN_FRONTEND
unset LANGUAGE
echo ::group::Setup $0 on Debian sid
cat >dummy.c <<\EOF
int main(void) { return (0); }
EOF
cp dummy.c dummy.cc
# more once #539617 is fixed
dbmo_f=future=+all,-lfs,-time64
dbmo_q=qa=+all,-canary
dbmo_o=optimize=+all,-lto
dbmo_h=hardening=+all
dbmo_r=reproducible=+all
cfs=
cft=
cfx=
cfx_asan='-fsanitize=address -fno-omit-frame-pointer -fno-common -fsanitize=pointer-compare -fsanitize=pointer-subtract -fsanitize=undefined -fsanitize=shift -fsanitize=shift-exponent -fsanitize=shift-base -fsanitize=integer-divide-by-zero -fsanitize=unreachable -fsanitize=vla-bound -fsanitize=null -fsanitize=signed-integer-overflow -fsanitize=bounds -fsanitize=bounds-strict -fsanitize=alignment -fsanitize=object-size -fsanitize=nonnull-attribute -fsanitize=returns-nonnull-attribute -fsanitize=bool -fsanitize=enum -fsanitize=vptr -fsanitize=pointer-overflow -fsanitize=builtin -fsanitize-address-use-after-scope -fstack-clash-protection'
libc=
xpkg=
usecxx=
while test $# -gt 0; do
	case $1 in
	(gccss)
		xpkg=gcc-snapshot
		;;
	(-std=DEFAULT)
		;;
	(-std=*)
		cfx=$1
		;;
	(lfs)
		dbmo_f=future=+all,-time64
		;;
	(asan)
		ASAN_OPTIONS=check_initialization_order=true:detect_stack_use_after_return=true:detect_invalid_pointer_pairs=2:dump_instruction_bytes=true:color=never:strict_string_checks=true:exitcode=251
		export ASAN_OPTIONS
		cfx="-Og $cfx_asan"
		;;
	(time64)
		# #1030159 is not available yet, so do it by hand
		dbmo_f=future=+all,-time64
		cft='-D_TIME_BITS=64'
		;;
	(ss[123])
		cfs=-DMBSDINT_H_SMALL_SYSTEM=${1#ss}
		;;
	(dietlibc)
		libc=$1
		xpkg=dietlibc-dev
		;;
	(klibc)
		libc=$1
		xpkg=libklibc-dev
		;;
	(clang)
		libc=$1
		xpkg=clang
		;;
	(*)
		echo >&2 "E: unknown option: $1"
		exit 1 ;;
	esac
	shift
done
dbmo="$dbmo_f $dbmo_q $dbmo_o $dbmo_h $dbmo_r"
cat >/etc/apt/apt.conf.d/92bla <<\EOF
debug::pkgproblemresolver "true";
Dpkg::Progress-Fancy "false";
// undo lenny breakage
APT::Install-Recommends "0";
APT::Install-Suggests "0";
APT::Get::Always-Include-Phased-Updates "true";
APT::Periodic::Enable "0";
EOF
apt-get update
apt-get --purge -y dist-upgrade
apt-get install -y bc build-essential file $xpkg
if test x"$xpkg" = x"gcc-snapshot"; then
	mkdir -p /usr/local/bin
	cat >/usr/local/bin/gcc-snapshot <<\EOF
#!/bin/sh
LD_LIBRARY_PATH=/usr/lib/gcc-snapshot/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
PATH=/usr/lib/gcc-snapshot/bin${PATH:+:$PATH}
rpath=""
OLD_IFS="$IFS"
IFS=:
for i in $LD_RUN_PATH
do
  rpath="$rpath -Wl,-rpath -Wl,$i"
done
IFS="$OLD_IFS"
exec gcc -Wl,-rpath -Wl,/usr/lib/gcc-snapshot/lib \
         -Wl,-rpath -Wl,/usr/lib/gcc-snapshot/lib32 \
         -Wl,-rpath -Wl,/usr/lib/gcc-snapshot/libx32 $rpath "$@"
EOF
	chmod +x /usr/local/bin/gcc-snapshot
	cat >/usr/local/bin/g++-snapshot <<\EOF
#!/bin/sh
LD_LIBRARY_PATH=/usr/lib/gcc-snapshot/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
PATH=/usr/lib/gcc-snapshot/bin${PATH:+:$PATH}
rpath=""
OLD_IFS="$IFS"
IFS=:
for i in $LD_RUN_PATH
do
  rpath="$rpath -Wl,-rpath -Wl,$i"
done
IFS="$OLD_IFS"
exec g++ -Wl,-rpath -Wl,/usr/lib/gcc-snapshot/lib \
         -Wl,-rpath -Wl,/usr/lib/gcc-snapshot/lib32 \
         -Wl,-rpath -Wl,/usr/lib/gcc-snapshot/libx32 $rpath "$@"
EOF
	chmod +x /usr/local/bin/g++-snapshot
	CC=/usr/local/bin/gcc-snapshot
	CXX=/usr/local/bin/g++-snapshot
fi
: "${CC=cc}${CXX=c++}${CFLAGS=-O2}${CXXFLAGS=-O2}"
export CC CXX
eval "$(env DEB_BUILD_MAINT_OPTIONS="$dbmo" dpkg-buildflags --export=sh || :)"
if test -n "$libc"; then
	sCFLAGS=
	for x in $CFLAGS; do
		case $x in
		(-O*|-g*|-fstack-protector*|-fPIE|-specs=*) ;;
		(*) sCFLAGS="$sCFLAGS $x" ;;
		esac
	done
	sLDFLAGS=
	for x in $LDFLAGS; do
		case $x in
		(-pie|-fPIE|-specs=*) ;;
		(*) sLDFLAGS="$sLDFLAGS $x" ;;
		esac
	done
	case $libc in
	(dietlibc)
		CC="diet -v -Os $CC"
		CFLAGS=$sCFLAGS
		CPPFLAGS=$sCPPFLAGS
		LDFLAGS=$sLDFLAGS
		;;
	(klibc)
		CC=klcc
		CFLAGS="$(klcc -print-klibc-optflags) $sCFLAGS"
		CPPFLAGS=$sCPPFLAGS
		LDFLAGS="$sLDFLAGS -static"
		;;
	(clang)
		CC=clang
		CXX=clang++
		CFLAGS=$(printf '%s\n' "$CFLAGS" | sed 's/-Werror=clobbered\>//g')
		CXXFLAGS=$(printf '%s\n' "$CXXFLAGS" | sed 's/-Werror=clobbered\>//g')
		;;
	(*)
		exit 1 ;;
	esac
fi
case $cfx in
(*'++'*) usecxx=-cxx CC=$CXX CFLAGS=$CXXFLAGS ;;
esac
case $CC in
(*clang*) ;;
(*) CFLAGS="$CFLAGS -Wvla" ;;
esac
CPPFLAGS="$CPPFLAGS $cfs $cft"
CFLAGS="$CFLAGS -Wall -Wextra $cfx"
if test -z "$usecxx"; then
	($CC $CPPFLAGS $CFLAGS $LDFLAGS -v dummy.c || :)
	CXX= CXXFLAGS=
else
	($CC $CPPFLAGS $CFLAGS $LDFLAGS -v dummy.cc || :)
	CXX=$CC CXXFLAGS=$CFLAGS
fi
export CC CXX CPPFLAGS CFLAGS CXXFLAGS LDFLAGS
sh .extra/info.sh $usecxx
switchgroup Build and run testsuite
exec sh mkt-int.sh $usecxx \
    $CC $CPPFLAGS $CFLAGS \
    -DMBSDINT_H_WANT_PTR_IN_SIZET \
    -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 \
    -DMBSDINT_H_WANT_LRG64 \
    -DMBSDINT_H_WANT_SAFEC
echo ::endgroup::
