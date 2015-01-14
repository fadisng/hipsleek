extern void __VERIFIER_error() __attribute__ ((__noreturn__));

/*
 * Recursive computation of fibonacci numbers.
 * 
 * Author: Matthias Heizmann
 * Date: 2013-07-13
 * 
 */

extern int __VERIFIER_nondet_int(void);
int fibonacci(int n);
int main();


int fibonacci(int n)
/*@
  infer [@post_n]
  requires true
  ensures true;
 */
{
    if (n < 1) {
        return 0;
    } else if (n == 1) {
        return 1;
    } else {
        return fibonacci(n-1) + fibonacci(n-2);
    }
}

// Expect FAIL
// Return FAIL

int main()
/*@
  requires true
  ensures res!=1;
*/
{
    int x = __VERIFIER_nondet_int();
    int result = fibonacci(x);
    if (x != 5 || result == 3) {
        return 0;
    } else {
      return 1;
      //ERROR: __VERIFIER_error();
    }
}
    

