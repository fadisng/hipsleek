data node1 {
     node1 next;
}.

data node2 {
     node1 down;
     node2 next;
}.

; EXPECT:
;
; (declare-sort node1 0)
; (declare-fun next () (Field node1 node1))
; (declare-sort node2 0)
; (declare-fun down () (Field node2 node1))
; (declare-fun next () (Field node2 node2))