(set-logic QF_S)

(declare-sort node 0)
(declare-fun nxt () (Field node node))

(define-fun ll ((?in node) (?n Int))
Space (tospace
(or
(= ?in nil)
(= ?n 0)
(exists ((?a node)(?m Int)) (tobool (ssep (pto ?in  (ref nxt ?a)) (ll ?a ?m))))
)))
















(declare-fun n () Int)
(declare-fun x () node)


(assert 
(and 
(= n 0)
(distinct x nil)
(tobool (ssep 
(ll x n)
emp
) )
)
)


(check-sat)