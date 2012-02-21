
Processing file "num-app.ss"
Parsing num-app.ss ...
Parsing ../../prelude.ss ...
Starting Reduce... 
Starting Omega...oc
Translating global variables to procedure parameters...

Checking procedure appN$int~int... 
!!! >>>>>> HIP gather infer pre <<<<<<
!!! Inferred Heap :[]
!!! Inferred Pure :[ 1<=n, 1<=n]
!!! REL :  A(n,m,res)
!!! POST:  n>=1 & n+m=res
!!! PRE :  1<=n
!!! OLD SPECS: ((None,[]),EInfer [n,m,A]
              EBase true&true&{FLOW,(20,21)=__norm}
                      EBase true&MayLoop&{FLOW,(1,23)=__flow}
                              EAssume 1::
                                true&A(n,m,res)&{FLOW,(20,21)=__norm})
!!! NEW SPECS: ((None,[]),EBase true&1<=n & MayLoop&{FLOW,(1,23)=__flow}
                    EAssume 1::
                      true&n>=1 & n+m=res&{FLOW,(20,21)=__norm})
!!! NEW RELS:[ (n=1 & -1+res=m) --> A(n,m,res),
 (1<=v_int_12_522 & -1+n=v_int_12_522 & -1+res=v_int_12_526 & 
  A(v_int_12_522,m,v_int_12_526)) --> A(n,m,res)]
!!! NEW ASSUME:[]
!!! NEW RANK:[]
Procedure appN$int~int SUCCESS

Termination checking result:

Stop Omega... 94 invocations 
0 false contexts at: ()

Total verification time: 0.21 second(s)
	Time spent in main process: 0.15 second(s)
	Time spent in child processes: 0.06 second(s)
