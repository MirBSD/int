# © mirabilos Ⓕ MirBSD or CC0
exec 2>&1
set -ex
LC_ALL=C.UTF-8 LANGUAGE=C DEBIAN_FRONTEND=noninteractive
export LC_ALL DEBIAN_FRONTEND
unset LANGUAGE
xarch=$1 xtriplet=$2 xqemu=$3
echo ::group::Setup $0 on Debian sid/$xarch
nocxx=false
cat >dummy.c <<\EOF
int main(void) { return (0); }
EOF
cp dummy.c dummy.cc
# configury
HAVE_CAN_QNOIPA=0
HAVE_CAN_XIPO_0=0
export HAVE_CAN_QNOIPA HAVE_CAN_XIPO_0
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
apt-get install -y bc build-essential
apt-get install -y --install-recommends gcc-$xtriplet g++-$xtriplet
CC=$xtriplet-gcc CXX=$xtriplet-g++
export CC CXX
: "${CFLAGS=-O2}${CXXFLAGS=-O2}"
eval "$(env \
    DEB_BUILD_MAINT_OPTIONS="qa=+all,-canary optimize=+all,-lto hardening=+all reproducible=+all" \
    DEB_HOST_ARCH=$xarch \
    dpkg-buildflags --export=sh || :)"
CFLAGS="$CFLAGS -Wall -Wextra -Wvla"
CXXFLAGS="$CXXFLAGS -Wall -Wextra -Wvla"
# avoid qemu-m68k: Could not open '/lib/ld.so.1': No such file or directory
LDFLAGS="$LDFLAGS -static"
export LDFLAGS
($CC $CPPFLAGS $CFLAGS $LDFLAGS -v dummy.c || :)
$nocxx || ($CXX $CPPFLAGS $CXXFLAGS $LDFLAGS -v dummy.cc || :)
echo ::endgroup::
echo ::group::Build for C on sid/$xarch
<dummy.c DEBUG=' ' sh mkt-int.sh -x \
    $CC $CPPFLAGS $CFLAGS \
    -DMBSDINT_H_WANT_PTR_IN_SIZET \
    -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 \
    -DMBSDINT_H_WANT_LRG64 \
    -DMBSDINT_H_WANT_SAFEC
mv mkt-int-t-t.exe .result-c
echo ::endgroup::
if $nocxx; then
	echo ::group::No C++ here
else
	echo ::group::Build for C++ on sid/$xarch
	<dummy.cc DEBUG=' ' sh mkt-int.sh -cxx -x \
	    $CXX $CPPFLAGS $CXXFLAGS \
	    -DMBSDINT_H_WANT_PTR_IN_SIZET \
	    -DMBSDINT_H_WANT_SIZET_IN_LONG \
	    -DMBSDINT_H_WANT_INT32 \
	    -DMBSDINT_H_WANT_LRG64 \
	    -DMBSDINT_H_WANT_SAFEC
	mv mkt-int-t-t.exe .result-cxx
fi
echo ::endgroup::
echo ::group::Installing qemu-user
apt-get install -y qemu-user
echo ::endgroup::
echo ::group::Running under qemu-user
$xqemu ./.result-c
if $nocxx; then
	echo "(for C)"
else
	echo
	echo "(C above; CFrustFrust below)"
	echo
	$xqemu ./.result-cxx
fi
echo ::endgroup::
