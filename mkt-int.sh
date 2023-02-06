#!/bin/sh
# $MirOS: src/kern/include/mkt-int.sh,v 1.5 2023/02/06 01:33:55 tg Exp $
#-
# © 2023 mirabilos Ⓕ MirBSD

# Warning: stress test, creates multiple multi-MiB object files and runs it!

BC_ENV_ARGS=-qs LC_ALL=C LANGUAGE=C
unset LANGUAGE
export BC_ENV_ARGS LC_ALL
nl='
'

die() {
	echo >&2 "E: mkt-int.sh: $*"
	exit 1
}

if test -z "$1"; then
	echo >&2 'E: usage: LDFLAGS=$LDFLAGS sh mkt-int.sh $CC $CPPFLAGS $CFLAGS [-Dextra...]'
	echo >&2 'N: extra definitions can be:'
	echo >&2 'N:  -DMBSDINT_H_SMALL_SYSTEM=1/2/3'
	exit 3
fi

cd "$(dirname "$0")" || die cannot change to script directory
rm -f mkt-int.t* || die cannot delete old files
test -n "$DEBUG" || trap 'rm -f mkt-int.t*' EXIT

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
/* it can easily be ported to allow CHAR_BIT ≠ 8 if needed */
int testsuite_assumes_char_has_8_bits[(CHAR_BIT) == 8 ? 1 : -1];
int main(void) {
	return ((int)sizeof(testsuite_assumes_char_has_8_bits) +
	    printf("Hi!\\n"));
}
EOF
"$@" $LDFLAGS -o mkt-int.t-t mkt-int.t-in.c || die cannot build

echo >&2 'I: checking if we can add -fno-lto'
if "$@" $LDFLAGS -fno-lto -o mkt-int.t-t mkt-int.t-in.c; then
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
"$@" $LDFLAGS -o mkt-int.t-t mkt-int.t-in.c || use_systypes=

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
"$@" $LDFLAGS -o mkt-int.t-t mkt-int.t-in.c || use_stdint=

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
"$@" $LDFLAGS $use_icexp_rsmax -o mkt-int.t-t mkt-int.t-in.c || use_icexp_rsmax=

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
#include <stdio.h>
int main(void) { return (printf("Hi!\\n")); }
EOF
"$@" $LDFLAGS -o mkt-int.t-t mkt-int.t-in.c || die compile-time checks fail

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

fffile=0
newfff() {
	curfff=mkt-int.t-f$((fffile++)).c
	cat >$curfff <<EOF
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
}
newfff

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

static void c2_(const char *where) {
	fprintf(stderr, "E: %s(%02X, %u) failed, got %02X want %02X\n",
	    where, (unsigned)hin1u, (unsigned)hin2u,
	    (unsigned)boutu, (unsigned)iouts);
	rv = 1;
}
static void cs_(const char *where) {
	fprintf(stderr, "E: %s(%d, %d) failed, got %d want %d\n",
	    where, (signed)hin1s, (signed)hin2s,
	    (signed)bouts, (signed)iouts);
	rv = 1;
}
static void cf_(const char *where) {
	fprintf(stderr, "E: %s(%02X, %u) overflow: want %d got %d\n",
	    where, (unsigned)hin1u, (unsigned)hin2u, houts, hin1s);
	rv = 1;
}
#define c2(where) do {				\
	if (boutu != (unsigned)iouts)		\
		c2_(where);			\
} while (/* CONSTCOND */ 0)
#define C2u(where) do {				\
	if (hin1s != houts)			\
		cf_(where);			\
	else if (!hin1s &&			\
	    (boutu != (unsigned)iouts))		\
		c2_(where);			\
} while (/* CONSTCOND */ 0)
#define C2s(where) do {				\
	if (hin1u != houtu)			\
		cf_(where);			\
	else if (!hin1u &&			\
	    (bouts != iouts))			\
		cs_(where);			\
} while (/* CONSTCOND */ 0)

int main(void) {
	fprintf(stderr, "I: initial tests...\n");
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
	:>mkt-int.t-bc
	mbc1a "$@"
}

