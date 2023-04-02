.file   "gcd_11.c"
        .option pic
# GNU C17 (Ubuntu 11.3.0-1ubuntu1~22.04) version 11.3.0 (riscv64-linux-gnu)
#       compiled by GNU C version 11.3.0, GMP version 6.2.1, MPFR version 4.1.0, MPC version 1.2.1, isl version isl-0.24-GMP

# GGC heuristics: --param ggc-min-expand=100 --param ggc-min-heapsize=131072
# options passed: -mabi=lp64d -misa-spec=2.2 -march=rv64imafdc -O2 -fstack-protector-strong
        .text
        .align  1
        .globl  __gmpn_gcd_11
        .type   __gmpn_gcd_11, @function
__gmpn_gcd_11:
# ./gmp-original/mpn/generic/gcd_11.c:45:   u >>= 1;
        srli    a0,a0,1 #, u, tmp126
# ./gmp-original/mpn/generic/gcd_11.c:46:   v >>= 1;
        srli    a1,a1,1 #, v, tmp127
# ./gmp-original/mpn/generic/gcd_11.c:48:   while (u != v)
        beq     a0,a1,.L2       #, u, v,
        la      t1,__gmpn_clz_tab               # tmp121,
# ./gmp-original/mpn/generic/gcd_11.c:63:       count_trailing_zeros (c, t);
        li      t3,62           # tmp124,
.L6:
# ./gmp-original/mpn/generic/gcd_11.c:54:       t = u - v;
        sub     a4,a0,a1        # __ctz_x, u, v
# ./gmp-original/mpn/generic/gcd_11.c:55:       vgtu = LIMB_HIGHBIT_TO_MASK (t);
        srai    a2,a4,63        #, vgtu, __ctz_x
# ./gmp-original/mpn/generic/gcd_11.c:58:       v += (vgtu & t);
        and     a7,a4,a2        # vgtu, tmp99, __ctz_x
# ./gmp-original/mpn/generic/gcd_11.c:61:       u = (t ^ vgtu) - vgtu;
        xor     a3,a4,a2        # vgtu, tmp100, __ctz_x
# ./gmp-original/mpn/generic/gcd_11.c:63:       count_trailing_zeros (c, t);
        andi    a6,a4,255       #, tmp101, __ctz_x
        mv      a5,a1   # v, v
# ./gmp-original/mpn/generic/gcd_11.c:61:       u = (t ^ vgtu) - vgtu;
        sub     a3,a3,a2        # u, tmp100, vgtu
# ./gmp-original/mpn/generic/gcd_11.c:58:       v += (vgtu & t);
        add     a1,a1,a7        # tmp99, v, v
# ./gmp-original/mpn/generic/gcd_11.c:63:       count_trailing_zeros (c, t);
        beq     a6,zero,.L8     #, tmp101,,
# ./gmp-original/mpn/generic/gcd_11.c:63:       count_trailing_zeros (c, t);
        sub     a5,a5,a0        # tmp103, v, u
        and     a5,a5,a4        # __ctz_x, tmp104, tmp103
        add     a5,t1,a5        # tmp104, tmp105, tmp121
        lbu     a0,0(a5)        # __gmpn_clz_tab[_10], __gmpn_clz_tab[_10]
        addiw   a0,a0,-2        #, c, __gmpn_clz_tab[_10]
.L4:
# ./gmp-original/mpn/generic/gcd_11.c:71:       u = (u >> 1) >> c;
        srli    a5,a3,1 #, _21, u
# ./gmp-original/mpn/generic/gcd_11.c:71:       u = (u >> 1) >> c;
        srl     a0,a5,a0        # c, u, _21
# ./gmp-original/mpn/generic/gcd_11.c:48:   while (u != v)
        bne     a1,a0,.L6       #, v, u,
.L2:
# ./gmp-original/mpn/generic/gcd_11.c:73:   return (u << 1) + 1;
        slli    a0,a0,1 #, tmp120, u
# ./gmp-original/mpn/generic/gcd_11.c:74: }
        addi    a0,a0,1 #,, tmp120
        ret
.L8:
# ./gmp-original/mpn/generic/gcd_11.c:63:       count_trailing_zeros (c, t);
        li      a2,6            # __ctz_c,
.L3:
# ./gmp-original/mpn/generic/gcd_11.c:63:       count_trailing_zeros (c, t);
        srli    a4,a4,8 #, __ctz_x, __ctz_x
        andi    a5,a4,255       #, tmp108, __ctz_x
        beq     a5,zero,.L12    #, tmp108,,
.L5:
# ./gmp-original/mpn/generic/gcd_11.c:63:       count_trailing_zeros (c, t);
        neg     a5,a4   # tmp113, __ctz_x
        and     a5,a5,a4        # __ctz_x, tmp114, tmp113
        add     a5,t1,a5        # tmp114, tmp115, tmp121
        lbu     a0,0(a5)        # __gmpn_clz_tab[_18], __gmpn_clz_tab[_18]
        addw    a0,a0,a2        # __ctz_c, c, __gmpn_clz_tab[_18]
        j       .L4             #
.L12:
# ./gmp-original/mpn/generic/gcd_11.c:63:       count_trailing_zeros (c, t);
        addiw   a2,a2,8 #, __ctz_c, __ctz_c
        beq     a2,t3,.L5       #, __ctz_c, tmp124,
        j       .L3             #
        .size   __gmpn_gcd_11, .-__gmpn_gcd_11
        .ident  "GCC: (Ubuntu 11.3.0-1ubuntu1~22.04) 11.3.0"
        .section        .note.GNU-stack,"",@progbits
