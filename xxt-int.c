/* $MirOS: src/kern/include/xxt-int.c,v 1.3 2023/02/06 01:33:55 tg Exp $ */

/* © 2023 mirabilos Ⓕ MirBSD */

/* test helpers */

int th_rol(int bits, unsigned int v1, unsigned int v2) {
	unsigned int mask = bits == 4 ? 0x0FU : 0xFFU;

	v1 &= mask;
	v2 &= (bits - 1);
	if (!v2)
		return (v1);
	v1 = (v1 << v2) | (v1 >> (bits - v2));
	return (v1 & mask);
}

int th_ror(int bits, unsigned int v1, unsigned int v2) {
	unsigned int mask = bits == 4 ? 0x0FU : 0xFFU;

	v1 &= mask;
	v2 &= (bits - 1);
	if (!v2)
		return (v1);
	v1 = (v1 >> v2) | (v1 << (bits - v2));
	return (v1 & mask);
}

int th_shl(int bits, unsigned int v1, unsigned int v2) {
	unsigned int mask = bits == 4 ? 0x0FU : 0xFFU;

	v1 &= mask;
	v2 &= (bits - 1);
	if (!v2)
		return (v1);
	v1 = (v1 << v2);
	return (v1 & mask);
}

int th_shr(int bits, unsigned int v1, unsigned int v2) {
	unsigned int mask = bits == 4 ? 0x0FU : 0xFFU;

	v1 &= mask;
	v2 &= (bits - 1);
	if (!v2)
		return (v1);
	v1 = (v1 >> v2);
	return (v1 & mask);
}

int th_sar(int bits, unsigned int v1, unsigned int v2) {
	unsigned int mask = bits == 4 ? 0x0FU : 0xFFU;
	unsigned int sgnb = bits == 4 ? 0x08U : 0x80U;

	v1 &= mask;
	v2 &= (bits - 1);
	if (!v2)
		return (v1);
	v1 = (((v1 & sgnb) ? mask : 0U) << (bits - v2)) | (v1 >> v2);
	return (v1 & mask);
}

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
	return (mbiA_U2S(but, bst, bsm, in));
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
	return (mbiA_VZM2S(but, bst, in1, in2));
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
	return (mbiKdiv(but, bsm, in1, in2));
}

xut x_mbiMKdiv(xut in1, xut in2) {
	return (mbiMKdiv(xut, xfm, xhm, in1, in2));
}

but b_mbiKrem(but in1, but in2) {
	return (mbiKrem(but, bsm, in1, in2));
}

xut x_mbiMKrem(xut in1, xut in2) {
	return (mbiMKrem(xut, xfm, xhm, in1, in2));
}
