#!/bin/sh
rcsid='$MirOS: int/mkt-int.sh,v 1.46 2024/04/02 03:16:50 tg Exp $'
#-
# © mirabilos Ⓕ MirBSD

# Warning: stress test, creates multiple multi-MiB .c files, .o about half each

set -e

BC_ENV_ARGS=-qs LC_ALL=C LANGUAGE=C
unset LANGUAGE
export BC_ENV_ARGS LC_ALL
nl='
'
ht='	'
rcsid="$rcsid ($*|$LDFLAGS)"

die() {
	w=false
	if test x"$1" = x"-w"; then
		w=true
		shift
	fi
	echo >&2 "E: mkt-int.sh: $*"
	if $w; then
		echo >&2 'N: press Return to continue'
		read dummy
	fi
	exit 1
}

v() { (
	set -x
	exec "$@"
); }

if test x"$1" = x"-cxx"; then
	shift
	usecxx=true
else
	usecxx=false
fi

if test x"$1" = x"-x"; then
	shift
	cross=true
else
	cross=false
fi

if test -z "$1"; then cat >&2 <<\EOF
E: usage: LDFLAGS=$LDFLAGS sh mkt-int.sh [-cxx] [-x] \
              $CC $CPPFLAGS $CFLAGS [-Dextra...]
N: -cxx = build as CFrustFrust
N: -x = cross-compile
N: extra definitions can be:
N:  -DMBSDINT_H_SMALL_SYSTEM=1/2/3
N:  -DMBSDINT_H_MBIPTR_IS_SIZET=0 (if sizet_mbiPTRU fails)
N:  -DMBSDINT_H_MBIPTR_IN_LARGE=0 (+ mbiPTRU_inlarge, do report!)
N:  -DMBSDINT_H_WANT_LONG_IN_SIZET=0 (for 16-bit size_t from int)
N:  -DMBSDINT_H_WANT_PTR_IN_SIZET (extra check, see below)
N:  -DMBSDINT_H_WANT_SIZET_IN_LONG (extra check, !Win64)
N:  -DMBSDINT_H_WANT_INT32 (extra check, POSIX guaranteed)
N:  -DMBSDINT_H_WANT_LRG64 (ensure a 64-bit type exists)
N:  -DMBSDINT_H_WANT_SAFEC (test safe twos complement)
EOF
	exit 3
fi

test "$(bc <<\EOF
define f(x) {
return (-(256 - x))
}
for (v = 4; v <= 5; ++v) {
	v
	f(v)
}
EOF
)" = "4${nl}-252${nl}5${nl}-251" || die 'bc(1) inoperable'

cd "$(dirname "$0")" || die cannot change to script directory
rm -f mkt-int-t* || die cannot delete old files
test -n "$DEBUG" || trap 'rm -f mkt-int-t*' EXIT

srcext=c
case " $* " in
*\ do-cl.bat\ *)
	Fe=/Fe
	objext=obj
	$usecxx && srcext=cxx || :
	;;
*\ wcl\ *|*\ wcl386\ *)
	Fe=-fe=
	objext=obj
	set -- "$@" "-fo=.$objext"
	$usecxx && srcext=cc || :
	;;
*)
	Fe='-o '
	objext=o
	$usecxx && srcext=cc || :
	;;
esac

echo >&2 'I: testing whether we can detect configure failures...'
canfail=false
cat >mkt-int-t-in.$srcext <<EOF
extern int thiswillneverbedefinedIhope(void);
int main(void) { return (thiswillneverbedefinedIhope()); }
EOF
v "$@" $LDFLAGS ${Fe}mkt-int-t-t.exe mkt-int-t-in.$srcext || canfail=true
$canfail || die cannot fail

echo >&2 'I: checking if we can build at all'
cat >mkt-int-t-in.$srcext <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
#include <limits.h>
#include <stdio.h>
#include <time.h>
#include "mbsdcc.h"
typedef unsigned char but;
typedef signed char bst;
typedef unsigned short hut;
typedef signed short hst;
mbCTA_BEG(check);
 /* it can easily be ported to allow CHAR_BIT ≠ 8, if needed */
 mbCTA(testsuite_assumes_char_has_8_bits, (CHAR_BIT) == 8);
mbCTA_END(check);
int main(void) {
	return (printf("Hi!\\n"));
}
EOF
v "$@" $LDFLAGS ${Fe}mkt-int-t-t.exe mkt-int-t-in.$srcext || die cannot build
$cross || test "$(set +e; ./mkt-int-t-t.exe; echo $?)" = "Hi!${nl}4" || die fails to run
rm -f mkt-int-t-t.exe
echo >&2 'I: checking if we can compile and link separately'
v "$@" -c mkt-int-t-in.$srcext || die cannot compile
v "$@" $LDFLAGS ${Fe}mkt-int-t-t.exe mkt-int-t-*.$objext || die cannot link
$cross || test "$(set +e; ./mkt-int-t-t.exe; echo $?)" = "Hi!${nl}4" || die fails to run

test -n "$TARGET_OS" || TARGET_OS=$(uname -s 2>/dev/null || uname)

flagstotest=-Werror
case $TARGET_OS in
MirBSD)
	;;
*)
	flagstotest="$flagstotest -fno-lto -qnoipa -xipo=0"
	;;
esac
case " $* " in
*\ do-cl.bat\ *)
	flagstotest='/WX' ;;
*\ owcc\ *|*\ wcl\ *|*\ wcl386\ *)
	flagstotest= ;;
esac
for flagtotest in $flagstotest; do
	varname=$(echo "X$flagtotest" | sed \
	    -e 's!^X[/-]*!HAVE_CAN_!' | tr \
	    qwertyuiopasdfghjklzxcvbnm/=- \
	    QWERTYUIOPASDFGHJKLZXCVBNM___)
	eval "varvalue=\${$varname-x}"
	case $varvalue in
	0)
		echo >&2 "I: skipping trying to add $flagtotest"
		continue
		;;
	1)
		echo >&2 "I: forcing to add $flagtotest"
		set -- "$@" $flagtotest
		continue
		;;
	esac
	echo >&2 "I: checking if we can add $flagtotest"
	if v "$@" $LDFLAGS $flagtotest ${Fe}mkt-int-t-t.exe mkt-int-t-in.$srcext; then
		set -- "$@" $flagtotest
	fi
