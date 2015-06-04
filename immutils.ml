#include "xdebug.cppo"

(* extension of cpure, focused on imm related operations  *)

open Globals
open VarGen
open Gen.Basic
open Cpure

let int_imm_to_exp i loc = 
  mkExpAnnSymb (mkConstAnn (heap_ann_of_int i)) loc

let ann_sv_lst  = (name_for_imm_sv Mutable):: (name_for_imm_sv Imm):: (name_for_imm_sv Lend)::[(name_for_imm_sv Accs)]

let is_ann_const_sv sv = 
  match sv with
  | SpecVar(AnnT,a,_) -> List.exists (fun an -> an = a ) ann_sv_lst
  | _                 -> false

let helper_is_const_ann_sv em sv test =
  let imm_const_sv = mkAnnSVar test in
  if not (is_ann_typ sv) then false
  else if eq_spec_var sv imm_const_sv then true
  else EMapSV.is_equiv em sv imm_const_sv 

let is_mut_sv ?emap:(em=[])  sv = helper_is_const_ann_sv em sv Mutable 

let is_imm_sv ?emap:(em=[])  sv = helper_is_const_ann_sv em sv Imm

let is_lend_sv ?emap:(em=[]) sv = helper_is_const_ann_sv em sv Lend

let is_abs_sv ?emap:(em=[])  sv = helper_is_const_ann_sv em sv Accs

let is_imm_const_sv ?emap:(em=[])  sv = 
  (is_abs_sv ~emap:em sv) ||   (is_mut_sv ~emap:em sv) ||   (is_lend_sv ~emap:em sv) ||   (is_imm_sv ~emap:em sv)

let get_imm_list ?loc:(l=no_pos) list =
  let elem_const = (mkAnnSVar Mutable)::(mkAnnSVar Imm)::(mkAnnSVar Lend)::[(mkAnnSVar Accs)] in
  let anns_ann =  (ConstAnn(Mutable))::(ConstAnn(Imm))::(ConstAnn(Lend))::[(ConstAnn(Accs))] in
  let anns_exp =  (AConst(Mutable,l))::(AConst(Imm,l))::(AConst(Lend,l))::[(AConst(Accs,l))] in
  let anns = List.combine anns_ann anns_exp in
  let lst = List.combine elem_const anns in
  let imm = 
    try
      Some (snd (List.find (fun (a,_) -> EMapSV.mem a list  ) lst ) )
    with Not_found -> None
  in imm

let get_imm_emap ?loc:(l=no_pos) sv emap =
  let aliases = EMapSV.find_equiv_all sv emap in
  get_imm_list ~loc:l aliases

let get_imm_emap_exp_opt  ?loc:(l=no_pos) sv emap : exp option = map_opt snd (get_imm_emap ~loc:l sv emap)

let get_imm_emap_exp  ?loc:(l=no_pos) sv emap : exp  = 
  map_opt_def (mkVar sv l) (fun x -> x) (get_imm_emap_exp_opt ~loc:l sv emap)

let get_imm_emap_ann_opt  ?loc:(l=no_pos) sv emap : ann option = map_opt fst (get_imm_emap ~loc:l sv emap)

(* replace with imm constant, where exp is constant or variable *)
let norm_emap_imm_exp  ?loc:(l=no_pos) (e: exp) emap : exp  = 
  match e with
  | Var(sv,l) ->  get_imm_emap_exp ~loc:l sv emap
  | _ -> e

let eq_const_ann const_imm em sv = 
  match const_imm with
  | Mutable -> is_mut_sv ~emap:em sv
  | Imm     -> is_imm_sv ~emap:em sv
  | Lend    -> is_lend_sv ~emap:em sv
  | Accs    -> is_abs_sv ~emap:em sv

let helper_is_const_imm em (imm:ann) const_imm = 
  match imm with
  | ConstAnn a -> a == const_imm
  | PolyAnn sv -> eq_const_ann const_imm em sv 
  | _ -> false

(* below functions take into account the alias information while checking if imm is a certain const. *)
let is_abs ?emap:(em=[]) (imm:ann) = helper_is_const_imm em imm Accs
let is_abs_exp ?emap:(em=[]) (e: exp) = is_abs ~emap:em (exp_to_imm e)

let is_abs_list ?emap:(em=[]) imm_list = List.for_all (is_abs ~emap:em) imm_list

let is_mutable ?emap:(em=[]) (imm:ann) = helper_is_const_imm em imm Mutable 

let is_mutable_list ?emap:(em=[]) imm_list =  List.for_all (is_mutable ~emap:em) imm_list

let is_immutable ?emap:(em=[]) (imm:ann) = helper_is_const_imm em imm Imm

let is_immutable_list ?emap:(em=[]) imm_list =  List.for_all (is_immutable ~emap:em) imm_list

let is_lend ?emap:(em=[]) (imm:ann) = helper_is_const_imm em imm Lend

