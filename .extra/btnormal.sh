#!/bin/sh
#-
# © mirabilos Ⓕ MirBSD or CC0

switchgroup() {
	printf '::%s\n' 'endgroup::' "group::$*"
}
exec 2>&1
echo ::group::Begin
: "${CC=cc}${CXX=c++}${CFLAGS=-O2}${CXXFLAGS=-O2}"
eval "$(env DEB_BUILD_MAINT_OPTIONS='future=+all qa=+all,-canary optimize=+all,-lto hardening=+all reproducible=+all' \
    dpkg-buildflags --export=sh || :)"
set -- -Wall -Wextra -Wformat
CFLAGS="$CFLAGS $*"
CXXFLAGS="$CXXFLAGS $*"
set -ex
export CC CXX CPPFLAGS CFLAGS CXXFLAGS LDFLAGS
sh .extra/info.sh
switchgroup Build for C
sh mkt-int.sh $CC $CPPFLAGS $CFLAGS \
    -DMBSDINT_H_WANT_PTRV_IN_SIZET -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC
switchgroup Build for C++
sh mkt-int.sh -cxx $CXX $CPPFLAGS $CXXFLAGS \
    -DMBSDINT_H_WANT_PTRV_IN_SIZET -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC
echo ::endgroup::
