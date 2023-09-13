LC_ALL=C.UTF-8 DEBIAN_FRONTEND=noninteractive
export LC_ALL DEBIAN_FRONTEND
unset LANGUAGE
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
set -ex
while test $# -gt 0; do
	case $1 in
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
apt-get install -y bc build-essential $xpkg
: "${CC=cc}${CXX=c++}${CFLAGS=-O2}"
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
		;;
	(*)
		exit 1 ;;
	esac
fi
export LDFLAGS
case $cfx in
(*'++'*) usecxx=-cxx CC=$CXX CFLAGS=$CXXFLAGS ;;
esac
exec sh mkt-int.sh $usecxx \
    $CC $CPPFLAGS $cfs $cft $CFLAGS -Wall -Wextra $cfx \
    -DMBSDINT_H_WANT_PTR_IN_SIZET \
    -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 \
    -DMBSDINT_H_WANT_LRG64 \
    -DMBSDINT_H_WANT_SAFEC
