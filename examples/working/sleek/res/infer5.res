Starting Omega...oc

Entail (1) : Valid. 

 <1>false&false&{FLOW,(17,18)=__norm}[]
 inferred pure: [x!=null]


Entail (2) : Valid. 

 <1>false&false&{FLOW,(17,18)=__norm}[]
 inferred pure: [n!=0]


Entail (3) : Fail.(may) cause:AndR[ b!=null |-  inf_b_70=b. LOCS:[19];  true |-  inf_flted_19_74=null. LOCS:[0;19] (may-bug).]

 

Entail (4) : Valid. 

 <1>true&Anon_18=1 & Anon_17=inf_Anon_116 & Anon_19=inf_Anon_120 & inf_ann_119<=0 & inf_ann_115<=0 & b=inf_b_117 & inf_flted_29_121=null&{FLOW,(17,18)=__norm}[]
 inferred heap: [y::node<inf_Anon_120,inf_flted_29_121>@inf_ann_119[Orig]; 
                x::node<inf_Anon_116,inf_b_117>@inf_ann_115[Orig]]
 inferred pure: [inf_flted_29_121=null; b=inf_b_117; inf_ann_115<=0; 
                inf_ann_119<=0]

Stop Omega... 102 invocations 