let is_lend_list ?emap:(em=[]) imm_list =  List.for_all (is_lend ~emap:em) imm_list

let isAccs (a : ann) : bool = is_abs a

let isLend(a : ann) : bool = is_lend a

let isMutable(a : ann) : bool = is_mutable a

let isImm(a : ann) : bool = is_immutable a

let isPoly(a : ann) : bool = 
  match a with
  | PolyAnn v -> true
  | _ -> false

let is_const_imm ?emap:(em=[]) (a:ann) : bool =
  match a with
  | ConstAnn _ -> true
  | PolyAnn sv -> (is_mutable ~emap:em a) || (is_immutable ~emap:em a) || (is_lend ~emap:em a) || (is_abs ~emap:em a)
  | _ -> false

let is_const_imm_list ?emap:(em=[]) (alst:ann list) : bool =
  List.for_all (is_const_imm ~emap:em) alst

(* end imm utilities *)

let contains_imm (f:formula) =
  let f_e e =  Some (is_ann_type (get_exp_type e)) in
  fold_formula f (nonef,nonef, f_e)  (List.exists (fun b -> b) )

let contains_imm (f:formula) =
  Debug.no_1 "contains_imm" !print_formula string_of_bool contains_imm f

(* assumption: f is in CNF *)
let build_eset_of_imm_formula f =
  let lst = split_conjunctions f in
  let emap = List.fold_left (fun acc f -> match f with
      | BForm (bf,_) ->
        (match bf with
         | (Eq (Var (v1,_), Var (v2,_), _),_) -> 
           if (is_bag_typ v1) then acc
           else EMapSV.add_equiv acc v1 v2
         | (Eq (ex, Var (v1,_), _),_) 
         | (Eq (Var (v1,_), ex, _),_) -> 
           (match conv_ann_exp_to_var ex with
            | Some (v2,_) -> EMapSV.add_equiv acc v1 v2
            | None -> acc)
         | (SubAnn (Var (v1,_), (AConst(Mutable,_) as exp), _),_) -> (* bot *)
           let v2 = mkAnnSVar Mutable in EMapSV.add_equiv acc v1 v2
         | (SubAnn(AConst(Accs,_) as exp, Var (v1,_), _),_) -> (* top *)
           let v2 = mkAnnSVar Accs in EMapSV.add_equiv acc v1 v2
         | _ -> acc)
      | _ -> acc
    ) EMapSV.mkEmpty lst in emap

let build_eset_of_imm_formula f =
  let pr = !print_formula in
  let pr_out = EMapSV.string_of in
  Debug.no_1 "build_eset_of_imm_formula" pr pr_out build_eset_of_imm_formula f

(* ===================== imm addition utils ========================= *)

(* assume e is Add(..) *)
let get_imm_var_cts_operands e =
  let rec helper e =
    match e with
    | Add (a1,a2,_) -> (helper a1)@(helper a2)
    | Var (sv, _)   -> [sv]
    | AConst (a,l)  -> [mkAnnSVar a]
    | _             -> []               (* should never reach this point if sum is well defined *)
  in helper e

let get_imm_var_cts_operands e =
  Debug.no_1 "let get_imm_var_cts_operands" !print_exp !print_svl get_imm_var_cts_operands e

let mkAdd_list exp_lst =  
  let rec helper exp_lst = 
    match exp_lst with
    | [] -> AConst (Accs, no_pos)
    | [(AConst _ as e)]
    | [(Var _ as e)]  ->  e
    | e::tail -> Add(e, helper tail, no_pos)
  in helper exp_lst

let sv_to_imm_exp_flag_change sv emap loc = 
  let return_same_sv = (mkVar sv loc, true) in
  if is_ann_const_sv sv then (get_imm_emap_exp ~loc:loc sv emap, true)
  else 
    let ne = get_imm_emap_exp_opt ~loc:loc sv emap in
    map_opt_def return_same_sv (fun x -> (x,false)) ne