mbc1a() {
	want=$(( ($1) * 2))
	bc >mkt-int.t-bc2 <<EOF
define f(x) {
${4#$nl}
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

mbc2() {
	:>mkt-int.t-bc
	mbc2a "$@"
}

mbc2a() {
	want=$(( ($1) * 3))
	bc >mkt-int.t-bc2 <<EOF
define f(x,y) {
${6#$nl}
}
for (v = $2; v <= $3; ++v) {
	for (w = $4; w <= $5; ++w) {
		v
		w
		f(v,w)
	}
}
EOF
	got=$(wc -l <mkt-int.t-bc2)
	test $got -eq $want || \
	    die got $got lines, not "$want", from bc "'$6'"
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
    } >>$curfff
}

ubc2() {
	fn=f$((numf++))
	echo "	$fn();" >>mkt-int.t-in.c
	echo "extern void $fn(void);" >>mkt-int.t-ff.h
    {
	echo "void $fn(void) {"
	echo "	fstr = \"$1\";"
	while read in1; do
		read in2
		read out
		echo "	tm2($2, $3, $4, $1, $in1, $in2, $out);"
	done <mkt-int.t-bc
	echo '}'
    } >>$curfff
}

t1 'mbiCOS(bst, -1, <, 2)' 1
t1 'mbiMOT(hut, hfm, 1, 0x1234, 0x5678)' 0x0234
t1 'mbiUP(but, bfm)' '0xFFU'
t1 'mbiUP(but, bhm)' '0x7FU'
t1 'mbiUP(hut, hfm)' '0x3FFU'
t1 'mbiUP(hut, hhm)' '0x1FFU'
t1 'mbiMM(hut, hfm, (hut)0xFFFFUL)' hfm
t1 'mbiMM(hut, hhm, (hut)0xFFFFUL)' hhm

cat >>mkt-int.t-in.c <<\EOF
	fprintf(stderr, "I: manual two’s complement in unsigned...\n");
EOF

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

newfff

mbc2 256 0 1 0 127 '
	if (y == 0) return (0)
	if (x == 0) return (y)
	return (-y)'
ubc2 b_mbiA_VZM2S bin1u bin2u bouts

mbc2 4096 0 0 0 4095 'return (y % 512)'
mbc2a 4096 1 1 0 4095 '
	if ((y % 1024) == 0) return (0)
	return (-((y - 1) % 512) - 1)'
ubc2 h_mbiMA_VZM2S hin1u hin2u houts

newfff

mbc2 512 0 1 0 255 '
	if (y == 0) return (0)
	if (x == 0) return (y % 128)
	a = (-((y - 1) % 128) - 1)
	while (a < 0) a += 256
	return (a)'
ubc2 b_mbiA_VZM2U bin1u bin2u boutu

mbc2 8192 0 1 0 4095 '
	if ((y % 1024) == 0) return (0)
	if (x == 0) return (y % 512)
	a = (-((y - 1) % 512) - 1)
	while (a < 0) a += 1024
	return (a)'
ubc2 h_mbiMA_VZM2U hin1u hin2u houtu

newfff

mbc2 512 0 1 0 255 'if (x != 0) y = -y
while (y < 0) y += 256
return (y)'
ubc2 b_mbiA_VZU2U bin1u bin2u boutu

mbc2 8192 0 1 0 4095 'if (x != 0) y = -y
while (y < 0) y += 1024
return (y % 1024)'
ubc2 h_mbiMA_VZU2U hin1u hin2u houtu

newfff

cat >>mkt-int.t-in.c <<\EOF
	fprintf(stderr, "I: overflow/underflow-checking unsigned...\n");

#define mbiCfail hin1s = 1
	for (hin1u = 0; hin1u < UCHAR_MAX; ++hin1u)
		for (hin2u = 0; hin2u < UCHAR_MAX; ++hin2u) {
			hin1s = 0;
			boutu = hin1u;
			mbiCAUadd(boutu, hin2u);
			iouts = hin1u + hin2u;
			houts = (iouts < 0) || (iouts > UCHAR_MAX);
			C2u("mbiCAUadd");

			hin1s = 0;
			boutu = hin1u;
			mbiCAUsub(boutu, hin2u);
			iouts = hin1u - hin2u;
			houts = (iouts < 0) || (iouts > UCHAR_MAX);
			C2u("mbiCAUsub");

			hin1s = 0;
			boutu = hin1u;
			mbiCAUmul(but, boutu, hin2u);
			iouts = hin1u * hin2u;
			houts = (iouts < 0) || (iouts > UCHAR_MAX);
			C2u("mbiCAUmul");
		}
#undef mbiCfail

	fprintf(stderr, "I: overflow/underflow-checking signed...\n");
#define mbiCfail hin1u = 1
	for (hin1s = SCHAR_MIN; hin1s < SCHAR_MAX; ++hin1s)
		for (hin2s = SCHAR_MIN; hin2s < SCHAR_MAX; ++hin2s) {
		    if (hin2s == 1) {
			hin1u = 0;
			mbiCASlet(bst, bin1s, hst, hin1s);
			if (hin1u) {
				fprintf(stderr, "E: mbiCASlet(%d) failed\n", hin1s);
				rv = 1;
			}

			hin1u = 0;
			bouts = hin1s;
			mbiCASinc(SCHAR, bouts);
			iouts = hin1s + hin2s;
			houtu = (iouts < SCHAR_MIN) || (iouts > SCHAR_MAX);
			C2s("mbiCASinc");

			hin1u = 0;
			bouts = hin1s;
			mbiCASdec(SCHAR, bouts);
			iouts = hin1s - hin2s;
			houtu = (iouts < SCHAR_MIN) || (iouts > SCHAR_MAX);
			C2s("mbiCASdec");
		    }
		    if (hin2s >= 0) {
			hin1u = 0;
			bouts = hin1s;
			mbiCAPadd(SCHAR, bouts, hin2s);
			iouts = hin1s + hin2s;
			houtu = (iouts < SCHAR_MIN) || (iouts > SCHAR_MAX);
			C2s("mbiCAPadd");

			hin1u = 0;
			bouts = hin1s;
			mbiCAPsub(SCHAR, bouts, hin2s);
			iouts = hin1s - hin2s;
			houtu = (iouts < SCHAR_MIN) || (iouts > SCHAR_MAX);
			C2s("mbiCAPsub");

			hin1u = 0;
			bouts = hin1s;
			mbiCAPmul(SCHAR, bouts, hin2s);
			iouts = hin1s * hin2s;
			houtu = (iouts < SCHAR_MIN) || (iouts > SCHAR_MAX);
			C2s("mbiCAPmul");
		    }

			hin1u = 0;
			bouts = hin1s;
			mbiCASadd(SCHAR, bouts, hin2s);
			iouts = hin1s + hin2s;
			houtu = (iouts < SCHAR_MIN) || (iouts > SCHAR_MAX);
			C2s("mbiCASadd");

			hin1u = 0;
			bouts = hin1s;
			mbiCASsub(SCHAR, bouts, hin2s);
			iouts = hin1s - hin2s;
			houtu = (iouts < SCHAR_MIN) || (iouts > SCHAR_MAX);
			C2s("mbiCASsub");

			hin1u = 0;
			bouts = hin1s;
			mbiCASmul(SCHAR, bouts, hin2s);
			iouts = hin1s * hin2s;
			houtu = (iouts < SCHAR_MIN) || (iouts > SCHAR_MAX);
			C2s("mbiCASmul");
		}

	fprintf(stderr, "I: manual two’s komplement calculations...\n");
EOF

for split in '0 63' '64 127' '128 191' '192 255'; do
mbc2 16384 $split 0 255 '
	if (x == y) return (0)
	if (x > 127) x = -(256 - x)
	if (y > 127) y = -(256 - y)
	if (x < y) return (-1)
	return (1)'
ubc2 b_mbiKcmp bin1u bin2u iouts
newfff
done

mbc2 256 0 15 0 15 '
	if (x == y) return (0)
	if (x > 7) x = -(16 - x)
	if (y > 7) y = -(16 - y)
	if (x < y) return (-1)
	return (1)'
ubc2 x_mbiMKcmp bin1u bin2u iouts

cat >>mkt-int.t-in.c <<\EOF
	for (hin1u = 0; hin1u < 256; ++hin1u)
		for (hin2u = 0; hin2u < 8; ++hin2u) {
			boutu = b_mbiKrol(hin1u, hin2u);
			iouts = th_rol(8, hin1u, hin2u);
			c2("b_mbiKrol");
			boutu = b_mbiKror(hin1u, hin2u);
			iouts = th_ror(8, hin1u, hin2u);
			c2("b_mbiKror");
			boutu = b_mbiKshl(hin1u, hin2u);
			iouts = th_shl(8, hin1u, hin2u);
			c2("b_mbiKshl");
			boutu = b_mbiKshr(hin1u, hin2u);
			iouts = th_shr(8, hin1u, hin2u);
			c2("b_mbiKshr");
			boutu = b_mbiKsar(hin1u, hin2u);
			iouts = th_sar(8, hin1u, hin2u);
			c2("b_mbiKsar");
		}
	for (hin1u = 0; hin1u < 16; ++hin1u)
		for (hin2u = 0; hin2u <= 8; ++hin2u) {
			boutu = x_mbiMKrol(hin1u, hin2u);
			iouts = th_rol(4, hin1u, hin2u);
			c2("x_mbiMKrol");
			boutu = x_mbiMKror(hin1u, hin2u);
			iouts = th_ror(4, hin1u, hin2u);
			c2("x_mbiMKror");
			boutu = x_mbiMKshl(hin1u, hin2u);
			iouts = th_shl(4, hin1u, hin2u);
			c2("x_mbiMKshl");
			boutu = x_mbiMKshr(hin1u, hin2u);
			iouts = th_shr(4, hin1u, hin2u);
			c2("x_mbiMKshr");
			boutu = x_mbiMKsar(hin1u, hin2u);
			iouts = th_sar(4, hin1u, hin2u);
			c2("x_mbiMKsar");
		}
EOF

for split in '0 63' '64 127' '128 191' '192 255'; do
mbc2 16320 $split 1 255 '
	s = 1
	if (x > 127) {
		x = 256 - x
		s = -1
	}
	if (y > 127) {
		y = 256 - y
		s *= -1
	}
	s *= (x / y)
	while (s < 0) s += 256
	return (s)'
ubc2 b_mbiKdiv bin1u bin2u boutu
newfff
done

mbc2 240 0 15 1 15 '
	s = 1
	if (x > 7) {
		x = 16 - x
		s = -1
	}
	if (y > 7) {
		y = 16 - y
		s *= -1
	}
	s *= (x / y)
	while (s < 0) s += 16
	return (s)'
ubc2 x_mbiMKdiv bin1u bin2u boutu

newfff

for split in '0 63' '64 127' '128 191' '192 255'; do
mbc2 16320 $split 1 255 '
	r = 1
	if (x > 127) {
		x = 256 - x
		r = -1
	}
	if (y > 127) {
		y = 256 - y
	}
	s = (x / y)
	r *= x - (s * y)
	while (r < 0) r += 256
	return (r)'
ubc2 b_mbiKrem bin1u bin2u boutu
newfff
done

mbc2 240 0 15 1 15 '
	r = 1
	if (x > 7) {
		x = 16 - x
		r = -1
	}
	if (y > 7) {
		y = 16 - y
	}
	s = (x / y)
	r *= x - (s * y)
	while (r < 0) r += 16
	return (r)'
ubc2 x_mbiMKrem bin1u bin2u boutu

cat >>mkt-int.t-in.c <<\EOF
	fprintf(stderr, "I: final tests...\n");
EOF

t1 'mbi_nil == NULL' 1

cat >>mkt-int.t-in.c <<\EOF

	return (rv);
}
EOF
echo >&2 'I: running tests...'
set -x
rm -f mkt-int.t-*.o
"$@" -c mkt-int.t-xx.c || die compiling tests-xx failed
"$@" -c mkt-int.t-in.c || die compiling tests-mk failed
ffcur=0
while test $ffcur -lt $fffile; do
	curfff=mkt-int.t-f$((ffcur++)).c
	"$@" -O0 -g0 -c $curfff || die compiling $curfff failed
done
"$@" $LDFLAGS -o mkt-int.t-t mkt-int.t-*.o || die linking tests failed
set +e
./mkt-int.t-t
rv=$?
set +x
if test "$rv" = 0; then
	echo >&2 'I: tests passed'
	exit 0
fi
echo >&2 'E: tests failed; press Return to continue'
read dummy
exit 1
