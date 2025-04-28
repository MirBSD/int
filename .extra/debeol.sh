#!/bin/sh
#-
# © mirabilos Ⓕ MirBSD or CC0
exec 2>&1
set -ex
LC_ALL=C LANGUAGE=C DEBIAN_FRONTEND=noninteractive
export LC_ALL DEBIAN_FRONTEND
unset LANGUAGE
echo ::group::Setup $0 on Debian $2
nocxx=false
case $1 in
jessie)
	cat >/etc/apt/sources.list <<\EOF
deb http://archive.debian.org/debian/ jessie main non-free contrib
deb http://archive.debian.org/debian-security/ jessie/updates main non-free contrib
EOF
	rm -f /etc/apt/sources.list.d/*
	;;
stretch)
	cat >/etc/apt/sources.list <<\EOF
deb http://archive.debian.org/debian/ stretch main non-free contrib
deb http://archive.debian.org/debian-security/ stretch/updates main non-free contrib
EOF
	rm -f /etc/apt/sources.list.d/*
	;;
experimental)
	rm -f /etc/apt/sources.list /etc/apt/sources.list.d/*
	cat >/etc/apt/sources.list.d/sid.sources <<\EOF
Types: deb
URIs: http://deb.debian.org/debian/
Suites: sid
Components: main non-free-firmware non-free contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
	cat >/etc/apt/sources.list.d/experimental.sources <<\EOF
Types: deb
URIs: http://deb.debian.org/debian/
Suites: experimental
Components: main non-free-firmware non-free contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
	;;
esac
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
APT::Install-Recommends "0";
EOF
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
	apt-get -d -y install bc gcc g++
	dpkg -i /var/cache/apt/archives/*.deb
	;;
experimental)
	apt-get install -t experimental -y bc build-essential \
	    binutils cpp gcc g++
	;;
*)
	apt-get install -y bc build-essential
	;;
esac
: "${CC=cc}${CXX=c++}${CFLAGS=-O2}${CXXFLAGS=-O2}"
export CC CXX
eval "$(env DEB_BUILD_MAINT_OPTIONS=hardening=+all dpkg-buildflags --export=sh || :)"
case $1 in
experimental)
	CFLAGS="$CFLAGS -Wall -Wextra -Wformat -Wformat-security"
	CXXFLAGS="$CXXFLAGS -Wall -Wextra -Wformat -Wformat-security"
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
export LDFLAGS
($CC $CPPFLAGS $CFLAGS $LDFLAGS -v dummy.c || :)
$nocxx || ($CXX $CPPFLAGS $CXXFLAGS $LDFLAGS -v dummy.cc || :)
echo ::endgroup::
echo ::group::Build for C on $1
sh mkt-int.sh \
    $CC $CPPFLAGS $CFLAGS \
    -DMBSDINT_H_WANT_PTR_IN_SIZET \
    -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 \
    -DMBSDINT_H_WANT_SAFEC
echo ::endgroup::
if $nocxx; then exit 0; fi
echo ::group::Build for C++ on $1
sh mkt-int.sh -cxx \
    $CXX $CPPFLAGS $CXXFLAGS \
    -DMBSDINT_H_WANT_PTR_IN_SIZET \
    -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 \
    -DMBSDINT_H_WANT_SAFEC
echo ::endgroup::