done

use_systypes='#include <sys/types.h>'
use_stdint='#include <stdint.h>'
use_inttypes='#include <inttypes.h>'
use_basetsd='#include <basetsd.h>'
use_icexp_rsmax=-DHAVE_INTCONSTEXPR_RSIZE_MAX
have_offt=1

echo >&2 'I: checking if we have <sys/types.h>'
cat >mkt-int-t-in.$srcext <<EOF
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
v "$@" $LDFLAGS ${Fe}mkt-int-t-t.exe mkt-int-t-in.$srcext || use_systypes=

echo >&2 'I: checking if we have <inttypes.h>'
cat >mkt-int-t-in.$srcext <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_inttypes
#include <limits.h>
#include <stddef.h>
#include <stdio.h>
typedef unsigned char but;
typedef signed char bst;
typedef unsigned short hut;
typedef signed short hst;
int main(void) { return (printf("Hi!\\n")); }
EOF
v "$@" $LDFLAGS ${Fe}mkt-int-t-t.exe mkt-int-t-in.$srcext || use_inttypes=

echo >&2 'I: checking if we have <stdint.h>'
cat >mkt-int-t-in.$srcext <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_inttypes
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
v "$@" $LDFLAGS ${Fe}mkt-int-t-t.exe mkt-int-t-in.$srcext || use_stdint=

echo >&2 'I: checking if we have <basetsd.h>'
cat >mkt-int-t-in.$srcext <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_inttypes
$use_stdint
$use_basetsd
#include <limits.h>
#include <stddef.h>
#include <stdio.h>
typedef unsigned char but;
typedef signed char bst;
typedef unsigned short hut;
typedef signed short hst;
int main(void) { return (printf("Hi!\\n")); }
EOF
v "$@" $LDFLAGS ${Fe}mkt-int-t-t.exe mkt-int-t-in.$srcext || use_basetsd=

echo >&2 'I: checking whether RSIZE_MAX is an integer constant expression'
cat >mkt-int-t-in.$srcext <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_inttypes
$use_stdint
$use_basetsd
#include <limits.h>
#include <stdio.h>
#include "mbsdcc.h"
typedef unsigned char but;
typedef signed char bst;
typedef unsigned short hut;
typedef signed short hst;
#ifdef _MSC_VER
#pragma warning(disable:4310)
#endif
int tstarr[((int)mbccCEX(RSIZE_MAX) & 1) + 1] = {0};
#if defined(INTMAX_MIN)
#define mbiHUGE_U		uintmax_t
#elif defined(LLONG_MIN)
#define mbiHUGE_U		unsigned long long
#elif defined(_UI64_MAX)
#define mbiHUGE_U		unsigned __int64
#elif defined(QUAD_MIN)
#define mbiHUGE_U		u_quad_t
#else
#define mbiHUGE_U		unsigned long
#endif
mbCTA_BEG(check);
 mbCTA(fits_sizet, (mbiHUGE_U)(RSIZE_MAX) == (mbiHUGE_U)(size_t)(RSIZE_MAX));
mbCTA_END(check);
int main(void) { return (printf("Hi! %d\\n", tstarr[0])); }
EOF
v "$@" $LDFLAGS $use_icexp_rsmax ${Fe}mkt-int-t-t.exe mkt-int-t-in.$srcext || use_icexp_rsmax=
set -- "$@" $use_icexp_rsmax

echo >&2 'I: checking for off_t'
cat >mkt-int-t-in.$srcext <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_inttypes
$use_stdint
$use_basetsd
#include <limits.h>
#include <stddef.h>
#include <stdio.h>
typedef unsigned char but;
typedef signed char bst;
typedef unsigned short hut;
typedef signed short hst;
int main(void) { return ((int)sizeof(off_t)); }
EOF
v "$@" $LDFLAGS ${Fe}mkt-int-t-t.exe mkt-int-t-in.$srcext || have_offt=0
set -- "$@" -DHAVE_OFF_T=$have_offt

xset() {
	v=have
	test -n "$1" || v=lack
}
echo >&2 'I: results so far:'
xset "$use_systypes"
echo >&2 "N: you $v <sys/types.h>"
xset "$use_basetsd"
echo >&2 "N: you $v <basetsd.h>"
xset "$use_inttypes"
echo >&2 "N: you $v <inttypes.h>"
xset "$use_stdint"
echo >&2 "N: you $v <stdint.h>"
xset "$use_icexp_rsmax"
echo >&2 "N: you $v an integer constant expression RSIZE_MAX"

echo >&2 'I: checking if compile-time checks pass'
cat >mkt-int-t-in.$srcext <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_inttypes
$use_stdint
$use_basetsd
#undef MBSDINT_H_SKIP_CTAS
#include "mbsdcc.h"
#include "mbsdint.h"
#include <stdio.h>
int main(void) { return (printf("Hi!\\n")); }
EOF
v "$@" $LDFLAGS ${Fe}mkt-int-t-t.exe mkt-int-t-in.$srcext || die compile-time checks fail

use_float='#include <float.h>'
echo >&2 'I: checking if we have <float.h>'
cat >mkt-int-t-in.$srcext <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_inttypes
$use_stdint
$use_basetsd
$use_float
#include <limits.h>
#include <stddef.h>
#include <stdio.h>
int main(void) { return (printf("Hi!\\n")); }
EOF
v "$@" $LDFLAGS ${Fe}mkt-int-t-t.exe mkt-int-t-in.$srcext || die use_float=

echo >&2 'I: creating tests... (can take very long)'
cat - xxt-int.c >mkt-int-t-xx.$srcext <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_inttypes
$use_stdint
$use_basetsd
#undef MBSDINT_H_SKIP_CTAS
#include "mbsdcc.h"
#include "mbsdint.h"
#include "xxt-int.h"
#include <string.h>
EOF

for x in 0 1 2; do
	cat >mkt-int-t-f$x.$srcext <<EOF
#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_inttypes
$use_stdint
$use_basetsd
#define MBSDINT_H_SKIP_CTAS 1
#include "mbsdcc.h"
#include "mbsdint.h"
#include <stdio.h>

