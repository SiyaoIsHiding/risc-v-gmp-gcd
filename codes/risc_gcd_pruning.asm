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
        la      t1,__gmpn_clz_tab               

        li      t3,62           
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

# init for count_trailing_zeros   
        andi    a6,a4,255
# a5 is the previous v
        sub		a5,a1,a7
        beq     a6,zero,L(ctz_ge_8)    
# if ctz < 8, which is 99% of the time
        sub     a5,a5,a0        # -__ctz_x
        and     a5,a5,a4        # __ctz_x & -__ctz_x
        add     a5,t1,a5        # address of __clz_tab[__ctz_x & -__ctz_x]
        lbu     a0,0(a5)        # __clz_tab[__ctz_x & -__ctz_x]
        addiw   a0,a0,-1        # a0 = count of trailing zeros
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

# If the count of trailing zeros is greater than or equal to 8
# 		a2 for __ctz_c
# 		a4 for __ctz_x, aka t, aka |u-v|
# 		a5 for intermediary value
L(ctz_ge_8):
        li      a2,7            # init __ctz_c
L(loop_by_byte):
        srli    a4,a4,8 
        andi    a5,a4,255       # __ctz_x & 0xff  
        beq     a5,zero,L(next_byte)    
L(found_n_lookup):
        neg     a5,a4   		# -__ctz_x
        and     a5,a5,a4        # __ctz_x & -__ctz_x
        add     a5,t1,a5        # address of __clz_tab[__ctz_x & -__ctz_x]
        lbu     a0,0(a5)        # __clz_tab[__ctz_x & -__ctz_x]
        addw    a0,a0,a2        # __ctz_c = __ctz_c + __clz_tab[__ctz_x & -__ctz_x];
        j       L(end_ctz)      
L(next_byte):
        addiw   a2,a2,8  		# __ctz_c += 8
        beq     a2,t3,L(found_n_lookup)       
        j       L(loop_by_byte)           

EPILOGUE()
ASM_END()
