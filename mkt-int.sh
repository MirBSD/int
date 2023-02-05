#!/bin/sh
# $MirOS: int/mkt-int.sh,v 1.1 2023/02/05 16:55:01 tg Exp $
#-
# © 2023 mirabilos Ⓕ MirBSD

die() {
	echo >&2 "E: mkt-int.sh: $*"
	exit 1
}

if test -z "$1"; then
	echo >&2 'E: usage: sh mkt-int.sh $CC $CPPFLAGS $CFLAGS $LDFLAGS [-Dextra...]'
	echo >&2 'N: extra definitions can be:'
	echo >&2 'N:  -DMBSDINT_H_SMALL_SYSTEM=1/2/3'
	exit 3
fi

cd "$(dirname "$0")" || die cannot change to script directory
rm -f mkt-int.t* || die cannot delete old files
trap 'rm -f mkt-int.t*' EXIT

echo >&2 'I: checking if we can build at all'
set -e
cat >mkt-int.t-in.c <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
#include <limits.h>
#include <stddef.h>
#include <stdio.h>
typedef unsigned char but;
typedef signed char bst;
typedef unsigned short hut;
typedef signed short hst;
int main(void) { return (printf("Hi!\\n")); }
EOF
"$@" -o mkt-int.t-t mkt-int.t-in.c || die cannot build

echo >&2 'I: checking if we can add -fno-lto'
if "$@" -fno-lto -o mkt-int.t-t mkt-int.t-in.c; then
	set -- "$@" -fno-lto
fi

use_systypes='#include <sys/types.h>'
use_stdint='#include <stdint.h>'
use_icexp_rsmax=-DHAVE_INTCONSTEXPR_RSIZE_MAX

echo >&2 'I: checking if we have <sys/types.h>'
cat >mkt-int.t-in.c <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
#include <limits.h>
#include <stddef.h>
#include <stdio.h>
typedef unsigned char but;
typedef signed char bst;
typedef unsigned short hut;
typedef signed short hst;
int main(void) { return (printf("Hi!\\n")); }
EOF
"$@" -o mkt-int.t-t mkt-int.t-in.c || use_systypes=

echo >&2 'I: checking if we have <stdint.h>'
cat >mkt-int.t-in.c <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_stdint
#include <limits.h>
#include <stddef.h>
#include <stdio.h>
typedef unsigned char but;
typedef signed char bst;
typedef unsigned short hut;
typedef signed short hst;
int main(void) { return (printf("Hi!\\n")); }
EOF
"$@" -o mkt-int.t-t mkt-int.t-in.c || use_stdint=

echo >&2 'I: checking whether RSIZE_MAX is an integer constant expression'
cat >mkt-int.t-in.c <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_stdint
#include <limits.h>
#include <stddef.h>
#include <stdio.h>
typedef unsigned char but;
typedef signed char bst;
typedef unsigned short hut;
typedef signed short hst;
int tstarr[((int)(RSIZE_MAX) & 1) + 1] = {0};
#if defined(INTMAX_MIN)
#define mbiHUGE_U		uintmax_t
#elif defined(LLONG_MIN)
#define mbiHUGE_U		unsigned long long
#else
#define mbiHUGE_U		unsigned long
#endif
int tst2[((mbiHUGE_U)(RSIZE_MAX) == (mbiHUGE_U)(size_t)(RSIZE_MAX)) ? 1 : -1];
int main(void) { tst2[0] = tstarr[0]; return (printf("Hi!\\n")); }
EOF
"$@" $use_icexp_rsmax -o mkt-int.t-t mkt-int.t-in.c || use_icexp_rsmax=

xset() {
	v=have
	test -n "$1" || v=lack
}
echo >&2 'I: results so far:'
xset "$use_systypes"
echo >&2 "N: you $v <sys/types.h>"
xset "$use_stdint"
echo >&2 "N: you $v <stdint.h>"
xset "$use_icexp_rsmax"
echo >&2 "N: you $v an integer constant expression RSIZE_MAX"

echo >&2 'I: checking if compile-time checks pass'
cat >mkt-int.t-in.c <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_stdint
#undef MBSDINT_H_SKIP_CTAS
#include "mbsdint.h"
int main(void) { return (printf("Hi!\\n")); }
EOF
"$@" -o mkt-int.t-t mkt-int.t-in.c || die compile-time checks fail

echo >&2 'I: creating tests...'
cat - xxt-int.c >mkt-int.t-xx.c <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_stdint
#undef MBSDINT_H_SKIP_CTAS
#include "mbsdint.h"
#include "xxt-int.h"
EOF

cat >mkt-int.t-ff.c <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_stdint
#define MBSDINT_H_SKIP_CTAS 1
#include "mbsdint.h"
#include <stdio.h>

#include "xxt-int.h"
#include "mkt-int.t-ff.h"
EOF

cat >mkt-int.t-in.c <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_stdint
#define MBSDINT_H_SKIP_CTAS 1
#include "mbsdint.h"
#include <stdio.h>

#include "xxt-int.h"
#include "mkt-int.t-ff.h"

int rv = 0;
but bin1u, bin2u, boutu;
bst bin1s, bin2s, bouts;
hut hin1u, hin2u, houtu;
hst hin1s, hin2s, houts;
int iouts;
const char *fstr;

