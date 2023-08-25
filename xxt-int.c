const char xxtc_rcsid[] = "$MirOS: src/kern/include/xxt-int.c,v 1.8 2023/08/25 18:12:55 tg Exp $";

/* © 2023 mirabilos Ⓕ MirBSD */

/* test helpers */

int th_rol(unsigned int bits, unsigned int v1, unsigned int v2) {
	unsigned int mask = bits == 6 ? 0x3FU : 0xFFU;

	v1 &= mask;
	while (v2 >= bits)
		v2 -= bits;
	if (!v2)
		return (v1);
	v1 = (v1 << v2) | (v1 >> (bits - v2));
	return (v1 & mask);
}

int th_ror(unsigned int bits, unsigned int v1, unsigned int v2) {
	unsigned int mask = bits == 6 ? 0x3FU : 0xFFU;

	v1 &= mask;
	while (v2 >= bits)
		v2 -= bits;
	if (!v2)
		return (v1);
	v1 = (v1 >> v2) | (v1 << (bits - v2));
	return (v1 & mask);
}

int th_shl(unsigned int bits, unsigned int v1, unsigned int v2) {
	unsigned int mask = bits == 6 ? 0x3FU : 0xFFU;

	v1 &= mask;
	while (v2 >= bits)
		v2 -= bits;
	if (!v2)
		return (v1);
	v1 = (v1 << v2);
	return (v1 & mask);
}

int th_shr(unsigned int bits, unsigned int v1, unsigned int v2) {
	unsigned int mask = bits == 6 ? 0x3FU : 0xFFU;

	v1 &= mask;
	while (v2 >= bits)
		v2 -= bits;
	if (!v2)
		return (v1);
	v1 = (v1 >> v2);
	return (v1 & mask);
}

int th_sar(unsigned int bits, unsigned int v1, unsigned int v2) {
	unsigned int mask = bits == 6 ? 0x3FU : 0xFFU;
	unsigned int sgnb = bits == 6 ? 0x20U : 0x80U;

	v1 &= mask;
	while (v2 >= bits)
		v2 -= bits;
	if (!v2)
		return (v1);
	v1 = (((v1 & sgnb) ? mask : 0U) << (bits - v2)) | (v1 >> v2);
	return (v1 & mask);
}

unsigned char bitrepr(signed char val) {
	unsigned char res;

	memcpy(&res, &val, sizeof(res));
	return (res);
}

#define e_CAsafe(name,vz,v) do {				\
	if (vz == 2)						\
		fprintf(stderr, "E: %s(%u)", name, v);		\
	else							\
		fprintf(stderr, "E: %s(%u, %u)", name, vz, v);	\
	rv = 1;							\
} while (/* CONSTCOND */ 0)

/* test wrappers */

int b_mbiA_S2VZ(bst in) {
	return (mbiA_S2VZ(in));
}

int b_mbiA_U2VZ(but in) {
	return (mbiA_U2VZ(but, bsm, in));
}

int h_mbiMA_U2VZ(hut in) {
	return (mbiMA_U2VZ(hut, hfm, hsm, in));
}

bst b_mbiA_U2S(but in) {
#define mbiCfail e_CAsafe("b_mbiA_U2S", 2, in)
	mbiCAsafeU2S(bs, but, in);
	return (mbiA_U2S(but, bst, bsm, in));
#undef mbiCfail
}

hst h_mbiMA_U2S(hut in) {
	return (mbiMA_U2S(hut, hst, hfm, hhm, in));
}

but b_mbiA_S2U(bst in) {
	return (mbiA_S2U(but, bst, in));
}

hut b_mbiMA_S2U(hst in) {
	return (mbiMA_S2U(hut, hst, hfm, in));
}

but b_mbiA_S2M(bst in) {
	return (mbiA_S2M(but, bst, in));
}

hut h_mbiMA_S2M(hst in) {
	return (mbiMA_S2M(hut, hst, hhm, in));
}

but b_mbiA_U2M(but in) {
	return (mbiA_U2M(but, bsm, in));
}

hut h_mbiMA_U2M(hut in) {
	return (mbiMA_U2M(hut, hfm, hhm, in));
}

bst b_mbiA_VZM2S(but in1, but in2) {
#define mbiCfail e_CAsafe("b_mbiA_VZM2S", in1, in2)
	mbiCAsafeVZM2S(bs, but, in1, in2);
	return (mbiA_VZM2S(but, bst, in1, in2));
#undef mbiCfail
}

hst h_mbiMA_VZM2S(hut in1, hut in2) {
	return (mbiMA_VZM2S(hut, hst, hfm, hhm, in1, in2));
}

