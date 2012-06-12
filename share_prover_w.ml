open Genlet no_pos = Globals.no_poslet report_error = Gen.report_errormodule Ts = Tree_shares.Tsmodule CP = Cpure(*module Sv:Share_prover.SV =  struct	type t = CP.spec_var	let cnt = ref 1	let eq = CP.eq_spec_var	(*type t_spec = CP.spec_var		let rconv v = v	let conv v = v	let string_of_s v1 = CP.string_of_spec_var v1	let get_name_s v = CP.string_of_spec_var v	*)    let string_of v1 = CP.string_of_spec_var v1		let rename s a =  match s with CP.SpecVar(t,_,p)-> CP.SpecVar(t,a,p)    let get_name v = CP.string_of_spec_var v		let var_of v = CP.SpecVar(Globals.Tree_sh,v,Globals.Unprimed)    let fresh_var v = cnt:=!cnt+1; rename v ("__ts_fv_"^(string_of_int !cnt))end*)	module Ss_proc_Z3:Share_prover.SAT_SLV = functor (Sv:Share_prover.SV) ->  struct	type t_var = Sv.t	type nz_cons = t_var list list 	type p_var = (*include Gen.EQ_TYPE with type t=v*)		| PVar of t_var 		| C_top	type eq_syst = (t_var*t_var*p_var) list				let mkTop () = C_top	let mkVar v = PVar v	let getVar v = match v with | C_top -> None | PVar v -> Some v			let string_of_eq (v1,v2,v3) = (Sv.string_of v1)^" * "^(Sv.string_of v2)^" = "^(match v3 with | PVar v3 ->  Sv.string_of v3 | _ -> " true")	let string_of_eq_l l = String.concat "\n" (List.map string_of_eq l)		let to_sv v = CP.SpecVar(Globals.Bool,Sv.string_of v,Globals.Unprimed)		let mkBfv v = CP.BForm (CP.BVar (to_sv v,no_pos),None)			let f_of_eqs eqs = List.fold_left (fun a (e1,e2,e3)-> 			let bf1,bf2 = mkBfv e1, mkBfv e2 in			let f_eq =  match e3 with				| PVar v3->					let bf3 = mkBfv v3 in					let f1 = CP.And (bf3, CP.And (bf2, CP.Not (bf1,None,no_pos),no_pos), no_pos) in					let f2 = CP.And (bf3, CP.And (bf1, CP.Not (bf2,None,no_pos),no_pos), no_pos) in					let f3 = CP.Or (CP.Not (bf2,None,no_pos), CP.Not (bf1,None,no_pos), None, no_pos) in					let r = CP.Or (f1,f2,None,no_pos) in					CP.And(r,f3,no_pos)				| C_top -> 					let f1 = CP.And (bf2, CP.Not (bf1,None,no_pos),no_pos) in					let f2 = CP.And (bf1, CP.Not (bf2,None,no_pos),no_pos) in							CP.Or (f1,f2,None,no_pos) in			CP.mkAnd a f_eq no_pos) (CP.mkTrue no_pos) eqs 			let check_nz_sat f_eq f_nz_l = 		let f_tot = List.fold_left (fun a c-> CP.mkAnd a c no_pos) f_eq f_nz_l in		if Smtsolver.is_sat f_tot "0" then true 		else List.for_all (fun c-> Smtsolver.is_sat (CP.mkAnd f_eq c no_pos) "1") f_nz_l			let call_sat non_zeros eqs = 			let f = f_of_eqs eqs in		let f_nz_l = List.map (List.fold_left (fun a c-> CP.mkOr a (mkBfv c) None no_pos) (CP.mkTrue no_pos))  non_zeros in		check_nz_sat f f_nz_l			let call_sat non_zeros eqs = (*		let nzs = String.concat "," (List.map (fun l-> "{"^(String.concat "," (List.map Sv.string_of l))^"}") non_zeros) in		let eqss = string_of_eq_l eqs in		Debug.devel_print ("Z3 SAT: "^nzs^"\n"^eqss^"\n");*)		let r = call_sat non_zeros eqs in(*		Debug.devel_print ("r: "^(string_of_bool r)^"\n");*) r(*t_var list -> nz_cons -> eq_syst -> t_var list -> nz_cons -> eq_syst -> (t_var*bool) list -> (t_var*t_var) list-> bool*)	let call_imply (a_ev:t_var list) a_nz_cons a_l_eqs (c_ev:t_var list) c_nz_cons c_l_eqs c_const_vars c_subst_vars  = 		let ante_eq_f = f_of_eqs a_l_eqs in		let ante_nz_l = List.map (List.fold_left (fun a c-> CP.mkOr a (mkBfv c) None no_pos) (CP.mkTrue no_pos))  a_nz_cons in		if not (check_nz_sat ante_eq_f ante_nz_l) then true		else			let ante_tot = CP.mkExists (List.map to_sv a_ev) (List.fold_left (fun a c-> CP.mkAnd a c no_pos) ante_eq_f ante_nz_l) None no_pos in			let conseq_tot = 				let conseq_eq_f = f_of_eqs c_l_eqs in				let conseq_nz_f = List.fold_left (fun a c->					let r = List.fold_left (fun a c-> CP.mkOr a (mkBfv c) None no_pos) (CP.mkTrue no_pos) c in					CP.And (a,r,no_pos)) conseq_eq_f  c_nz_cons in				let vc_f = List.fold_left (fun a (v,c)-> 					let r = if c then mkBfv v else CP.Not (mkBfv v, None, no_pos) in					CP.And (r,a,no_pos)) conseq_nz_f  c_const_vars in				let ve_f = List.fold_left (fun a (v1,v2)->					let f1 = CP.Or (CP.Not (mkBfv v1, None, no_pos),mkBfv v2, None, no_pos) in					let f2 = CP.Or (CP.Not (mkBfv v2, None, no_pos),mkBfv v1, None, no_pos) in					CP.And (CP.And (f1,f2,no_pos),a,no_pos)) vc_f c_subst_vars in				CP.mkExists (List.map to_sv c_ev) ve_f None no_pos in			(*let _ = Debug.devel_print ("share prover: call_imply ante:  "^ (Cprinter.string_of_pure_formula ante_tot))in			let _ = Debug.devel_print ("share prover: call_imply conseq:  "^ (Cprinter.string_of_pure_formula conseq_tot))in*)			Smtsolver.imply ante_tot conseq_tot 						let call_imply (a_ev:t_var list) a_nz_cons a_l_eqs c_ev c_nz_cons c_l_eqs c_const_vars c_subst_vars  = 			(*let nzsf l = String.concat "," (List.map (fun l-> "{"^(String.concat "," (List.map Sv.string_of l))^"}") l) in			let consl = Gen.Basic.pr_list (Gen.Basic.pr_pair Sv.string_of string_of_bool) c_const_vars in			let cvel = Gen.Basic.pr_list (Gen.Basic.pr_pair Sv.string_of Sv.string_of) c_subst_vars in			let anzs = nzsf a_nz_cons in			let cnzs = nzsf c_nz_cons in			let aeqss = string_of_eq_l a_l_eqs in			let ceqss = string_of_eq_l c_l_eqs in			Debug.devel_print ("Imply ante: "^anzs^";\n"^aeqss^";\n");			Debug.devel_print ("Imply conseq: "^cnzs^";\n"^cvel^";\n"^consl^";\n"^ceqss^";\n")s;*)			let r = call_imply a_ev a_nz_cons a_l_eqs c_ev c_nz_cons c_l_eqs c_const_vars c_subst_vars in			(*Debug.devel_print ("r: "^(string_of_bool r));*) rend;;	(************************************************************************************)	module Ss_minisat_proc:Share_prover.SAT_SLV = functor (Sv:Share_prover.SV) ->  struct	type t_var = Sv.t	type nz_cons = t_var list list 	type p_var = (*include Gen.EQ_TYPE with type t=v*)		| PVar of t_var 		| C_top	type eq_syst = (t_var*t_var*p_var) list		let mkTop () = C_top	let mkVar v = PVar v	let getVar v = match v with | C_top -> None | PVar v -> Some v					let string_of_eq (v1,v2,v3) = (Sv.string_of v1)^" * "^(Sv.string_of v2)^" = "^(match v3 with | PVar v3 ->  Sv.string_of v3 | _ -> " true")	let string_of_eq_l l = String.concat "\n" (List.map string_of_eq l)				(**********minisat interface **********)																(* Global settings *)						let minisat_timeout_limit = 15.0						let test_number = ref 0						let last_test_number = ref 0						let minisat_restart_interval = ref (-1)						let log_all_flag = ref false						let is_minisat_running = ref false						let in_timeout = ref 15.0 (* default timeout is 15 seconds *)						let minisat_call_count: int ref = ref 0						let log_file = open_out ("allinput.minisat")						let minisat_input_mode = "file"    (* valid value is: "file" or "stdin" *) 						(*minisat*)						let minisat_path = "/usr/local/bin/minisat"						let minisat_name = "minisat"						let minisat_arg = "-pre"						let minisat_input_format = "cnf"   (* valid value is: cnf *)						let number_clauses = ref 1						let number_var = ref 0						let minisat_process = ref {    Globals.name = "minisat";													   Globals.pid = 0;													   Globals.inchannel = stdin;													   Globals.outchannel = stdout;													   Globals.errchannel = stdin 												  }(***************************************************************INTERACTION**************************************************************)						let rec collect_output (chn: in_channel)  : (string * bool) =						  try							let line = input_line chn in							if line = "SATISFIABLE" then							  (line, true)							else							  collect_output chn 						  with 						  | End_of_file ->  ("", false)						  						let get_prover_result (output : string) :bool =						  let validity =							if (output="SATISFIABLE") then							  true							else							  false in 						  validity							(* output:  - prover_output 									- the running status of prover: true if running, otherwise false *)						let get_answer (chn: in_channel) : (bool * bool)=						  let (output, running_state) = collect_output chn  in						  let							validity_result = get_prover_result output;						   in						  (validity_result, running_state)  							let remove_file filename =						  try Sys.remove filename;						  with e -> ignore e							let set_process proc =								minisat_process := proc							let start () =						  if not !is_minisat_running then (							print_endline ("Starting Minisat... \n");							last_test_number := !test_number;							if (minisat_input_format = "cnf") then (							  Procutils.PrvComms.start false stdout (minisat_name, minisat_path, [|minisat_arg|]) set_process (fun () -> ());							  is_minisat_running := true;							)						  )							(* stop minisat system *)						let stop () =						  if !is_minisat_running then (							let num_tasks = !test_number - !last_test_number in							print_string ("\nStop Minisat... " ^ (string_of_int !minisat_call_count) ^ " invocations "); flush stdout;							Procutils.PrvComms.stop false stdout !minisat_process num_tasks Sys.sigkill (fun ()->());							is_minisat_running := false;						  )							(* restart Omega system *)						let restart reason =						  if !is_minisat_running then (							let _ = print_string (reason ^ " Restarting minisat after ... " ^ (string_of_int !minisat_call_count) ^ " invocations ") in							Procutils.PrvComms.restart false stdout reason "minisat" start stop						  )						  else (							let _ = print_string (reason ^ " not restarting minisat ... " ^ (string_of_int !minisat_call_count) ^ " invocations ") in ()						  )													(* Runs the specified prover and returns output *)						let check_problem_through_file (input: string) (timeout: float) : bool =						  (* debug *)						  (* let _ = print_endline "** In function minisat.check_problem" in *)						  let file_suffix = Random.int 1000000 in						  let infile = "/tmp/in" ^ (string_of_int file_suffix) ^ ".cnf" in						  (*let _ = print_endline ("-- input: \n" ^ input) in*) 						  let out_stream = open_out infile in						  output_string out_stream input;						  close_out out_stream;						  let minisat_result="minisatres.txt" in						  let set_process proc = minisat_process := proc in						  let fnc () =							if (minisat_input_format = "cnf") then (							  Procutils.PrvComms.start false stdout (minisat_name, minisat_path, [|minisat_arg;infile;minisat_result|]) set_process (fun ()->());							  minisat_call_count := !minisat_call_count + 1;							  let (prover_output, running_state) = get_answer !minisat_process.Globals.inchannel in							  is_minisat_running := running_state;							  prover_output;							)							else failwith "[minisat.ml] The value of minisat_input_format is invalid!" in						  let res =							try							  let fail_with_timeout () = restart ("[minisat]Timeout when checking sat!" ^ (string_of_float timeout)); false in							  let res = Procutils.PrvComms.maybe_raise_and_catch_timeout fnc () timeout fail_with_timeout in							  res							with _ -> ((* exception : return the safe result to ensure soundness *)							  Printexc.print_backtrace stdout;							  print_endline ("WARNING: Restarting prover due to timeout");							  Unix.kill !minisat_process.Globals.pid 9;							  ignore (Unix.waitpid [] !minisat_process.Globals.pid);							  false							) in						  let _ = Procutils.PrvComms.stop false stdout !minisat_process 0 9 (fun () -> ()) in						  remove_file infile;						  res								  (**************************************************************MAIN INTERFACE : CHECKING IMPLICATION AND SATISFIABILITY*************************************************************)				(*******************zzzzzzzzzzzzzz****************)							(*generate the CNF *)			let cnf_to_string var_cnt f : string =				let fct l = String.concat " " (List.map (fun (c,b)-> if b then string_of_int c else ("-"^(string_of_int c))) l) in				"p cnf "^(string_of_int var_cnt)^" "^ (string_of_int (List.length f))^"\n"^				(String.concat " 0\n" (List.map fct f))^" 0\n" 									let xor sv1 sv2 sv3 = [ [(sv1, false);(sv2,false)];				(*~v1 | ~v2      *)										  [(sv1,true);(sv2,true);(sv3,false)]; 	    (* v1 | v2 | ~v3 *)										  [(sv1,false);(sv2,true);(sv3,true)]; 	    (* ~v1| v2 | v3  *)										  [(sv1,true);(sv2,false);(sv3,true)]] 	 	(* v1 | ~v2| v3  *) 										  			let xorc sv1 sv2 = [[(sv1, true);(sv2,true)];[(sv1, false);(sv2,false)]] 						let trans_vv sv1 sv2 = [[(sv1, true);(sv2,false)];[(sv1, false);(sv2,true)]] 						let negVar v f = List.map (List.map (fun (c,b)-> if c=v then c,not b else c,b)) f 						let rec tauto l = match l with 				| [] -> false				| (c,b)::t-> (List.exists (fun (v,b1)-> c=v && b<>b1) t) || (tauto t) 						let neg_f f = 				let f = List.map (List.map (fun (c,b)-> c,not b)) f in				if f=[] then f				else List.fold_left (fun a c-> 					  let r = List.concat (List.map (fun c-> List.map (fun d-> c::d) a) c) in					  List.filter (fun c->not (tauto c)) r) (List.map (fun c-> [c]) (List.hd f)) (List.tl f)										let mkOr f1 f2 = 				let l = List.map (fun l -> List.map (fun l2 -> l@l2) f2) f1 in				List.filter (fun c-> not (tauto c)) (List.concat l)						let mkExists vl f = 				let fv = List.fold_left (fun a c-> a@ (List.map fst c)) [] f in				let vl = List.filter (fun c-> List.mem c fv) vl in				List.fold_left (fun f v-> mkOr f (negVar v f)) f vl 															let call_imply (a_ev:t_var list) (a_nz_cons:nz_cons) (a_l_eqs:eq_syst) (c_ev:t_var list) (c_nz_cons:nz_cons) (c_l_eqs:eq_syst) (c_const_vars:(t_var*bool) list) (c_subst_vars:(t_var*t_var) list):bool  =  				let ht = Hashtbl.create 20 in				let tp = ref 0 in				let get_var v = let v = Sv.string_of v in try Hashtbl.find ht v  with | Not_found -> (tp:= !tp+1; Hashtbl.add ht v !tp;!tp) in				let trans_eq (v1,v2,c) = match c with 									| C_top -> xorc (get_var v1) (get_var v2)									| PVar v3-> xor (get_var v1) (get_var v2) (get_var v3) in								let ante_f = 						let nz = List.map (List.map (fun c-> get_var c, true)) a_nz_cons in   (*conj of disj*)						let eqs = List.map trans_eq a_l_eqs in						let a_ev = List.map get_var a_ev in						mkExists a_ev (List.concat (nz::eqs)) in											let conseq_f = 						let c_ev = List.map get_var c_ev in						let nz = List.map (List.map (fun c-> get_var c, true)) c_nz_cons in   (*conj of disj*)						let eqs = List.map trans_eq  c_l_eqs in						let c_subst = List.map (fun (v1,v2) -> trans_vv (get_var v1)(get_var v2)) c_subst_vars in						let c_const = List.map (fun (v,b) -> [[(get_var v, b)]]) c_const_vars in						let r = List.concat (nz::eqs@c_subst@c_const) in						let r = List.map (List.filter (fun (c,_)-> not (List.mem c c_ev))) (neg_f r) in						List.filter (fun c-> c<>[]) r in				let all_f = ante_f@conseq_f in					if all_f<>[] then						( if !Globals.perm_prof then Gen.Profiling.inc_counter ("p_m_i") else () ;						not (check_problem_through_file (cnf_to_string !tp (ante_f@conseq_f)) 0.))					else true				            				let call_imply  (a_ev:t_var list) (a_nz_cons:nz_cons) (a_l_eqs:eq_syst) 								(c_ev:t_var list) (c_nz_cons:nz_cons) (c_l_eqs:eq_syst) (c_const_vars:(t_var*bool) list) (c_subst_vars:(t_var*t_var) list):bool  =  								(*let nzsf l = String.concat "," (List.map (fun l-> "{"^(String.concat "," (List.map Sv.string_of l))^"}") l) in					let consl = Gen.Basic.pr_list (Gen.Basic.pr_pair Sv.string_of string_of_bool) c_const_vars in					let cvel = Gen.Basic.pr_list (Gen.Basic.pr_pair Sv.string_of Sv.string_of) c_subst_vars in					let anzs = nzsf a_nz_cons in					let cnzs = nzsf c_nz_cons in					let aeqss = string_of_eq_l a_l_eqs in					let ceqss = string_of_eq_l c_l_eqs in				    print_string ("Imply ante: "^anzs^";\n"^aeqss^";\n");					print_string ("Imply conseq: "^cnzs^";\n"^cvel^";\n"^consl^";\n"^ceqss^";\n");*)					let r = call_imply a_ev a_nz_cons a_l_eqs c_ev c_nz_cons c_l_eqs c_const_vars c_subst_vars in				    (*print_string ("r: "^(string_of_bool r));*) r													let call_sat non_zeros eqs = 					let ht = Hashtbl.create 20 in					let tp = ref 0 in					let get_var v = let v = Sv.string_of v in try Hashtbl.find ht v  with | Not_found -> 						(tp:= !tp+1; 							(*print_string (v^" "^(string_of_int !tp)^"\n");*)						Hashtbl.add ht v !tp;!tp) in					let input = 							let nz = List.map (List.map (fun c-> get_var c, true)) non_zeros in   (*conj of disj*)							let eqs = List.map ( fun (v1,v2,c)-> 								let sv1 = get_var v1 in								let sv2 = get_var v2 in								match c with 									| C_top -> xorc sv1 sv2 									| PVar v3-> xor sv1 sv2 (get_var v3) ) eqs in							List.concat (nz::eqs) in					if input<> [] then 						let input_str = cnf_to_string !tp input in						((*print_string (input_str^"\n");*)						if !Globals.perm_prof then Gen.Profiling.inc_counter ("p_m_s") else () ;						check_problem_through_file input_str minisat_timeout_limit)					else true 											let call_sat non_zeros eqs = 				(*let nzs = String.concat "," (List.map (fun l-> "{"^(String.concat "," (List.map Sv.string_of l))^"}") non_zeros) in				let eqss = string_of_eq_l eqs in				print_string ("MINISAT SAT: "^nzs^"\n"^eqss^"\n");*)				let r = call_sat non_zeros eqs in				(*print_string ("r: "^(string_of_bool r)^"\n");*) r	end;;(*module SSV = Share_prover.Sv*)module Solver_byt = Share_prover.Dfrac_s_solver(Ts)(Share_prover.Sv)(Ss_proc_Z3)module Solver_minisat = Share_prover.Dfrac_s_solver(Ts)(Share_prover.Sv)(Ss_minisat_proc)(*to switch to z3 as library change solver from solver_byt to Solver_nat*)(*module Solver_nat = Shares_z3_lib.Solver*)module Solver= Solver_minisatlet tr_var v= CP.string_of_spec_var vlet sv_eq = Share_prover.Sv.eq let mkVperm v = Solver.Vperm (tr_var v)let mkCperm t = Solver.Cperm t