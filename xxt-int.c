/* $MirOS: int/xxt-int.c,v 1.1 2023/02/05 16:55:01 tg Exp $ */

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
