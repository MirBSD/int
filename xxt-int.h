/* $MirOS: src/kern/include/xxt-int.h,v 1.3 2023/02/06 01:33:55 tg Exp $ */

/* © 2023 mirabilos Ⓕ MirBSD */

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
#define xfm 0x0F
#define xhm 0x07
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

int th_rol(int, unsigned int, unsigned int);
int th_ror(int, unsigned int, unsigned int);
int th_shl(int, unsigned int, unsigned int);
int th_shr(int, unsigned int, unsigned int);
int th_sar(int, unsigned int, unsigned int);

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
