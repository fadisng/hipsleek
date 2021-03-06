data node {
	int val;
	node next
}

relation dm(int[] a, int low, int high).

axiom dm(a,low,high) & low<=l & h<=high ==> dm(a,l,h).
//axiom dm(a,l+1,h) & dm(a,l,l+1)  ==> dm(a,l,h).
//axiom dm(a,l,h-1) & dm(a,h-1,h) ==> dm(a,l,h).
axiom l>=h ==> dm(a,l,h).
axiom dm(a,l,k) & dm(a,k,h) ==> dm(a,l,h).

ll2<i,j,aaa> == self = null & i=j //& dm(aaa,i,j)
  or self::node<v, r> * r::ll2<i+1,j,aaa> & aaa[i]=v
      & dm(aaa,i,i+1) 
     inv i<=j & dm(aaa,i,j);

node foo(node x)
 requires x::ll2<i,j,aaa>
 ensures res::ll2<i,j,bbb> & forall(k:!(i<=k<j)|bbb[k]=aaa[k]+1) ;
{
  if (x==null) { 
    return null;
  } else {
    //assume false;
    x.val = x.val+1;
    x.next = foo(x.next);
    return x;
  }
}