#include "xxt-int.h"
#include "mkt-int-t-ff.h"
EOF
done

cat >mkt-int-t-in.$srcext <<EOF
#define S(x) #x
#define s(x) S(x)
#ifdef MBSDINT_H_MBIPTR_IS_SIZET
static const char oMBSDINT_H_MBIPTR_IS_SIZET[] = "passed '" s(MBSDINT_H_MBIPTR_IS_SIZET) "'";
#else
static const char oMBSDINT_H_MBIPTR_IS_SIZET[] = "not passed";
#endif
#ifdef MBSDINT_H_MBIPTR_IN_LARGE
static const char oMBSDINT_H_MBIPTR_IN_LARGE[] = "passed '" s(MBSDINT_H_MBIPTR_IN_LARGE) "'";
#else
static const char oMBSDINT_H_MBIPTR_IN_LARGE[] = "not passed";
#endif
#ifdef MBSDINT_H_WANT_LONG_IN_SIZET
static const char oMBSDINT_H_WANT_LONG_IN_SIZET[] = "passed '" s(MBSDINT_H_WANT_LONG_IN_SIZET) "'";
#else
static const char oMBSDINT_H_WANT_LONG_IN_SIZET[] = "not passed";
#endif
#ifdef MBSDINT_H_WANT_PTR_IN_SIZET
static const char oMBSDINT_H_WANT_PTR_IN_SIZET[] = "passed '" s(MBSDINT_H_WANT_PTR_IN_SIZET) "'";
#else
static const char oMBSDINT_H_WANT_PTR_IN_SIZET[] = "not passed";
#endif
#ifdef MBSDINT_H_WANT_SIZET_IN_LONG
static const char oMBSDINT_H_WANT_SIZET_IN_LONG[] = "passed '" s(MBSDINT_H_WANT_SIZET_IN_LONG) "'";
#else
static const char oMBSDINT_H_WANT_SIZET_IN_LONG[] = "not passed";
#endif
#ifdef MBSDINT_H_WANT_INT32
static const char oMBSDINT_H_WANT_INT32[] = "passed '" s(MBSDINT_H_WANT_INT32) "'";
#else
static const char oMBSDINT_H_WANT_INT32[] = "not passed";
#endif
#ifdef MBSDINT_H_WANT_LRG64
static const char oMBSDINT_H_WANT_LRG64[] = "passed '" s(MBSDINT_H_WANT_LRG64) "'";
#else
static const char oMBSDINT_H_WANT_LRG64[] = "not passed";
#endif
#ifdef MBSDINT_H_WANT_SAFEC
static const char oMBSDINT_H_WANT_SAFEC[] = "passed '" s(MBSDINT_H_WANT_SAFEC) "'";
#else
static const char oMBSDINT_H_WANT_SAFEC[] = "not passed";
#endif
#undef s
#undef S

#ifndef __STDC_WANT_LIB_EXT1__
#define __STDC_WANT_LIB_EXT1__ 1
#endif
$use_systypes
$use_inttypes
$use_stdint
$use_basetsd
#define MBSDINT_H_SKIP_CTAS 1
#include "mbsdcc.h"
#include "mbsdint.h"
$use_float
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define XXT_DO_STDIO_IMPLS
#include "xxt-int.h"
#include "mkt-int-t-ff.h"

static const char use_systypes[] = "$use_systypes";
static const char use_inttypes[] = "$use_inttypes";
static const char use_stdint[] = "$use_stdint";
static const char use_basetsd[] = "$use_basetsd";

static const char test_rcsid[] = "$rcsid";
extern const char xxtc_rcsid[];

EOF
cat >>mkt-int-t-in.$srcext <<\EOF
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

typedef long larr[3];
typedef larr *larrp;

static const int xMBSDINT_H_MBIPTR_IS_SIZET =
#if defined(UINTPTR_MAX) && !defined(__CHERI__)
	sizeof(size_t) == sizeof(uintptr_t) &&
#endif
	sizeof(mbiPTR_U) == sizeof(size_t) &&
	mbiTYPE_UBITS(mbiPTR_U) == mbiTYPE_UBITS(size_t);
static const int xMBSDINT_H_MBIPTR_IN_LARGE =
	sizeof(mbiPTR_U) <= sizeof(mbiLARGE_U) &&
	mbiTYPE_UBITS(mbiPTR_U) <= mbiMASK_BITS(mbiLARGE_U_MAX);
static const int xMBSDINT_H_WANT_LONG_IN_SIZET =
	sizeof(size_t) >= sizeof(long);
static const int xMBSDINT_H_WANT_PTR_IN_SIZET =
	sizeof(void *) == sizeof(size_t) &&
	sizeof(char *) == sizeof(size_t) &&
	sizeof(int *) == sizeof(size_t) &&
	sizeof(larrp) == sizeof(size_t) &&
	sizeof(void (*)(void)) == sizeof(size_t);
static const int xMBSDINT_H_WANT_SIZET_IN_LONG =
	sizeof(size_t) <= sizeof(long);
static const int xMBSDINT_H_WANT_INT32 =
	mbiTYPE_UBITS(unsigned int) >= 32;
static const int xMBSDINT_H_WANT_LRG64 =
	mbiTYPE_UBITS(mbiLARGE_U) >= 64;
static const int xMBSDINT_H_WANT_SAFEC =
	mbiSAFECOMPLEMENT == 1;

