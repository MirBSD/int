set -e
echo ::group::Setup $0 on Debian $2
cat >dummy.c <<\EOF
int main(void) { return (0); }
EOF
cp dummy.c dummy.cc
LC_ALL=C LANGUAGE=C DEBIAN_FRONTEND=noninteractive
export LC_ALL DEBIAN_FRONTEND
unset LANGUAGE
# configury
HAVE_CAN_QNOIPA=0
HAVE_CAN_XIPO_0=0
HAVE_CAN_WERROR=0
export HAVE_CAN_QNOIPA HAVE_CAN_XIPO_0 HAVE_CAN_WERROR
set -x
cat >>/etc/apt/apt.conf <<\EOF
debug::pkgproblemresolver "true";
APT::Install-Recommends "0";
EOF
apt-get update
if test x"$1" = x"slink"; then
	apt-get -y install bc gcc g++
else
	apt-get install -y bc build-essential
fi
: "${CC=cc}${CXX=c++}${CFLAGS=-O2}${CXXFLAGS=-O2}"
eval "$(env DEB_BUILD_MAINT_OPTIONS=hardening=+all dpkg-buildflags --export=sh || :)"
($CC $CPPFLAGS $CFLAGS -v dummy.c || :)
($CXX $CPPFLAGS $CXXFLAGS -v dummy.cc || :)
echo ::endgroup::
echo ::group::Build for C on $1
sh mkt-int.sh \
    $CC $CPPFLAGS $CFLAGS -Wall -W \
    -DMBSDINT_H_WANT_PTR_IN_SIZET \
    -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 \
    -DMBSDINT_H_WANT_LRG64 \
    -DMBSDINT_H_WANT_SAFEC
echo ::endgroup::
echo ::group::Build for C++ on $1
sh mkt-int.sh -cxx \
    $CXX $CPPFLAGS $CXXFLAGS -Wall -W \
    -DMBSDINT_H_WANT_PTR_IN_SIZET \
    -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 \
    -DMBSDINT_H_WANT_LRG64 \
    -DMBSDINT_H_WANT_SAFEC
echo ::endgroup::
