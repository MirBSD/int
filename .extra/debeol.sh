#!/bin/sh
#-
# © mirabilos Ⓕ MirBSD or CC0

switchgroup() {
	echo "::endgroup::
::group::$*"
}
exec 2>&1
set -ex
LC_ALL=C LANGUAGE=C DEBIAN_FRONTEND=noninteractive
export LC_ALL DEBIAN_FRONTEND
unset LANGUAGE
echo ::group::Setup $0 on Debian $2
nocxx=false
cat >dummy.c <<\EOF
int main(void) { return (0); }
EOF
cp dummy.c dummy.cc
# configury
HAVE_CAN_QNOIPA=0
HAVE_CAN_XIPO_0=0
export HAVE_CAN_QNOIPA HAVE_CAN_XIPO_0
cat >>/etc/apt/apt.conf <<\EOF
debug::pkgproblemresolver "true";
Dpkg::Progress-Fancy "false";
// undo lenny breakage
APT::Install-Recommends "0";
APT::Install-Suggests "0";
APT::Get::Always-Include-Phased-Updates "true";
APT::Periodic::Enable "0";
EOF
rm -f /etc/apt/sources.list /etc/apt/sources.list.d/*
if test -s .extra/sl/$1.sources; then
	cp .extra/sl/$1.sources /etc/apt/sources.list.d/
else
	cp .extra/sl/$1.list /etc/apt/sources.list
fi
apt-get update
case $1 in
slink|potato|woody|sarge|etch)
	;;
*)
	apt-get --purge -y dist-upgrade
	;;
esac
case $1 in
slink)
	# work around a segfault
	apt-get -d -y install bc file gcc g++
	dpkg -i /var/cache/apt/archives/*.deb
	;;
experimental)
	apt-get install -t experimental -y bc build-essential \
	    binutils cpp file gcc g++ libc6-dev
	;;
*)
	apt-get install -y bc build-essential file
	;;
esac
: "${CC=cc}${CXX=c++}${CFLAGS=-O2}${CXXFLAGS=-O2}"
export CC CXX
eval "$(env DEB_BUILD_MAINT_OPTIONS=hardening=+all dpkg-buildflags --export=sh || :)"
case $1 in
experimental)
	CFLAGS="$CFLAGS -Wall -Wextra -Wformat -Wformat-security"
	CXXFLAGS="$CXXFLAGS -Wall -Wextra -Wformat -Wformat-security"
	if test x"$2" = x"experimental-next"; then
		CFLAGS="$CFLAGS -std=c2y"
		CXXFLAGS="$CXXFLAGS -std=c++2c"
	fi
	;;
slink)
	CFLAGS="$CFLAGS -Wall -W"
	CXXFLAGS="$CXXFLAGS -Wall -W"
	# work around issue in egcs system header
	CFLAGS="$CFLAGS -Wno-missing-braces"
	;;
*)
	CFLAGS="$CFLAGS -Wall -W"
	CXXFLAGS="$CXXFLAGS -Wall -W"
	;;
esac
($CC $CPPFLAGS $CFLAGS $LDFLAGS -v dummy.c || :)
$nocxx || ($CXX $CPPFLAGS $CXXFLAGS $LDFLAGS -v dummy.cc || :)
if $nocxx; then CXX= CXXFLAGS=; fi
export CC CXX CPPFLAGS CFLAGS CXXFLAGS LDFLAGS
sh .extra/info.sh
switchgroup Build for C on $1
sh mkt-int.sh \
    $CC $CPPFLAGS $CFLAGS \
    -DMBSDINT_H_WANT_PTR_IN_SIZET \
    -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 \
    -DMBSDINT_H_WANT_SAFEC
if $nocxx; then
	echo ::endgroup::
	exit 0
fi
switchgroup Build for C++ on $1
sh mkt-int.sh -cxx \
    $CXX $CPPFLAGS $CXXFLAGS \
    -DMBSDINT_H_WANT_PTR_IN_SIZET \
    -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 \
    -DMBSDINT_H_WANT_SAFEC
echo ::endgroup::
