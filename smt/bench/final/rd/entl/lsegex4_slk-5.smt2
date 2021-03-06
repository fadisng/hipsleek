(set-logic QF_S)
(set-info :source |  Sleek solver
  http://loris-7.ddns.comp.nus.edu.sg/~project/s2/beta/
|)

(set-info :smt-lib-version 2.0)
(set-info :category "crafted")
(set-info :status unsat)


(declare-sort node 0)
(declare-fun nxt () (Field node node))

(define-fun lseg ((?in node) (?p node))
Space (tospace
(or
(= ?in ?p)
(exists ((?a node))(and 
(tobool (ssep 
(pto ?in  (ref nxt ?a))
(lseg ?a ?p)
) )
)))))




(define-fun right1 ((?in node) (?p node))
Space (tospace
(exists ((?u node))(and 
(tobool (ssep 
(lseg ?in ?u)
(pto ?u  (ref nxt ?p))
) )
))))



(define-fun right2 ((?in node) (?p node))
Space (tospace
(exists ((?u node))(and 
(tobool (ssep 
(lseg ?in ?u)
(lseg ?u ?p)
) )
))))


(define-fun right3 ((?in node) (?p node))
Space (tospace
(exists ((?u node)(?u2 node))(and 
(tobool (ssep 
(lseg ?in ?u)
(lseg ?u ?u2)
(lseg ?u2 ?p)
) )
))))


(define-fun right4 ((?in node))
Space (tospace
(exists ((?u node)(?w node))(and 
(tobool (ssep 
(lseg ?in ?u)
(lseg ?u ?w)
) )
))))


(define-fun right5 ((?in node))
Space (tospace
(exists ((?w node))(and 
(tobool  
(lseg ?in ?w)
 )
))))


(declare-fun p () node)
(declare-fun x () node)


(assert 
(and 
(tobool  
(lseg x p)
 )
)
)

(assert (not 
(and 
(tobool  
(right4 x)
 )
)
))

(check-sat)