#define s(x) "'" mbccS(x) "'"
#ifdef MBSDINT_H_MBIPTR_IS_SIZET
static const char dMBSDINT_H_MBIPTR_IS_SIZET[] = s(MBSDINT_H_MBIPTR_IS_SIZET);
#else
static const char dMBSDINT_H_MBIPTR_IS_SIZET[] = "undef";
#endif
#ifdef MBSDINT_H_MBIPTR_IN_LARGE
static const char dMBSDINT_H_MBIPTR_IN_LARGE[] = s(MBSDINT_H_MBIPTR_IN_LARGE);
#else
static const char dMBSDINT_H_MBIPTR_IN_LARGE[] = "undef";
#endif
#ifdef MBSDINT_H_WANT_LONG_IN_SIZET
static const char dMBSDINT_H_WANT_LONG_IN_SIZET[] = s(MBSDINT_H_WANT_LONG_IN_SIZET);
#else
static const char dMBSDINT_H_WANT_LONG_IN_SIZET[] = "undef";
#endif
#ifdef MBSDINT_H_WANT_PTR_IN_SIZET
static const char dMBSDINT_H_WANT_PTR_IN_SIZET[] = s(MBSDINT_H_WANT_PTR_IN_SIZET);
#else
static const char dMBSDINT_H_WANT_PTR_IN_SIZET[] = "undef";
#endif
#ifdef MBSDINT_H_WANT_SIZET_IN_LONG
static const char dMBSDINT_H_WANT_SIZET_IN_LONG[] = s(MBSDINT_H_WANT_SIZET_IN_LONG);
#else
static const char dMBSDINT_H_WANT_SIZET_IN_LONG[] = "undef";
#endif
#ifdef MBSDINT_H_WANT_INT32
static const char dMBSDINT_H_WANT_INT32[] = s(MBSDINT_H_WANT_INT32);
#else
static const char dMBSDINT_H_WANT_INT32[] = "undef";
#endif
#ifdef MBSDINT_H_WANT_LRG64
static const char dMBSDINT_H_WANT_LRG64[] = s(MBSDINT_H_WANT_LRG64);
#else
static const char dMBSDINT_H_WANT_LRG64[] = "undef";
#endif
#ifdef MBSDINT_H_WANT_SAFEC
static const char dMBSDINT_H_WANT_SAFEC[] = s(MBSDINT_H_WANT_SAFEC);
#else
static const char dMBSDINT_H_WANT_SAFEC[] = "undef";
#endif
#undef s

struct ChkTest {
	char expr1[mbccChkExpr(3*3) + 1];
	mbmscWs(4820) /* padding warning */
	unsigned int expr2 : mbccCEX(3*3);
};

/* ensure flexible array members can be used */
struct want_fam {
	int blahfoo;
	char moo;
	mbccFAMslot(char, label);
};
union pre1_fam {
	struct want_fam s;
	char storage[mbccFAMSZ(struct want_fam, label, 1)];
};
union pre5_fam {
	struct want_fam s;
	char storage[mbccFAMSZ(struct want_fam, label, 5)];
};
struct fam_t {
	int count;
	mbccFAMslot(time_t, value);
};

mbCTA_BEG(fieldsizeof);
 mbCTA(o0, offsetof(struct want_fam, blahfoo) == 0);
 mbCTA(s0, mbccFSZ(struct want_fam, blahfoo) == sizeof(int));
 mbCTA(o1, offsetof(struct want_fam, moo) >= sizeof(int));
 mbCTA(s1, mbccFSZ(struct want_fam, moo) == sizeof(char));
 mbCTA(o2, offsetof(struct want_fam, label) >=
    (offsetof(struct want_fam, moo) + sizeof(char)));
 mbCTA(e1, mbccFSZ(struct ChkTest, expr1) == 1);
mbCTA_END(fieldsizeof);

static const char faml[] = "FAM label";

void dfam(const char *what, const char *exp, struct want_fam *fam);
void dfam(const char *what, const char *exp, struct want_fam *fam) {
	fprintf(stderr, "I: %s: the following text should read '%s':\n", what, exp);
	fflush(stderr);
	fprintf(stderr, "N: '%s'\n", fam->label);
}

volatile int zero = 0;
volatile mbiHUGE_U uzero = 0;

static void
ti_f(const char *t, size_t sz, const char *Min, const char *Max)
{
	fprintf(stderr, "N: %18s: floatish, %u chars, min(%s) max(%s)\n",
	    t, 0U+(unsigned)sz, Min, Max);
}

static void
tin_u(const char *t, size_t sz,
    unsigned Bits, const char *Max, unsigned Mb)
{
	fprintf(stderr, "N: %18s: unsigned, %u chars, %u bits, max(%s) w=%u\n",
	    t, 0U+(unsigned)sz, Bits, Max, Mb);
}

static void
tif_u(const char *t, size_t sz, int TbOK, int MaxOK,
    mbiHUGE_U Tb, const char *Max, mbiHUGE_U uMax)
{
	fprintf(stderr, "N: %18s: unsigned, %u chars, ", t, 0U+(unsigned)sz);
	if (TbOK == 1)
		fprintf(stderr, "%u", mbiMASK_BITS(Tb));
	else
		fprintf(stderr, "more than %u", mbiTYPE_UBITS(mbiHUGE_U));
	fprintf(stderr, " bits, max(%s) w", Max);
	if (MaxOK == 0)
		fprintf(stderr, "=0\n");
	else if (MaxOK == 1)
		fprintf(stderr, "=%u\n", mbiMASK_BITS(uMax));
	else
		fprintf(stderr, " > %u\n", mbiTYPE_UBITS(mbiHUGE_U));
}

static void
tin_s(const char *t, size_t sz, const char *Min, const char *Max, unsigned Bits)
{
	fprintf(stderr, "N: %18s:   signed, %u chars, min(%s), max(%s) w=%u\n",
	    t, 0U+(unsigned)sz, Min, Max, Bits);
}

static void
tif_s(const char *t, size_t sz, const char *Min, const char *Max,
    int MaxOK, mbiHUGE_U uMax)
{
	fprintf(stderr, "N: %18s:   signed, %u chars, min(%s), max(%s) w",
	    t, 0U+(unsigned)sz, Min, Max);
	if (MaxOK == 0)
		fprintf(stderr, "=0\n");
	else if (MaxOK == 1)
		fprintf(stderr, "=%u\n", mbiMASK_BITS(uMax) + 1U);
	else
		fprintf(stderr, " > %u\n", mbiTYPE_UBITS(mbiHUGE_U));
}

