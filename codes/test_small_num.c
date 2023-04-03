#include <gmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>


int main(int argc, char * argv[]){
  mpz_t u;
  mpz_t v;
  mpz_t g;

  mpz_init_set_ui(g,0);
  mpz_init(u);
  mpz_init(v);

  mpz_set_str(u,"45",10);
  mpz_set_str(v,"27",10);

  mp_limb_t ul = mpz_getlimbn(u,0);
  mp_limb_t vl = mpz_getlimbn(v,0);

  mp_limb_t r;

  clock_t start, end;
  start = clock();
  printf("Start clock is %ld\n", start);
  for(int i = 0; i < 5000; i++){
          r = mpn_gcd_11(ul,vl);
          mpz_add_ui(u,u,2);
          mpz_add_ui(v,v,2);
          ul = mpz_getlimbn(u,0);
          vl = mpz_getlimbn(v,0);
  }

  end = clock();
  printf("End clock is %ld\n", end);
  printf("Total clock used to calculate gcd_11 for 5000 times is %ld\n", end-start);

  return 1;
}
