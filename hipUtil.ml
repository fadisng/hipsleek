#include "xdebug.cppo"
(* open VarGen *)
open Gen
(* open Basic *)
open Globals

let proc_files = new stack_noexc "proc_files" "__no_file" pr_id (fun s1 s2 -> s1=s2) 


module Name =
struct
  type t = ident
  let compare = compare
  let hash = Hashtbl.hash
  let equal = ( = )
end

module NG = Graph.Imperative.Digraph.Concrete(Name)
module NGComponents = Graph.Components.Make(NG)
module TopoNG = Graph.Topological.Make(NG)
module DfsNG = Graph.Traverse.Dfs(NG)

class graph =
  object (self)
    val mutable nlst = Hashtbl.create 20
    val mutable grp = None
    val mutable scc = []
    val mutable pto = [] (* pt_to rec & non-rec e.g. p->([q],[r])*)
    val mutable self_rec = [] (* those with self-recursive *)
    val mutable self_rec_only = [] (* those with self-recursive call only *)
    val mutable mut_rec = [] (* those in mutual-recursion *)
    val mutable dom = [] (* those in mutual-recursion *)

    method reset =
      grp <- None;
      Hashtbl.clear nlst

    method replace n lst  =
      grp <- None;
      Hashtbl.replace nlst n lst

    method remove n  =
      grp <- None;
      Hashtbl.remove nlst n

    method exists n  =
      Hashtbl.mem nlst n

    method is_self_rec n  =
      let r = self # find_rec n in
      List.exists (fun v -> n=v) r

    (* method is_self_rec_only n  = *)
    (*   if grp==None then self # build_scc_void; *)
    (*   List.exists (fun v -> n=v) self_rec_only *)

    method find_rec n  =
      if grp==None then self # build_scc_void;
      try
        snd(List.find (fun (a,_) -> a=n) pto)
      with _ -> []

    method split n  =
      if grp==None then self # build_scc_void;
      let (nrec_n,rec_n) = List.partition (fun (a,r) -> r==[]) pto in
      let (self_r,mut_r) = List.partition (fun (a,r) -> List.exists (fun m -> a=m) r) rec_n in
      (List.map fst nrec_n,List.map fst self_r,List.map fst mut_r)

    method get_rec  =
      let (_,self_r,mut_r) = self # split in
      (self_r,mut_r)

    method is_rec n  =
      (self # find_rec n) != []

    method in_dom n  =
      if grp==None then self # build_scc_void;
      (List.exists (fun v -> n=v) dom)

    method build_scc  =
      let g = NG.create () in
      self_rec <- [];
      pto <- [];
      dom <- Hashtbl.fold (fun n xs acc-> n::acc) nlst [];
      let () = Hashtbl.iter (fun n edges ->
          if List.exists (fun v -> n=v) edges then self_rec <- n::self_rec;
          List.iter (fun t ->
              NG.add_edge g (NG.V.create n) (NG.V.create t)
            ) edges
        ) nlst in
      let scclist = NGComponents.scc_list g in
      scc <- scclist;
      grp <- Some g;
      pto <- List.concat
          (List.map (fun sc ->
               List.map (fun m ->
                   try
                     let edges = Hashtbl.find nlst m in
                     let rec_callee = BList.intersect_eq (=) sc edges in
                     (m,rec_callee)
                   with _ ->
                     begin
                       y_winfo_pp "Unexpected exception";
                       failwith "HipUtil.Graph"
                     end
                 ) sc
             ) scclist);
      (* let mutlist = List.filter (fun lst -> (List.length lst)>1) scclist in *)
      (* mut_rec <- List.concat mutlist; *)
      (* self_rec_only <- BList.difference_eq (=) self_rec mut_rec; *)
      scclist

    method build_scc_void  =
      let scclist = self # build_scc in
      ()

    method get_scc  =
      match grp with
      | Some _ -> scc
      | None -> self # build_scc

    method get_graph  =
      match grp with
      | Some g -> g
      | None -> 
        let _ = self # build_scc in
        self # get_graph

    method string_of  =
      if grp==None then self # build_scc_void;
      let str = "SCC:"^((pr_list ((pr_list pr_id))) scc) in
      let lst = (Hashtbl.fold (fun n xs acc-> (n,xs)::acc) nlst []) in
      let str2 = pr_list (pr_pair pr_id (pr_list pr_id)) lst in
      let str = str^"\nGraph:"^str2 in 
      (* print_endline_quiet *) str
  end;;

let view_scc_obj = new graph;;
