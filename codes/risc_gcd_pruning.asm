include(`../config.m4')


# 		a0 for u, also the count of trailing zeros of u 
# 		a1 for v
#  		a2 for the high bit mask
# 		a3 for intermediary value for u, before shifting
#  		a4 for t = u - v
# 		a5 for intermediary value when counting trailing zeros
#  		a6 for __ctz_x & 0xff
# 		t1 for base address of the clz_tab
# 		t3 for the upper limit of __ctz_c  '

ASM_START()

PROLOGUE(mpn_gcd_11)
# u >>= 1;
        srli    a0,a0,1 #, u
# v >>= 1;
        srli    a1,a1,1 #, v
# while (u != v)
        beq     a0,a1,L(end)       #, u, v,
   
L(top):
# t = u - v;
        sub     a4,a0,a1        # t, u, v
# a2 = mask of t (vgtu)
        srai    a2,a4,63        
# the `&` in v += (vgtu & t);
        and     a7,a4,a2    
# the `^` in u = (t ^ vgtu) - vgtu;
        xor     a3,a4,a2        

# the `-` in a3 = (t ^ vgtu) - vgtu
        sub     a3,a3,a2        
# the `+=` in v += (vgtu & t);
        add     a1,a1,a7

# If last bit 1, which should be 50% of the time
        andi	a6,a4,1 
        bne 	a6,x0,L(t_ends_1)

# count trailing zeros
        neg     a5,a4   		# -__ctz_x
        and     a5,a5,a4        # __ctz_x & -__ctz_x
        fcvt.d.lu 	fa5, a5		# convert to double
        fmv.x.d 	a5, fa5 	# load back to integer register
        srli 	a5, a5, 52 		# discard the fragment
        addi 	a0, a5, -1022 	# 1023 is the bias, 1 is the 1 in (u >> 1) >> c
L(end_ctz):
# u = (u >> 1) >> c;
        # srli    a5,a3,1 # already done by modifying the initial value of a0
# u = (u >> 1) >> c;
        srl     a0,a3,a0        
# while (u != v) loop
        bne     a1,a0,L(top)    
L(end):
# return (u << 1) + 1;
        slli    a0,a0,1 
        addi    a0,a0,1 
        ret

# If the last bit of t is 1
L(t_ends_1):
        srli 	a0,a3,1
        bne     a1,a0,L(top)    
        j 		L(end)

  
       

EPILOGUE()
ASM_END()
