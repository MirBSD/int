#!/bin/sh
#-
# © mirabilos Ⓕ MirBSD or CC0

exec 2>&1
set -ex
LC_ALL=C LANGUAGE=C
export LC_ALL
unset LANGUAGE

echo ::group::Setup
CC=gcc
CXX=g++
: "${CC=cc}${CXX=c++}${CFLAGS=-O2}${CXXFLAGS=-O2}"
export LDFLAGS
echo ::endgroup::
echo ::group::Build for C
sh mkt-int.sh $CC $CPPFLAGS $CFLAGS -Wall -Wextra -Wformat \
    -DMBSDINT_H_WANT_PTR_IN_SIZET -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC
echo ::endgroup::
echo ::group::Build for C++
sh mkt-int.sh -cxx $CXX $CPPFLAGS $CXXFLAGS -Wall -Wextra -Wformat \
    -DMBSDINT_H_WANT_PTR_IN_SIZET -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC
echo ::endgroup::
CFLAGS="$CFLAGS -m32"
CXXFLAGS="$CXXFLAGS -m32"
echo ::group::Build ILP32 for C
sh mkt-int.sh $CC $CPPFLAGS $CFLAGS -Wall -Wextra -Wformat \
    -DMBSDINT_H_WANT_PTR_IN_SIZET -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC
echo ::endgroup::
echo ::group::Build ILP32 for C++
sh mkt-int.sh -cxx $CXX $CPPFLAGS $CXXFLAGS -Wall -Wextra -Wformat \
    -DMBSDINT_H_WANT_PTR_IN_SIZET -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC
echo ::endgroup::