int main(void) {
	unsigned int b_rsz = 0, b_sz = 0, b_ptr = 0, b_mbi = 0, f_mbi;
	const char *whichrepr;
	const char *mbiPTR_casttgt;
	struct want_fam *fam;
	struct fam_t *fam2;
	struct ChkTest ct = { { 0 }, 1 };

	--ct.expr2;
	--ct.expr2;

	/* check FAMs don’t warn */
	fam = (struct want_fam *)malloc(mbccFAMSZ(struct want_fam, label, sizeof(faml)));
	if (!fam) {
		fprintf(stderr, "E: malloc failed\n");
		return (1);
	}
	memcpy(&fam->label, faml, sizeof(faml));
	dfam("faml", faml, fam);
	free(fam);
	fam2 = (struct fam_t *)malloc(mbccFAMSZ(struct fam_t, value, sizeof(time_t[5])));
	fam2->count = 5;
	free(fam2);
	(void)mbccFAMsz(struct fam_t, value, sizeof(time_t[5]));
#undef mbccABEND
#define mbccABEND(reasonstr) (fprintf(stderr, "E: mbccABEND: %s\n", (reasonstr)), abort())
	fam2 = (struct fam_t *)malloc(mbccFAMsz(struct fam_t, value, sizeof(time_t[5])));
	free(fam2);
/* CFrustFrust has no support for FAMs, so omit triggering -Warray-bounds */
#if !defined(__cplusplus) || defined(__cpp_flexible_array_members) || defined(_MSC_VER)
    {
	union pre1_fam p1fam;
	union pre5_fam p5fam;

	p1fam.s.label[0] = '\0';
	p5fam.s.label[0] = 'm';
	p5fam.s.label[1] = 'i';
	p5fam.s.label[2] = 'a';
	p5fam.s.label[3] = 'u';
	p5fam.s.label[4] = '\0';
	dfam("p1", "", (struct want_fam *)&p1fam);
	dfam("p5", "miau", (struct want_fam *)&p5fam);
    }
#endif

	fprintf(stderr, "I: initial tests...\n");
	mbmscWd(4127);
EOF

echo "/* NeXTstep bug workaround */" >mkt-int-t-ff.h
numf=0

t1() { cat >>mkt-int-t-in.$srcext <<EOF
	if (($1) != ($2)) {
		fprintf(stderr, "E: (%s) failed, got %lu want %lu (%s)\\n",
		    "$1", (unsigned long)($1), (unsigned long)($2), "$2");
		rv = 1;
	}
EOF
}

mbc1() {
	:>mkt-int-t-bc
	mbc1a "$@"
}

mbc1a() {
	want=$(( ($1) * 2))
	bc >mkt-int-t-bc2 <<EOF
define f(x) {
${4#$nl}
}
for (v = $2; v <= $3; ++v) {
	v
	f(v)
}
EOF
	got=$(wc -l <mkt-int-t-bc2)
	test $got -eq $want || \
	    die got $got lines, not "$want", from bc "'$4'"
	cat mkt-int-t-bc2 >>mkt-int-t-bc
}

mbc2() {
	:>mkt-int-t-bc
	mbc2a "$@"
}

mbc2a() {
	want=$(( ($1) * 3))
	bc >mkt-int-t-bc2 <<EOF
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
	got=$(wc -l <mkt-int-t-bc2)
	test $got -eq $want || \
	    die got $got lines, not "$want", from bc "'$6'"
	cat mkt-int-t-bc2 >>mkt-int-t-bc
}

mba() {
	printf '%s\n' "$@" >>mkt-int-t-bc
}

gett() {
	case $1 in
	iouts) echo int; return ;;
	bin?s|bouts) echo bst; return ;;
	hin?s|houts) echo hst; return ;;
	bin?u|boutu) echo but; return ;;
	hin?u|houtu) echo hut; return ;;
	*) echo "unknown type for argument <$1>" ;;
	esac
}

ubc1() {
	fn=f$numf
	numf=$(($numf + 1))
	ti=$(gett $2)
	to=$(gett $3)
	echo "	$fn();" >>mkt-int-t-in.$srcext
	echo "extern void $fn(void);" >>mkt-int-t-ff.h
    {
	echo >&4 "extern const $ti ${fn}_i[];"
	echo >&4 "const $ti ${fn}_i[] = {"
	echo "extern const $ti ${fn}_i[];"
	echo "static const $to ${fn}_o[] = {"
	os=$ht
	while read in; do
		read out
		echo >&4 "$os$in"
		echo "$os$out"
		os=,$ht
	done <mkt-int-t-bc
	echo >&4 "};"
	echo "};"
	echo "void $fn(void) {"
	echo "	size_t cnt = sizeof(${fn}_o) / sizeof(${fn}_o[0]);"
	echo "	fstr = \"$1\";"
	echo "	while (cnt--)"
	echo "		tm1($2, $3, $1, ${fn}_i[cnt], ${fn}_o[cnt]);"
	echo '}'
    } >>mkt-int-t-f0.$srcext 4>>mkt-int-t-f1.$srcext
}

ubc2() {
	fn=f$numf
	numf=$(($numf + 1))
	ta=$(gett $2)
	tb=$(gett $3)
	ty=$(gett $4)
	echo "	$fn();" >>mkt-int-t-in.$srcext
	echo "extern void $fn(void);" >>mkt-int-t-ff.h
    {
	echo >&4 "extern const $ta ${fn}_a[];"
	echo >&4 "const $ta ${fn}_a[] = {"
	echo "extern const $ta ${fn}_a[];"
	echo >&5 "extern const $tb ${fn}_b[];"
	echo >&5 "const $tb ${fn}_b[] = {"
	echo "extern const $tb ${fn}_b[];"
	echo "static const $ty ${fn}_y[] = {"
	os=$ht
	while read in; do
		read in2
		read out
		echo >&4 "$os$in"
		echo >&5 "$os$in2"
		echo "$os$out"
		os=,$ht
	done <mkt-int-t-bc
	echo >&4 "};"
	echo >&5 "};"
	echo "};"
	echo "void $fn(void) {"
	echo "	size_t cnt = sizeof(${fn}_y) / sizeof(${fn}_y[0]);"
	echo "	fstr = \"$1\";"
	echo "	while (cnt--)"
	echo "		tm2($2, $3, $4, $1, ${fn}_a[cnt], ${fn}_b[cnt], ${fn}_y[cnt]);"
	echo '}'
    } >>mkt-int-t-f0.$srcext 4>>mkt-int-t-f1.$srcext 5>>mkt-int-t-f2.$srcext
}