(* prune @A's from imm summation and replace vars with their corresponding constants if the information exists *)
let imm_summation emap e =

  (* retrieve addition operands - constanst or sv only *)
  let sum_operands = get_imm_var_cts_operands e in 

  (* replace vars with their corresponding constants if this info exists in emap *)
  let sum_operands = List.map (fun sv -> sv_to_imm_exp_flag_change sv emap (pos_of_exp e)) sum_operands in
  let sum_operands, fixptaux = List.split sum_operands in
  let fixpt = List.for_all (fun x-> x) fixptaux in

  (* prune @A's  *)
  let nonA_sum_operands = List.filter (fun x -> not(is_abs_exp x)) sum_operands in
  let fixpt = fixpt && (List.length sum_operands == List.length nonA_sum_operands) in

  (* count the no of non@A constants in the sum  *)
  let constants = List.filter (fun x -> is_const_imm ~emap:emap (exp_to_imm x)) nonA_sum_operands in
  if (List.length constants <= 1) then (Some (mkAdd_list  nonA_sum_operands),fixpt) (* zero or only one non @A constant *)
  else (None, fixpt)

let imm_summation emap e =
  let pr = !print_exp in
  let pr2 b = ite b "exp is unchanged" "exp has changed" in
  Debug.no_2 "imm_summation" EMapSV.string_of pr (pr_pair (pr_opt pr) pr2) imm_summation emap e

let norm_eq_add lhs_sv lhs_l emap e l =
  (* let new_var  = f_e emap (Var(sv,lv)) in *) (* without this we might have false ctx: eg b=@L  & b=@A+@M*)
  let new_var = Var(lhs_sv,lhs_l) in
  let new_sum, fixpt = imm_summation emap e in
  let new_eq rhs = Eq (new_var, rhs, l) in 
  let new_pf = map_opt_def  (BConst (false, l)) (fun x -> new_eq x) new_sum in
  (new_pf, fixpt)

let norm_subann_add mksubann emap e l =
  let new_sum, fixpt = imm_summation emap e in
  let new_pf = map_opt_def  (BConst (false, l)) (fun x -> mksubann x) new_sum in
  (new_pf, fixpt)

(*
   identity element: @A
   exp = @ct1 + @ct2  ----> false for @M <: ct1,ct2 <: @L
   exp = @ct1 + @v    ----> exp = @ct1 + @ct2 if emap of f contains (v,ct2)
   exp = @ct1 + @v    unchanged  if f doesn't contain a constant def for v
*)
let simplify_imm_adddition (f:formula) =
  let fixpt = ref true in

  let f_b_ann_exp_check sv lbl f_op l  =
    if is_ann_typ sv then 
      let new_pf, fixpt0 = f_op l in
      let () = if not(fixpt0) then fixpt:= false in
      Some (new_pf, lbl)
    else None in

  let mk_SubAnn_4Add l lhs rhs =  SubAnn (lhs, rhs, l) in

  let f_b emap fb =
    (* need a helper because of local var emap *)
    let f_b_helper bf =
      let (p_f, lbl) = bf in
      match p_f with
      | Eq (Var(sv,lv), (Add(e1,e2,la) as ea), l) -> 
        let f_eq l = norm_eq_add sv lv emap ea l in
        f_b_ann_exp_check sv lbl f_eq l
      | SubAnn (Var(sv,lv), (Add(e1,e2,la) as ea), l) ->
        let f_subann l = norm_subann_add (mk_SubAnn_4Add la (Var(sv,lv)) ) emap ea l in
        f_b_ann_exp_check sv lbl f_subann l
      | SubAnn ((Add(e1,e2,la) as ea),Var(sv,lv), l) ->
        let f_subann l = norm_subann_add (fun x -> mk_SubAnn_4Add la x (Var(sv,lv)) ) emap ea l in
        f_b_ann_exp_check sv lbl f_subann l
      | _ -> None
    in 
    let fb = transform_b_formula (f_b_helper, somef) fb in
    fb
  in

  let f_b emap fb =
    let pr1 = EMapSV.string_of in
    let pr2 = !print_b_formula in
    Debug.no_2 "f_b_imm_addition" pr1 pr2 pr2 f_b emap fb in
 
  let rec f_f emap f =
    match f with
    | BForm (b1,b2) ->  Some (BForm (f_b emap b1, b2))
    | Or (e1,e2,lbl,l) ->
      let emap1 = EMapSV.merge_eset emap (build_eset_of_imm_formula e1) in
      let e1 = map_formula_arg e1 emap1 (f_f, somef2, somef2) (idf2, idf2, idf2) in
      let emap2 = EMapSV.merge_eset emap (build_eset_of_imm_formula e2) in
      let e2 = map_formula_arg e2 emap2 (f_f, somef2, somef2) (idf2, idf2, idf2) in
      Some (Or (e1,e2,lbl,l))
    | Not (f, lbl, l) ->
      let emap = EMapSV.merge_eset emap (build_eset_of_imm_formula f) in
      let f = map_formula_arg f emap (f_f, somef2, somef2) (idf2, idf2, idf2) in
     Some ( Not (f, lbl, l))
    | _ -> None
  in

  let fncs = (f_f, somef2, somef2) in
  let rec helper form = 
    let () = fixpt := true in
    let emap = build_eset_of_imm_formula form in
    let () =  x_tinfo_hp (add_str "form" !print_formula) form no_pos in
    let () =  x_tinfo_hp (add_str "emap" EMapSV.string_of) emap no_pos in
    let new_form = map_formula_arg form emap fncs (idf2, idf2, idf2) in
    (* let () = fixpt:=(equalFormula form new_form) in *) (* using equalFormula leads to loop *)
    if not(!fixpt) then helper new_form else new_form
  in 
  if !Globals.imm_add  then helper f
  else f

let simplify_imm_addition (f:formula) =
  let pr = !print_formula in
  Debug.no_1 "simplify_imm_addition" pr pr simplify_imm_adddition f

(* ===================== END imm addition utils ========================= *)