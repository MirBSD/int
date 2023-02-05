/* $MirOS: int/xxt-int.h,v 1.1 2023/02/05 16:55:01 tg Exp $ */

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
