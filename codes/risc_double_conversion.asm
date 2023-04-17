include(`../config.m4')


# 		a0 for u, also the count of trailing zeros of u
# 		a1 for v
#  		a2 for the high bit mask
# 		a3 for intermediary value for u, before shifting
#  		a4 for t = u - v
# 		a5 for intermediary value when counting trailing zeros and also the final count

ASM_START()

PROLOGUE(mpn_gcd_11)
# u >>= 1
        srli    a0,a0,1
# v >>= 1
        srli    a1,a1,1
# while (u != v)
        beq     a0,a1,L(end)

L(top):
# t = u - v
        sub     a4,a0,a1
# a2 = mask of t (vgtu)
        srai    a2,a4,63
# the `&` in v += (vgtu & t)
        and     a7,a4,a2
# the `^` in u = (t ^ vgtu) - vgtu
        xor     a3,a4,a2

# the `-` in a3 = (t ^ vgtu) - vgtu
        sub     a3,a3,a2
# the `+=` in v += (vgtu & t)
        add     a1,a1,a7

# count trailing zeros
        neg     a5,a4   		# -__ctz_x
        and     a5,a5,a4        # __ctz_x & -__ctz_x
        fcvt.d.lu 	fa5, a5		# convert to double
        fmv.x.d 	a5, fa5 	# load back to integer register
        srli 	a5, a5, 52 		# discard the fraction
        addi 	a5, a5, -1022 	# 1023 is the bias, 1 is the 1 in (u >> 1) >> c

# u = (u >> 1) >> c
        srl     a0,a3,a5
# while (u != v) loop
        bne     a1,a0,L(top)
L(end):
# return (u << 1) + 1
        slli    a0,a0,1
        addi    a0,a0,1
        ret





EPILOGUE()
ASM_END()
