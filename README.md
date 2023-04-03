# RISC-V ASM Implementation of `mpn_gcd_11` for Rivos

In short, my codes are in `codes/risc_gcd.asm`. The tarball of the source codes is the `gmp-6.2.1.tar.gz` in this repo. You can skip to the [Tests and Performance](#tests-and-performance) section to reproduce the test result.

The inputs of this function have to be two unsigned 64-bit **odd** integers. It will return the greatest common divisor using the binary gcd algorithm.

**Table of Contents**
+ [Set up](#set-up)
+ [Implementation](#implementation)
  + [Design Decisions](#design-decisions)
+ [Tests and Performance](#tests-and-performance)
  + [Performance Comparison](#performance-comparison)


## Set up
I set up the Qemu environment and tested on silicon as well. 

| Property | Qemu                                   | Silicon                    |
|----------|----------------------------------------|----------------------------|
| OS       | Debian GNU/Linux 12 (bookworm) riscv64 | Ubuntu 22.04.1 LTS riscv64 |
| Host     | riscv-virtio,qemu                      | StarFive VisionFive V1     |
| Kernel   | 6.1.0-7-riscv64                        | 6.1.0-rc6-starfive         |
| CPU      | 1                                      | 2                          |
| Memory   | 7935MiB                                | 7178MiB                    |

Additionally, I find one of the `make check` tests may fail even before I made any changes. It is about `mpz_pow_ui` in the test `reuse` in the `mpz` test suite. It sometimes fails, but mostly does not. One fail log is in `logs/test-suite.log`. I assume it is not a big problem and move on.

## Implementation

I first studied the arm64 asm implementation and the generic C codes to understand their logic and their design decisions. You can find my comments for arm64 asm in `codes/arm64_gcd.asm`.

In addition, I reproduce the three different logic (1st: arm64 asm, 2nd: generic C, 3rd: my riscv64 asm) in a C script for the convenience of testing. You can find it in `codes/summary_gcd.c`.

### Design Decisions
Three important decisions when calculating: 
1. Absolute value
2. Min of two integers
3. Count of trailing zeros

I will discuss the counting of trailing zeros in the Test and Performance section in detail.

**Generic C:**

Their logic avoids branching by bit manipulation. 

First, they obtain the high bit mask of `t`, where `t = u-v`. Then, they calculate the absolute value of `t` by `(t ^ mask) - mask`. They calculate the min of `u` and `v` by `v += (mask & (u-v))`.

However, as the two inputs are unsigned integers, if `u-v > SIGNED_INT_MAX`, then `t` would start from 1 and the `mask` would become 111...111, as if `u-v < 0`. It is not correct. Therefore, they discard the least significant one bit first and then restore it in the end.

```c
mp_limb_t mpn_gcd_11 (mp_limb_t u, mp_limb_t v)
{
  // discard
  u >>= 1;
  v >>= 1;

  while (u != v)
    { 
      mp_limb_t t;
      mp_limb_t vgtu;
      int c;

      t = u - v;
      vgtu = LIMB_HIGHBIT_TO_MASK (t);

      /* v <-- min (u, v) */
      v += (vgtu & t);

      /* u <-- |u - v| */
      u = (t ^ vgtu) - vgtu;

      count_trailing_zeros (c, t);
      u = (u >> 1) >> c;
    }
  // restore
  return (u << 1) + 1;
}
```

**Arm64 asm:**

When they calculate the absolute value and the minimum value, they avoid branching by using conditional selection instructions.
```assembly
		# if u >= v
		# 	x3 = u-v
		# else
		#	x3 = -(u-v)
		csneg	x3, x3, x3, cs		#  			v = abs(u-v)

		# u = u >= v ? v : u
		csel	u0, v0, u0, cs		# 			u = min(u,v)
```
When counting the trailing zeros, they use the `clz` instruction.
```assembly
		# x12 = count of trailing zeros of (u-v)
		rbit	x12, x3				#			reverse bit order
		clz 	x12, x12			#			count leading zeros
```

**Riscv64 asm:**

As risc-v does not have conditional selection instruction, I implement the logic basically following the generic C.

In terms of counting the trailing zeros, I find `ctz` available in the risc-v bit manipulation ISA extension. However, I assume I should write the codes compatible with all riscv64 CPUs, so I choose not to use it.

Currently, I count the trailing zeros by an ugly for loop, which achieves the functionality but should be optimized later. My codes are in `codes/risc_gcd.asm`.
## Tests and Performance
I modified the `tests/mpn/t-gcd_11.c` to add the CPU clock logging. You can find a copy of this test in this repository `codes/t-gcd_11.c`.

Follow the following steps on a riscv64 linux environment to reproduce the test result:

```bash
wget https://github.com/SiyaoIsHiding/risc-v-gmp-gcd/raw/main/gmp-6.2.1.tar.gz
tar -xvzf gmp-6.2.1.tar.gz
cd gmp-6.2.1
./configure
make
make check
```

Now you can `cat ./tests/mpn/t-gcd_11.log` to see the test result as well as the CPU clock used. 

```txt
Start clock: 50462
End clock: 1681269
Total clock used: 1630807
PASS t-gcd_11 (exit status: 0)
```

You can also run `./tests/mpn/t-gcd_11` several times to see whether the performance is stable.

You can also modify my codes to make it fail. `vim ./mpn/riscv/64/gcd_11.asm` and add 1 to the return value:

```assembly
L(end): 
        slli    u0, u0, 1
        addi    u0, u0, 1
        addi    u0, u0, 1                       #       To make it fail
        ret
```

Then `make` and `make check` again.

When running the `mpn` test suite, it will fail the test `t-fat`, and then right after `t-brootinv`, stuck at `t-minvert`, without being aborted. Still, you can `Ctrl+C` to exit, and run `./tests/mpn/t-gcd_11` by yourself, and you will see:

```txt
Start clock: 4657
gcd_11 (0x1ff800fe007fc1, 0xfcf) failed, got: 0x2, ref: 0x1
Aborted
```

This indicates my codes are loaded and failing as expected.

### Performance Comparison

I wonder whether my codes can benefit the performance of this function.

First, I use the command `gcc -S -fverbose-asm -O2 ./gmp-original/mpn/generic/gcd_11.c -I./gmp-original -L./gmp-original` to obtain the assembly code compiled automatically by gcc from the generic C code. You can find it in `codes/generic_gcd.s`. It is much longer than mine, so I thought it might be slower than mine, but it is not true.

Here is the performance comparison of the total CPU clock used in the test `t-gcd_11.c`:

| Env     | Generic C                          | My Riscv Assembly                  |
|---------|------------------------------------|------------------------------------|
| Silicon | Stable between 1060000 and 1120000 | Stable between 1080000 and 1140000 |
| Qemu    | Stable between 1400000 and 1490000 | Stable between 1480000 and 1560000 |

It indicates that the generic C implementation is usually a little bit faster than mine. I look into it and find the problem may lie in the counting of trailing zeros.

If my conjecture is correct, then my codes should have an advantage when calculating small numbers. Therefore, I write another test, which is to calculate the `gcd_11` of small numbers only for 5000 times. You can find it in `codes/test_small_num.c`. Here is the test result of the total CPU clock used:

| Env     | Generic C                                               | My Riscv Assembly            |
|---------|---------------------------------------------------------|------------------------------|
| Silicon | Vary wildly from 1269 the smallest and 2582 the largest | Stable between 1250 and 1450 |
| Qemu    | Stable between 5400 and 6500                            | Stable between 5500 and 6500 |

The reason why the silicon performance fluctuates wildly is unknown yet. However, there is no obvious performance regression in my riscv64 asm codes when calculating small numbers, which confirms my conjecture.

I tried to study how they implement the `count_trailing_zeros`. But I cannot fully understand it for now.

Their implementation is in their `./longlong.h`. There are many different implementations in that file, optimized for each environment excluding risc-v. I believe the one in use is the following one.

It seems like they use (x & -x) to find the least significant bit, and then use the lookup table for counting leading zeros to find the count of trailing zeros (`__clz_tab[__ctz_x & -__ctz_x]`).

```c
/* Define count_trailing_zeros in plain C, assuming small counts are common.
   We use clz_tab without ado, since the C count_leading_zeros above will have
   pulled it in.  */
#define count_trailing_zeros(count, x)                                  \
  do {                                                                  \
    UWtype __ctz_x = (x);                                               \
    int __ctz_c;                                                        \
                                                                        \
    if (LIKELY ((__ctz_x & 0xff) != 0))                                 \
      (count) = __clz_tab[__ctz_x & -__ctz_x] - 2;                      \
    else                                                                \
      {                                                                 \
        for (__ctz_c = 8 - 2; __ctz_c < W_TYPE_SIZE - 2; __ctz_c += 8)  \
          {                                                             \
            __ctz_x >>= 8;                                              \
            if (LIKELY ((__ctz_x & 0xff) != 0))                         \
              break;                                                    \
          }                                                             \
                                                                        \
        (count) = __ctz_c + __clz_tab[__ctz_x & -__ctz_x];              \
      }                                                                 \
  } while (0)
```

Although I cannot fully understand it, I can see the corresponding logic in the automatically compiled assembly file.

That's all of my current progress. If you can provide some guidance on the implementation of counting the trailing zeros, I am more than willing to optimize it further.