int main(void) {
EOF

echo "/* NeXTstep bug workaround */" >mkt-int.t-ff.h
numf=0

t1() { cat >>mkt-int.t-in.c <<EOF
	if (($1) != ($2)) {
		fprintf(stderr, "E: (%s) failed, got %lu want %lu (%s)\\n",
		    "$1", (unsigned long)($1), (unsigned long)($2), "$2");
		rv = 1;
	}
EOF
}

mbc1() {
	want=$(( ($1) * 2))
	bc >mkt-int.t-bc <<EOF
define f(x) {
$4
}
for (v = $2; v <= $3; ++v) {
	v
	f(v)
}
EOF
	got=$(wc -l <mkt-int.t-bc)
	test $got -eq $want || \
	    die got $got lines, not "$want", from bc "'$4'"
}

mbc1a() {
	want=$(( ($1) * 2))
	bc >mkt-int.t-bc2 <<EOF
define f(x) {
$4
}
for (v = $2; v <= $3; ++v) {
	v
	f(v)
}
EOF
	got=$(wc -l <mkt-int.t-bc2)
	test $got -eq $want || \
	    die got $got lines, not "$want", from bc "'$4'"
	cat mkt-int.t-bc2 >>mkt-int.t-bc
}

mba() {
	printf '%s\n' "$@" >>mkt-int.t-bc
}

ubc1() {
	fn=f$((numf++))
	echo "	$fn();" >>mkt-int.t-in.c
	echo "extern void $fn(void);" >>mkt-int.t-ff.h
    {
	echo "void $fn(void) {"
	echo "	fstr = \"$1\";"
	while read in; do
		read out
		echo "	tm1($2, $3, $1, $in, $out);"
	done <mkt-int.t-bc
	echo '}'
    } >>mkt-int.t-ff.c
}

t1 'mbiCOS(bst, -1, <, 2)' 1
t1 'mbiMOT(hut, hfm, 1, 0x1234, 0x5678)' 0x0234
t1 'mbiUP(but, bfm)' '0xFFU'
t1 'mbiUP(but, bhm)' '0x7FU'
t1 'mbiUP(hut, hfm)' '0x3FFU'
t1 'mbiUP(hut, hhm)' '0x1FFU'
t1 'mbiMM(hut, hfm, (hut)0xFFFFUL)' hfm
t1 'mbiMM(hut, hhm, (hut)0xFFFFUL)' hhm

mbc1 255 -127 127 '
	t=0
	if (x < 0) t=1
	return (t)'
ubc1 b_mbiA_S2VZ bin1s iouts

mbc1 256 0 255 '
	if (x > 127) return (1)
	return (0)'
ubc1 b_mbiA_U2VZ bin1u iouts

mbc1 1024 0 1023 '
	if (x > 511) return (1)
	return (0)'
mba	1024 0 \
	1534 0 \
	1535 0 \
	1536 1 \
	2047 1 \
	2048 0
ubc1 h_mbiMA_U2VZ hin1u iouts

mbc1 128 0 127 'return (x)'
mbc1a 127 129 255 'return (-(256 - x))'
ubc1 b_mbiA_U2S bin1u bouts

mbc1 512 0 511 'return (x)'
mbc1a 512 512 1023 'return (-(1024 - x))'
mba	1024 0 \
	1535 511 \
	1536 -512 \
	2047 -1 \
	2048 0
ubc1 h_mbiMA_U2S hin1u houts

mbc1 255 -127 127 '
	if (x >= 0) return (x)
	return (256 + x)'
ubc1 b_mbiA_S2U bin1s boutu

mbc1 1024 -512 511 '
	if (x >= 0) return (x)
	return (1024 + x)'
ubc1 b_mbiMA_S2U hin1s houtu

mbc1 127 -127 -1 'return (-x)'
mbc1a 128 0 127 'return (x)'
ubc1 b_mbiA_S2M bin1s boutu

mbc1 512 -512 -1 'return (-x)'
mbc1a 512 0 511 'return (x)'
ubc1 h_mbiMA_S2M hin1s houtu

mbc1 128 0 127 'return (x)'
mbc1a 128 128 255 'return (256 - x)'
ubc1 b_mbiA_U2M bin1u boutu

mbc1 512 0 511 'return (x)'
mbc1a 512 512 1023 'return (1024 - x)'
mba	1024 0 \
	1534 510 \
	1535 511 \
	1536 512 \
	1537 511 \
	1538 510 \
	2046 2 \
	2047 1 \
	2048 0
ubc1 h_mbiMA_U2M hin1u houtu

if false; then
mbiMO	via mbiMA_VZM2S
mbiOshl
mbiOshr
fi


cat >>mkt-int.t-in.c <<\EOF

	return (rv);
}
EOF
echo >&2 'I: running tests...'
"$@" -c mkt-int.t-xx.c || die compiling tests-xx failed
"$@" -c mkt-int.t-in.c || die compiling tests-mk failed
"$@" -O0 -g0 -c mkt-int.t-ff.c || die compiling tests-mk failed
"$@" -o mkt-int.t-t mkt-int.t-xx.o mkt-int.t-in.o mkt-int.t-ff.o || die linking tests failed
if ./mkt-int.t-t; then
	echo >&2 'I: tests passed'
	exit 0
fi
echo >&2 'E: tests failed; press Return to continue'
read dummy
