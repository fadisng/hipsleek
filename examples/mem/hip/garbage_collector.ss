data node {
	int val; 
	node next;
	node left;
	node right;	
}


graph<v,M> == self = null & M = {}
	or self::node<0,_@A,l@L,r@L> * l::graph<_,Ml> & r::graph<_,Mr> & M = union(Ml,Mr,{self}) & v = 0
	or self::node<1@I,_@A,l@L,r@L> * l::graph<1,Ml> & r::graph<1,Mr> & M = union(Ml,Mr,{self}) & v = 1
	inv true
	mem M->(node<@M,@A,@L,@L> & v = 0 ; node<@I,@A,@L,@L> & v != 0);

ll<v,M> == self = null & M = {}
	or self::node<0@I,p,_@A,_@A> * p::ll<0,Mp> & M = union(Mp,{self}) & v = 0
	or self::node<1@I,p,_@A,_@A> * p::ll<1,Mp> & M = union(Mp,{self}) & v = 1
	inv true
	mem M->(node<@I,@M,@A,@A> & v = 0 ; node<@I,@M,@A,@A> & v != 0);


void mark(node x)
  requires x::graph<_,M>
  ensures x::graph<1,M>;
{
node l,r;
if(x == null) return;
else {
if (x.val == 1) return;
l = x.left;
r = x.right;
x.val = 1;
mark(l);
mark(r);
}
}

void sweep(ref node free, node x, ref node p)
  requires free::ll<0,Mf> * (x::graph<1,M> & p::ll<_,Mp>)
  ensures free'::ll<0,Mf2> * (x::graph<1,M> & p'::ll<_,Mp2>);
{
//mark(x);
if(p == null) return;
else{
if(p.val != 1){ 
move(free,p);
}
else p = p.next;
if(p != null)
	sweep(free,x,p);
else return;
}
}

void move(ref node free, ref node p)
requires free::ll<0,Mf> * p::node<_@I,q,_@A,_@A> * q::ll<_,Mq>
ensures p::node<0@I,free,_@A,_@A> * free::ll<0,Mf> * q::ll<_,Mq> & p' = q & free' = p; 

void collect(ref node alloted, node x, ref node free)
  requires free::ll<0,Mf> * (x::graph<_,M> & alloted::ll<_,Mp>)
  ensures free'::ll<0,Mf2> * (x::graph<1,M> & alloted'::ll<_,Mp2>);
{
mark(x);
sweep(free,x,alloted);
}
  
