include(`../config.m4')

C  INPUT PARAMETERS
define(`u0',    `a0')
define(`v0',    `a1')

C       t1 for the temprory value of v, which is |u-v| with trailing zeros descarded
C       t2 for the temprory value of the last bit of t1
C       t3 for the high bit mask, which will be 11..11 if t1 is negative, and 00..00 if positive
C       t4 for intermidiary value during bit manipulation

ASM_START()

PROLOGUE(mpn_gcd_11)


        srli    u0, u0, 1
        srli    v0, v0, 1

        C       t1 = u-v
        sub     t1, u0, v0
        beq     x0, t1, L(end)                  C       if two inputs same, jump end


L(top): 
        C       v = min(u, v)
        C       v += (mask & t1)                C       should optimize to t1 = v-u later
        srai    t3, t1, 63                      C       high bit mask
        and     t4, t3, t1
        add     v0, v0, t4

        C       u = |u-v|
        C       u = (t1 ^ mask) - mask
        xor     t4, t1, t3
        sub     u0, t4, t3

        C       handling the trailing zeros
        andi    t2, u0, 1
        bne     x0, t2, L(end_discard_tz)       C       if no trailing zero
L(discard_tz):      C   of t1
        srai    u0, u0, 1
        andi    t2, u0, 1
        beq     t2, x0, L(discard_tz)           C       if still trailing zero
L(end_discard_tz):

        srai    u0, u0, 1     

        sub     t1, u0, v0    
        bne     x0, t1, L(top)          
        
L(end): 
        slli    u0, u0, 1
        addi    u0, u0, 1

        ret


        
EPILOGUE()
ASM_END()