but b_mbiA_VZM2U(but in1, but in2) {
	return (mbiA_VZM2U(but, bsm, in1, in2));
}

hut h_mbiMA_VZM2U(hut in1, hut in2) {
	return (mbiMA_VZM2U(hut, hfm, hhm, in1, in2));
}

but b_mbiA_VZU2U(but in1, but in2) {
	return (mbiA_VZU2U(but, in1, in2));
}

hut h_mbiMA_VZU2U(hut in1, hut in2) {
	return (mbiMA_VZU2U(hut, hfm, in1, in2));
}

int b_mbiKcmp(but in1, but in2) {
	int lt, eq, gt;

	lt = mbiKcmp(but, bhm, in1, <, in2);
	eq = mbiKcmp(but, bhm, in1, ==, in2);
	gt = mbiKcmp(but, bhm, in1, >, in2);
	if ((lt + eq + gt) != 1)
		return (666);
	return (gt - lt);
}

int x_mbiMKcmp(xut in1, xut in2) {
	int lt, eq, gt;

	lt = mbiMKcmp(xut, xfm, xhm, in1, <, in2);
	eq = mbiMKcmp(xut, xfm, xhm, in1, ==, in2);
	gt = mbiMKcmp(xut, xfm, xhm, in1, >, in2);
	if ((lt + eq + gt) != 1)
		return (666);
	return (gt - lt);
}

but b_mbiKrol(but in1, but in2) {
	return (mbiKrol(but, in1, in2));
}

but b_mbiKror(but in1, but in2) {
	return (mbiKror(but, in1, in2));
}

but b_mbiKshl(but in1, but in2) {
	return (mbiKshl(but, in1, in2));
}

but b_mbiKsar(but in1, but in2) {
	return (mbiKsar(but, mbiA_U2VZ(but, bsm, in1), in1, in2));
}

but b_mbiKshr(but in1, but in2) {
	return (mbiKshr(but, in1, in2));
}

xut x_mbiMKrol(xut in1, xut in2) {
	return (mbiMKrol(xut, xfm, in1, in2));
}

xut x_mbiMKror(xut in1, xut in2) {
	return (mbiMKror(xut, xfm, in1, in2));
}

xut x_mbiMKshl(xut in1, xut in2) {
	return (mbiMKshl(xut, xfm, in1, in2));
}

xut x_mbiMKsar(xut in1, xut in2) {
	return (mbiMKsar(xut, xfm, mbiMA_U2VZ(xut, xfm, xsm, in1), in1, in2));
}

xut x_mbiMKshr(xut in1, xut in2) {
	return (mbiMKshr(xut, xfm, in1, in2));
}

but b_mbiKdiv(but in1, but in2) {
	but res, rd, rr;

	res = mbiKdiv(but, bsm, in1, in2);
	mbiKdivrem(rd, rr, but, bsm, in1, in2);
	if (res != rd) {
		xxt_divrem_err("b_mbiKdiv",
		    (unsigned)in1, (unsigned)in2, (unsigned)res,
		    (unsigned)rd, (unsigned)rr);
		rv = 1;
	}
	return (res);
}

xut x_mbiMKdiv(xut in1, xut in2) {
	xut res, rd, rr;

	res = mbiMKdiv(xut, xfm, xhm, in1, in2);
	mbiMKdivrem(rd, rr, xut, xfm, xhm, in1, in2);
	if (res != rd) {
		xxt_divrem_err("x_mbiMKdiv",
		    (unsigned)in1, (unsigned)in2, (unsigned)res,
		    (unsigned)rd, (unsigned)rr);
		rv = 1;
	}
	return (res);
}

but b_mbiKrem(but in1, but in2) {
	but res, rd, rr;

	res = mbiKrem(but, bsm, in1, in2);
	mbiKdivrem(rd, rr, but, bsm, in1, in2);
	if (res != rr) {
		xxt_divrem_err("b_mbiKrem",
		    (unsigned)in1, (unsigned)in2, (unsigned)res,
		    (unsigned)rd, (unsigned)rr);
		rv = 1;
	}
	return (res);
}

xut x_mbiMKrem(xut in1, xut in2) {
	xut res, rd, rr;

	res = mbiMKrem(xut, xfm, xhm, in1, in2);
	mbiMKdivrem(rd, rr, xut, xfm, xhm, in1, in2);
	if (res != rr) {
		xxt_divrem_err("x_mbiMKrem",
		    (unsigned)in1, (unsigned)in2, (unsigned)res,
		    (unsigned)rd, (unsigned)rr);
		rv = 1;
	}
	return (res);
}
