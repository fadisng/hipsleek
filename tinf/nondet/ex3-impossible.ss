void f(int x) 
{
  if (x < 0) return;
  else {
    int bbb = __VERIFIER_nondet_int();
    int ccc = __VERIFIER_nondet_int();
    //infer_assume [bbb, ccc];
    if (bbb > 0)
    //if (__VERIFIER_nondet_int() > 0)
      f(x - 1);
    else
      f(x - 1);
  }
}

/*
this example should be terminating

*/