t1 'mbiCOS(bst, -1, <, 2)' 1
t1 'mbiMOT(hut, hfm, 1, 0x1234, 0x5678)' 0x0234
t1 'mbiUP(but, bfm)' '0xFFU'
t1 'mbiUP(but, bhm)' '0x7FU'
t1 'mbiUP(hut, hfm)' '0x3FFU'
t1 'mbiUP(hut, hhm)' '0x1FFU'
t1 'mbiMM(hut, hfm, (hut)0xFFFFUL)' hfm
t1 'mbiMM(hut, hhm, (hut)0xFFFFUL)' hhm

cat >>mkt-int-t-in.$srcext <<\EOF
	mbmscWpop;
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

mbc2 512 0 1 0 255 'if (x != 0) y = -y
while (y < 0) y += 256
return (y)'
ubc2 b_mbiA_VZU2U bin1u bin2u boutu

mbc2 8192 0 1 0 4095 'if (x != 0) y = -y
while (y < 0) y += 1024
return (y % 1024)'
ubc2 h_mbiMA_VZU2U hin1u hin2u houtu

cat >>mkt-int-t-in.$srcext <<\EOF

#if ((SCHAR_MIN)+1 == -(SCHAR_MAX))
	fprintf(stderr, "I: assuming two's complement, testing...\n");
	fstr = "2b_mbiA_S2VZ";
	tm1(bin1s, iouts, b_mbiA_S2VZ, -128, 1);
	fstr = "2b_mbiA_U2S";
	tm1(bin1u, bouts, b_mbiA_U2S, 128, -128);
	fstr = "2b_mbiA_S2U";
	tm1(bin1s, boutu, b_mbiA_S2U, -128, 128);
	fstr = "2b_mbiA_S2M";
	tm1(bin1s, boutu, b_mbiA_S2M, -128, 128);
	fstr = "2b_mbiA_VZM2S";
	tm2(bin1u, bin2u, bouts, b_mbiA_VZM2S, 1, 128, -128);
#else
	fprintf(stderr, "I: one's complement or sign-and-magnitude system!\n");
#define mbiCfail hin1s = 0
	hin1s = 1;
	mbiCAsafeU2S(bs, but, 128);
	if (hin1s) {
		fprintf(stderr, "E: %s did not trigger\n", "mbiCAsafeU2S(128)");
		rv = 1;
	}
	hin1s = 1;
	mbiCAsafeVZM2S(bs, but, 1, 128);
	if (hin1s) {
		fprintf(stderr, "E: %s did not trigger\n", "mbiCAsafeVZM2S(1, 128)");
		rv = 1;
	}
#undef mbiCfail
#endif

	fprintf(stderr, "I: overflow/underflow-checking unsigned...\n");
	mbmscWd(4242 4244);

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
#if 1 /* mbiCASlet validate overflow */
			/*
			 * note: these may also raise an implementation-defined
			 * signal (C23§6.3.1.3(3)), in which case we lose here;
			 * for these systems that do that, comment out the test
			 */
			hin1u = 0;
			mbiCASlet(bst, bin1s, int, iouts);
			if (hin1u != houtu) {
				fprintf(stderr, "E: mbiCASlet(%d) unexpectedly %sed: %d",
				    iouts, hin1u ? "fail" : "pass", bin1s);
				rv = 1;
			}
#endif /* mbiCASlet validate overflow */
		}

	fprintf(stderr, "I: manual two’s komplement calculations...\n");
EOF

mbc2 65536 0 255 0 255 '
	if (x == y) return (0)
	if (x > 127) x = -(256 - x)
	if (y > 127) y = -(256 - y)
	if (x < y) return (-1)
	return (1)'
ubc2 b_mbiKcmp bin1u bin2u iouts

mbc2 4096 0 63 0 63 '
	if (x == y) return (0)
	if (x > 31) x = -(64 - x)
	if (y > 31) y = -(64 - y)
	if (x < y) return (-1)
	return (1)'
ubc2 x_mbiMKcmp bin1u bin2u iouts

cat >>mkt-int-t-in.$srcext <<\EOF
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
	for (hin1u = 0; hin1u < 64; ++hin1u)
		for (hin2u = 0; hin2u <= 8; ++hin2u) {
			boutu = x_mbiMKrol(hin1u, hin2u);
			iouts = th_rol(6, hin1u, hin2u);
			c2("x_mbiMKrol");
			boutu = x_mbiMKror(hin1u, hin2u);
			iouts = th_ror(6, hin1u, hin2u);
			c2("x_mbiMKror");
			boutu = x_mbiMKshl(hin1u, hin2u);
			iouts = th_shl(6, hin1u, hin2u);
			c2("x_mbiMKshl");
			boutu = x_mbiMKshr(hin1u, hin2u);
			iouts = th_shr(6, hin1u, hin2u);
			c2("x_mbiMKshr");
			boutu = x_mbiMKsar(hin1u, hin2u);
			iouts = th_sar(6, hin1u, hin2u);
			c2("x_mbiMKsar");
		}

	mbmscWpop;
EOF

mbc2 65280 0 255 1 255 '
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

mbc2 4032 0 63 1 63 '
	s = 1
	if (x > 31) {
		x = 64 - x
		s = -1
	}
	if (y > 31) {
		y = 64 - y
		s *= -1
	}
	s *= (x / y)
	while (s < 0) s += 64
	return (s)'
ubc2 x_mbiMKdiv bin1u bin2u boutu

mbc2 65280 0 255 1 255 '
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

mbc2 4032 0 63 1 63 '
	r = 1
	if (x > 31) {
		x = 64 - x
		r = -1
	}
	if (y > 31) {
		y = 64 - y
	}
	s = (x / y)
	r *= x - (s * y)
	while (r < 0) r += 64
	return (r)'
ubc2 x_mbiMKrem bin1u bin2u boutu

cat >>mkt-int-t-in.$srcext <<\EOF
	/* shall not warn */
	SHIKATANAI feof(stdin);

	fprintf(stderr, "I: final tests...\n");
	mbmscWd(4127 5219);
#ifndef __cplusplus
/* web+ap://toot.mirbsd.org/@mirabilos/statuses/01HC3SH1WGHVR48BT1G975MFT5 */
EOF

