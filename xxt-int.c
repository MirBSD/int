/* $MirOS: src/kern/include/xxt-int.c,v 1.2 2023/02/05 18:01:05 tg Exp $ */

/* © 2023 mirabilos Ⓕ MirBSD */

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
