include(`../config.m4')

define(`u0',    `x0')
define(`v0',    `x1')

# calculate the gcd when both parameters are odd
ASM_START()
    TEXT
    ALIGN(16)
PROLOGUE(mpn_gcd_11)
    subs	x3, u0, v0
    b.eq	L(end)					# jump to end if u == v

ALIGN(16)
    L(top):

# x12 = # of trailing zeros of (u-v)

        rbit	x12, x3				# reverse bit order
        clz	    x12, x12			# count leading zeros

# if u >= v
# 	x3 = u-v
# else
#	x3 = -(u-v)

        csneg	x3, x3, x3, cs		# v = abs(u-v)

# u = u >= v ? v : u

        csel	u0, v0, u0, cs		# u = min(u,v)

# discard trailing zeros
        lsr	    v0, x3, x12			# logical shift right
        subs	x3, u0, v0
        b.ne	L(top)				# if u0 != v0, loop

    L(end):	ret
EPILOGUE()
