#define XXTH_RCSID "$MirOS: src/kern/include/xxt-int.h,v 1.8 2023/08/25 18:12:55 tg Exp $"

/* © 2023 mirabilos Ⓕ MirBSD */

#define bs_MAX SCHAR_MAX
#define bfm 0xFF
#define bhm 0x7F
#define bsm bhm
typedef unsigned char but;
typedef signed char bst;
#define hfm 0x3FF
#define hhm 0x1FF
#define hsm hhm
typedef unsigned short hut;
typedef signed short hst;
#define xfm 0x3F
#define xhm 0x1F
#define xsm xhm
typedef unsigned char xut;
typedef signed char xst;

extern int rv;
extern but bin1u, bin2u, boutu;
extern bst bin1s, bin2s, bouts;
extern hut hin1u, hin2u, houtu;
extern hst hin1s, hin2s, houts;
extern int iouts;
extern const char *fstr;

#define tm1(nin, nout, f, vin, vout) do {				\
	nin = (vin);							\
	nout = f(nin);							\
	if (nout != (vout)) {						\
		fprintf(stderr,						\
		    "E: %s(%lu) failed, got %lu want %lu\n",		\
		    fstr, (unsigned long)(vin),				\
		    (unsigned long)nout, (unsigned long)(vout));	\
		rv = 1;							\
	}								\
} while (/* CONSTCOND */ 0)

#define tm2(nin1, nin2, nout, f, vin1, vin2, vout) do {			\
	nin1 = (vin1);							\
	nin2 = (vin2);							\
	nout = f(nin1, nin2);						\
	if (nout != (vout)) {						\
		fprintf(stderr,						\
		    "E: %s(%lu, %lu) failed, got %lu want %lu\n",	\
		    fstr, (unsigned long)(vin1), (unsigned long)(vin2),	\
		    (unsigned long)nout, (unsigned long)(vout));	\
		rv = 1;							\
	}								\
} while (/* CONSTCOND */ 0)

extern void xxt_divrem_err(const char *fn, unsigned int in1, unsigned int in2,
    unsigned int res, unsigned int divres, unsigned int remres);

#ifdef XXT_DO_STDIO_IMPLS
void
xxt_divrem_err(const char *fn, unsigned int in1, unsigned int in2,
    unsigned int res, unsigned int divres, unsigned int remres)
{
	fprintf(stderr, "E: %s(%u, %u) = %u, div=%u mod=%u\n",
	    fn, in1, in2, res, divres, remres);
}
#endif

int th_rol(unsigned int, unsigned int, unsigned int);
int th_ror(unsigned int, unsigned int, unsigned int);
int th_shl(unsigned int, unsigned int, unsigned int);
int th_shr(unsigned int, unsigned int, unsigned int);
int th_sar(unsigned int, unsigned int, unsigned int);

unsigned char bitrepr(signed char);

int b_mbiA_S2VZ(bst);
int b_mbiA_U2VZ(but);
int h_mbiMA_U2VZ(hut);
bst b_mbiA_U2S(but);
hst h_mbiMA_U2S(hut);
but b_mbiA_S2U(bst);
hut b_mbiMA_S2U(hst);
but b_mbiA_S2M(bst);
hut h_mbiMA_S2M(hst);
but b_mbiA_U2M(but);
hut h_mbiMA_U2M(hut);
bst b_mbiA_VZM2S(but, but);
hst h_mbiMA_VZM2S(hut, hut);
but b_mbiA_VZM2U(but, but);
hut h_mbiMA_VZM2U(hut, hut);
but b_mbiA_VZU2U(but, but);
hut h_mbiMA_VZU2U(hut, hut);
int b_mbiKcmp(but, but);
int x_mbiMKcmp(xut, xut);
but b_mbiKrol(but, but);
but b_mbiKror(but, but);
but b_mbiKshl(but, but);
but b_mbiKsar(but, but);
but b_mbiKshr(but, but);
xut x_mbiMKrol(xut, xut);
xut x_mbiMKror(xut, xut);
xut x_mbiMKshl(xut, xut);
xut x_mbiMKsar(xut, xut);
xut x_mbiMKshr(xut, xut);
but b_mbiKdiv(but, but);
xut x_mbiMKdiv(xut, xut);
but b_mbiKrem(but, but);
xut x_mbiMKrem(xut, xut);
