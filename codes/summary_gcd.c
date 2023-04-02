#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

/**
 * This script reproduce the three different logic of gcd_11 for testing convenience.
 */

// This ctz is slower than their real implementation.
int ctz(int64_t a) {
    int64_t k;
    for (k = 0; (a & 1) == 0; ++k) {
        a >>= 1;
    }
    return k;
}

/**
 * GMP's arm64 implementation
 */
int64_t arm_gcd(int64_t u, int64_t v) {
    int k; // t0, # of common trailing zero
    int64_t x3; // t1, the difference
    x3 = u - v;
    while (x3 != 0) {
        k = ctz(x3);
        x3 = abs(x3);
        u = u < v ? u : v;
        v = (unsigned) x3 >> k;
        x3 = abs(u - v);
    }
    return u;
}

/**
 * GMP's generic C implementation
 */
int LIMB_HIGHBIT_TO_MASK(int t){
    return  t >> 63;
}

int64_t generic_gcd(int64_t u, int64_t v) {

    /* In this loop, we represent the odd numbers ulimb and vlimb
       without the redundant least significant one bit. This reduction
       in size by one bit ensures that the high bit of t, below, is set
       if and only if vlimb > ulimb. */

    u >>= 1;
    v >>= 1;

    while (u != v) {
        int64_t t;
        int64_t vgtu;
        int64_t c;

        t = u - v;
        vgtu = LIMB_HIGHBIT_TO_MASK(t);

        /* v <-- min (u, v) */
        v += (vgtu & t);

        /* u <-- |u - v| */
        u = (t ^ vgtu) - vgtu;

        c = ctz(u);
        /* We have c <= GMP_LIMB_BITS - 2 here, so that

         ulimb >>= (c + 1);

        would be safe. But unlike the addition c + 1, a separate
        shift by 1 is independent of c, and can be executed in
        parallel with count_trailing_zeros. */
        u = (u >> 1) >> c ;
    }
    return (u << 1) + 1;
}

/**
 * My risc-v64 implementation
 */
int64_t risc_gcd(int64_t u, int64_t v) {

    u >>= 1;
    v >>= 1;

    int64_t mask;
    int64_t t1 = u - v;
    while (t1 != 0) {
        mask = t1 >> 63;
        /**
         * v = min(u, v) bit manipulation
         * if u < v, t1 < 0, mask = 1111, mask & t1 < 0, u += (mask & t1) to become v
         * if u > v, t1 > 0, mask = 0000, mask & t1 < 0, do nothing
         */
        v += (mask & t1);
        printf("%d\n", v);

        // u = abs(t1)
        u = (t1 ^ mask) - mask;
        printf("%d\n", u);

        // discard trailing zeros
        int64_t t2 = u & 1;
        while (t2 == 0) {
            u >>= 1;
            t2 = u & 1;
        }

        u >>= 1;
        t1 = u - v;
    }
    return (u << 1) + 1;
}



int main() {
    int64_t a = 15;
    int64_t b = 11;
    printf("%d", generic_gcd(a, b));
    return 0;
}