t1 'mbnil == NULL' 1

cat >>mkt-int-t-in.$srcext <<\EOF
#else /* __cplusplus */
EOF

t1 '((void *)NULL) == mbnil' 1
t1 'NULL == (void *)mbnil' 1

cat >>mkt-int-t-in.$srcext <<\EOF
#endif /* __cplusplus */
EOF

# the latter is possibly no intconstexpr in MSVC and on SCO and Xenix
t1 'offsetof(struct want_fam, label)' 'offsetof(struct want_fam, label[0])'
t1 'offsetof(struct fam_t, value)' 'offsetof(struct fam_t, value[0])'

t1 'ct.expr2' 511

cat >>mkt-int-t-in.$srcext <<\EOF
	switch ((unsigned int)bitrepr(-1)) {
	case 0xFFU:
		whichrepr = "two’s complement";
		break;
	case 0xFEU:
		whichrepr = "one’s complement";
		break;
	case 0x81U:
		whichrepr = "sign-and-magnitude";
		break;
	default:
		whichrepr = "an illegal (per ISO C) representation";
		break;
	}

	fprintf(stderr, "I: architecture infos (0 may mean unknown):\n");
	fprintf(stderr, "N: CHAR_BIT: %d\t\tcomplement: %s using %s\n",
	    (int)CHAR_BIT, mbiSAFECOMPLEMENT ? "safe" : "UNSAFE", whichrepr);

