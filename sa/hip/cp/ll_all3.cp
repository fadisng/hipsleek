HeapPred HP_1(node a).
HeapPred HP_2(node a, node b).

ret_first[
ass [H1,G2]:{
    H1(x) & x'=x & v=x' --> G2(x,v)
	}

hpdefs [H1,G2]:{
 H1(p) --> htrue&true;
 G2(x,y) --> x=y

 }
]
