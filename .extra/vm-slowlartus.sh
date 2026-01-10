#!/bin/sh
#-
# © mirabilos Ⓕ MirBSD or CC0

switchgroup() {
	printf '::%s\n' 'endgroup::' "group::$*"
}
exec 2>&1
set -ex
LC_ALL=C LANGUAGE=C
export LC_ALL
unset LANGUAGE

echo ::group::Setup
CC=gcc
CXX=g++
: "${CC=cc}${CXX=c++}${CFLAGS=-O2}${CXXFLAGS=-O2}"
CFLAGS="$CFLAGS -Wall -Wextra -Wformat"
CXXFLAGS="$CXXFLAGS -Wall -Wextra -Wformat"
export CC CXX CPPFLAGS CFLAGS CXXFLAGS LDFLAGS
sh .extra/info.sh -m32
switchgroup Build for C
sh mkt-int.sh $CC $CPPFLAGS $CFLAGS \
    -DMBSDINT_H_WANT_PTR_IN_SIZET -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC
switchgroup Build for C++
sh mkt-int.sh -cxx $CXX $CPPFLAGS $CXXFLAGS \
    -DMBSDINT_H_WANT_PTR_IN_SIZET -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC
switchgroup Build ILP32 for C
CFLAGS="$CFLAGS -m32"
CXXFLAGS="$CXXFLAGS -m32"
sh mkt-int.sh $CC $CPPFLAGS $CFLAGS \
    -DMBSDINT_H_WANT_PTR_IN_SIZET -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC
switchgroup Build ILP32 for C++
sh mkt-int.sh -cxx $CXX $CPPFLAGS $CXXFLAGS \
    -Wno-type-limits \
    -DMBSDINT_H_WANT_PTR_IN_SIZET -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC
echo ::endgroup::