/* use for types guaranteed to not be float only */
#define ti(t,min,max) if (mbiTYPE_ISF(t)) \
		ti_f(#t, sizeof(t), mbccS(min), mbccS(max)); \
	else if (mbiTYPE_ISU(t)) \
		tin_u(#t, sizeof(t), \
		    mbiMASK_BITS((t)((t)zero + mbiTYPE_UMAX(t))), \
		    mbccS(max), (max) == 0 ? 0 : mbiMASK_BITS(max)); \
	else \
		tin_s(#t, sizeof(t), mbccS(min), mbccS(max), \
		    (max) < 1 ? 0 : (mbiMASK_BITS(max) + 1U))

/* use if the type could be float */
#define tif(t,min,max) if (mbiTYPE_ISF(t)) \
		ti_f(#t, sizeof(t), mbccS(min), mbccS(max)); \
	else if (mbiTYPE_ISU(t)) \
		tif_u(#t, sizeof(t), \
		    tifc((t)-(t)1), tifc(max), \
		    tifC((t)-(t)1), mbccS(max), tifC(max)); \
	else \
		tif_s(#t, sizeof(t), mbccS(min), mbccS(max), \
		    tifc(max), tifC(max))
/* workarounds multiple idiotic compilers… */
#define tifc(v) ((v) < 1 ? 0 : uzero+(v) < mbiHUGE_U_MAX ? 1 : uzero+(v) == mbiHUGE_U_MAX ? 1 : 2)
#define tifC(v) ((v) < 1 ? 0U : uzero+(v) < mbiHUGE_U_MAX ? (mbiHUGE_U)(uzero+(v)) : uzero+(v) == mbiHUGE_U_MAX ? mbiHUGE_U_MAX : 0U)

	ti(char, CHAR_MIN, CHAR_MAX);
	ti(signed char, SCHAR_MIN, SCHAR_MAX);
	ti(unsigned char, 0, UCHAR_MAX);
	ti(short, SHRT_MIN, SHRT_MAX);
	ti(unsigned short, 0, USHRT_MAX);
	ti(int, INT_MIN, INT_MAX);
	ti(unsigned int, 0, UINT_MAX);
	ti(long, LONG_MIN, LONG_MAX);
	ti(unsigned long, 0, ULONG_MAX);
#ifdef UQUAD_MAX
	ti(quad_t, QUAD_MIN, QUAD_MAX);
	ti(u_quad_t, 0, UQUAD_MAX);
#endif
#ifdef LLONG_MIN
	ti(long long, LLONG_MIN, LLONG_MAX);
	ti(unsigned long long, 0, ULLONG_MAX);
#else
	fprintf(stderr, "N: no %s\n", "long long");
#endif
#ifdef INTMAX_MIN
	ti(intmax_t, INTMAX_MIN, INTMAX_MAX);
	ti(uintmax_t, 0, UINTMAX_MAX);
#else
	fprintf(stderr, "N: no %s\n", "intmax_t");
#endif
	ti(mbiLARGE_S, mbiLARGE_S_MIN, mbiLARGE_S_MAX);
	ti(mbiLARGE_U, 0, mbiLARGE_U_MAX);
	ti(mbiHUGE_S, mbiHUGE_S_MIN, mbiHUGE_S_MAX);
	ti(mbiHUGE_U, 0, mbiHUGE_U_MAX);
#ifdef SSIZE_MAX
	ti(ssize_t, 0, SSIZE_MAX);
#else
	fprintf(stderr, "N: no %s\n", "ssize_t");
#endif
#ifdef SIZE_MAX
	ti(size_t, 0, SIZE_MAX);
#else
	ti(size_t, 0, 0);
#endif
#ifdef PTRDIFF_MAX
	ti(ptrdiff_t, 0, PTRDIFF_MAX);
#else
	ti(ptrdiff_t, 0, 0);
#endif
#ifdef UINTPTR_MAX
	ti(uintptr_t, 0, UINTPTR_MAX);
#else
	fprintf(stderr, "N: no %s\n", "uintptr_t");
#endif
	ti(mbiPTR_U, 0, mbiPTR_U_MAX);
	tif(time_t, 0, 0);
#if HAVE_OFF_T
	ti(off_t, 0, 0);
#else
	fprintf(stderr, "N: no %s\n", "off_t");
#endif
#ifdef FLT_RADIX
	tif(float, FLT_MIN, FLT_MAX);
	tif(double, DBL_MIN, DBL_MAX);
	tif(long double, LDBL_MIN, LDBL_MAX);
#endif
#if MBSDINT_H_MBIPTR_IS_SIZET || \
    (!defined(__CHERI__) && !defined(UINTPTR_MAX))
	mbiPTR_casttgt = mbccS2(mbiSIZE_U);
#elif MBSDINT_H_MBIPTR_IN_LARGE
	mbiPTR_casttgt = "mbiLARGE_U";
#else
	mbiPTR_casttgt = "mbiHUGE_U";
#endif
	fprintf(stderr, "N: format specifiers: mbiLARGE_S %%%s / mbiHUGE_S %%%s\n"
	    "N: mbiPTR_U %%%s (with cast to %s) / size_t %%%s (cast to %s)\n",
	    mbiLARGE_P(d), mbiHUGE_P(d), mbiPTR_P(X), mbiPTR_casttgt,
	    mbiSIZE_P(u), mbccS2(mbiSIZE_U));
#ifdef RSIZE_MAX
	b_rsz = mbiMASK_BITS(RSIZE_MAX);
#endif
#ifdef SIZE_MAX
	b_sz = mbiMASK_BITS(SIZE_MAX);
#endif
#ifdef PTRDIFF_MAX
	b_ptr = mbiMASK_BITS(PTRDIFF_MAX);
#endif
	if (mbiMASK_CHK(mbiSIZE_MAX))
		b_mbi = mbiMASK_BITS(mbiSIZE_MAX);
	f_mbi = mbiTYPE_UBITS(size_t) / ((unsigned)(CHAR_BIT) / 2);
	mbmscWpop;
	fprintf(stderr, "N: bits of:"
	    " SIZE_MAX=%u RSIZE_MAX=%u PTRDIFF_MAX=%u"
	    " mbiSIZE_MAX=%u(0x%0*" mbiSIZE_P(X) ")\n",
	    b_sz, b_rsz, b_ptr, b_mbi, (int)f_mbi, (mbiSIZE_U)mbiSIZE_MAX);
	fprintf(stderr, "N: sizes of pointers:"
	    " void=%u char=%u int=%u long[]=%u func=%u\n",
	    (unsigned)sizeof(void *), (unsigned)sizeof(char *),
	    (unsigned)sizeof(int *), (unsigned)sizeof(larrp),
	    (unsigned)sizeof(void (*)(void)));
#if !defined(HAVE_INTCONSTEXPR_RSIZE_MAX) && defined(RSIZE_MAX)
	fprintf(stderr, "W: RSIZE_MAX found but not an integer constant expression\n");
	fprintf(stderr, "N: please review the sizes/limits above for suitability!\n");
#endif
	fprintf(stderr, "\nI: you must include at least the following headers before mbsdint.h:\n");
	if (*use_systypes) fprintf(stderr, "%s\n", use_systypes);
	if (*use_inttypes) fprintf(stderr, "%s\n", use_inttypes);
	if (*use_stdint) fprintf(stderr, "%s\n", use_stdint);
	if (*use_basetsd) fprintf(stderr, "%s\n", use_basetsd);
#if !HAVE_OFF_T
	fprintf(stderr, "%s\n", "#define HAVE_OFF_T 0");
#endif
#ifdef HAVE_INTCONSTEXPR_RSIZE_MAX
	fprintf(stderr, "%s\n", "#define HAVE_INTCONSTEXPR_RSIZE_MAX 1");
#else
	fprintf(stderr, "%s\n", "#undef HAVE_INTCONSTEXPR_RSIZE_MAX");
#endif
#ifdef MBSDINT_H_SMALL_SYSTEM
	fprintf(stderr, "/* you passed -DMBSDINT_H_SMALL_SYSTEM=%u which may or may not be necessary */\n",
	    (unsigned)MBSDINT_H_SMALL_SYSTEM);
#endif
	fprintf(stderr, "%s\n", "#include \"mbsdcc.h\" /* or whereever it lies */");
	fprintf(stderr, "\nI: state of the extra assertions:\n");
#define a(n,D) fprintf(stderr, "%-31s\tcan be %d; used %s\tdefault %d; %s\n", \
		   #n, x##n, d##n, D, o##n)
	a(MBSDINT_H_MBIPTR_IS_SIZET, 1);
	a(MBSDINT_H_MBIPTR_IN_LARGE, 1);
	a(MBSDINT_H_WANT_LONG_IN_SIZET, 1);
	a(MBSDINT_H_WANT_PTR_IN_SIZET, 0);
	a(MBSDINT_H_WANT_SIZET_IN_LONG, 0);
	a(MBSDINT_H_WANT_INT32, 0);
	a(MBSDINT_H_WANT_LRG64, 0);
	a(MBSDINT_H_WANT_SAFEC, 0);
#undef a

	fprintf(stderr, "\nI: tests finished with errorlevel %d\n"
	    "N: by %s\nN: and %s\nN: with %s\nN: for %s\nN: and %s\n",
	    rv, test_rcsid, xxtc_rcsid, XXTH_RCSID, SYSKERN_MBSDCC_H,
	    SYSKERN_MBSDINT_H);
	return (rv);
}
EOF
echo >&2 'I: building tests...'
set -x
rm -f mkt-int-t-*.$objext
"$@" -c mkt-int-t-xx.$srcext || die -w compiling tests-xx failed
"$@" -c mkt-int-t-in.$srcext || die -w compiling tests-mk failed
"$@" -c mkt-int-t-f0.$srcext || die -w compiling tests-f0 failed
"$@" -c mkt-int-t-f1.$srcext || die -w compiling tests-f1 failed
"$@" -c mkt-int-t-f2.$srcext || die -w compiling tests-f2 failed
"$@" $LDFLAGS ${Fe}mkt-int-t-t.exe mkt-int-t-*.$objext || die -w linking tests failed
(ls -l mkt-int-t-t.exe || :)
(size mkt-int-t-t.exe || :)
set +ex
if $cross; then
	echo >&2 'I: compilation finished, copy mkt-int-t-t.exe to the target and run it'
	echo >&2 "N: '$(pwd | sed "s,','\\\\'',g")/mkt-int-t-t.exe'"
	echo >&2 'I: then press Return to continue'
	read dummy
	exit 0
fi
echo >&2 'I: running tests'
./mkt-int-t-t.exe
rv=$?
if test "$rv" = 0; then
	echo >&2 'I: tests passed'
	exit 0
fi
echo >&2 'E: tests failed; press Return to continue'
read dummy
exit 1
