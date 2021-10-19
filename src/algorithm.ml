(*
 * This file is part of MONPOLY.
 *
 * Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
 * Contact:  Nokia Corporation (Debmalya Biswas: debmalya.biswas@nokia.com)
 *
 * Copyright (C) 2012, 2021 ETH Zurich.
 * Contact:  ETH Zurich (Eugen Zalinescu: eugen.zalinescu@inf.ethz.ch)
 *
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation, version 2.1 of the
 * License.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see
 * http://www.gnu.org/licenses/lgpl-2.1.html.
 *
 * As a special exception to the GNU Lesser General Public License,
 * you may link, statically or dynamically, a "work that uses the
 * Library" with a publicly distributed version of the Library to
 * produce an executable file containing portions of the Library, and
 * distribute that executable file under terms of your choice, without
 * any of the additional requirements listed in clause 6 of the GNU
 * Lesser General Public License. By "a publicly distributed version
 * of the Library", we mean either the unmodified Library as
 * distributed by Nokia, or a modified version of the Library that is
 * distributed under the conditions defined in clause 3 of the GNU
 * Lesser General Public License. This exception does not however
 * invalidate any other reasons why the executable file might be
 * covered by the GNU Lesser General Public License.
 *)



(** This module implements the monitoring algorithm. This algorithm is
    described in the paper "Runtime Monitoring of Metric First-order
    Temporal Properties" by David Basin, Felix Klaedtke, Samuel
    Muller, and Birgit Pfitzmann, presented at FSTTCS'08.


    This is the MONPOLY's main module, all other modules can be seen
    as "helper" modules. The module's entry point is normally the
    [monitor] function. This function checks that the given formula is
    monitorable and then calls the [check_log] function which
    iteratively reads each log entry. To be able to incrementally
    process the entries, the input formula is first extended with
    additional information for each subformula, by calling the
    [add_ext] function.  Also, a queue [neval] of not-yet evaluated
    indexes of log entries is maintained.

    The function [check_log] reads each log entry, calls [add_index]
    to update the extended formula with the new information from the
    entry at index [i], adds index [i] to the queue of not-yet
    evaluated indexes, and finally calls [process_index] to process
    this entry.

    The function [process_index] iterativelly tries to evaluate the
    formula at each index (calling the function [eval]) from the queue
    of not-yet evaluated indexes. It stops when the formula cannot be
    evaluated or when the formula has been evaluated at all indexes in
    the queue. The function [eval] performs a bottom-up evaluation of
    the formula.
*)


open Misc
open Predicate
open MFOTL
open Relation
open Sliding

module Sk = Dllist
module Sj = Dllist


(* For the sake of clarity, think about merging these types and all
   related functions. Some fields will be redundant, but we will not lose
   that much. *)

type info = (int * timestamp * relation) Queue.t
type ainfo = {mutable arel: relation option}
type pinfo = {mutable plast: Neval.cell}
type ninfo = {mutable init: bool}
type oainfo = {mutable ores: relation;
         oaauxrels: (timestamp * relation) Mqueue.t}

type agg_info = {agg_op: agg_op; agg_default: cst option}

type ozinfo = {mutable oztree: (int, relation) Sliding.stree;
               mutable ozlast: (int * timestamp * relation) Dllist.cell;
               ozauxrels: (int * timestamp * relation) Dllist.dllist}
type oinfo = {mutable otree: (timestamp, relation) Sliding.stree;
              mutable olast: (timestamp * relation) Dllist.cell;
              oauxrels: (timestamp * relation) Dllist.dllist}
type sainfo = {mutable sres: relation;
               mutable sarel2: relation option;
               saauxrels: (timestamp * relation) Mqueue.t}
type sinfo = {mutable srel2: relation option;
              sauxrels: (timestamp * relation) Mqueue.t}
type ezinfo = {mutable ezlastev: Neval.cell;
               mutable eztree: (int, relation) Sliding.stree;
               mutable ezlast: (int * timestamp * relation) Dllist.cell;
               ezauxrels: (int * timestamp * relation) Dllist.dllist}
type einfo = {mutable elastev: Neval.cell;
              mutable etree: (timestamp, relation) Sliding.stree;
              mutable elast: (timestamp * relation) Dllist.cell;
              eauxrels: (timestamp * relation) Dllist.dllist}
type uinfo = {mutable ulast: Neval.cell;
              mutable ufirst: bool;
              mutable ures: relation;
              mutable urel2: relation option;
              raux: (int * timestamp * (int * relation) Sk.dllist) Sj.dllist;
              mutable saux: (int * relation) Sk.dllist}
type uninfo = {mutable last1: Neval.cell;
               mutable last2: Neval.cell;
               mutable listrel1: (int * timestamp * relation) Dllist.dllist;
               mutable listrel2: (int * timestamp * relation) Dllist.dllist}

type comp_one = relation -> relation
type comp_two = relation -> relation -> relation

type extformula =
  | ERel of relation
  | EPred of predicate * comp_one * info
  | ENeg of extformula
  | EAnd of comp_two * extformula * extformula * ainfo
  | EOr of comp_two * extformula * extformula * ainfo
  | EExists of comp_one * extformula
  | EAggreg of agg_info * Aggreg.aggregator * extformula
  | EAggOnce of agg_info * Aggreg.window_aggregator * extformula
  | EPrev of interval * extformula * pinfo
  | ENext of interval * extformula * ninfo
  | ESinceA of comp_two * interval * extformula * extformula * sainfo
  | ESince of comp_two * interval * extformula * extformula * sinfo
  | EOnceA of interval * extformula * oainfo
  | EOnceZ of interval * extformula * ozinfo
  | EOnce of interval * extformula * oinfo
  | ENUntil of comp_two * interval * extformula * extformula * uninfo
  | EUntil of comp_two * interval * extformula * extformula * uinfo
  | EEventuallyZ of interval * extformula * ezinfo
  | EEventually of interval * extformula * einfo


let crt_ts = ref MFOTL.ts_invalid
let crt_tp = ref (-1)


let print_bool b =
  if b then
    print_string "true"
  else
    print_string "false"


let print_ainf str ainf =
  print_string str;
  match ainf with
  | None -> print_string "None"
  | Some rel -> Relation.print_rel "" rel

let print_auxel =
  (fun (k,rel) ->
     Printf.printf "(%d->" k;
     Relation.print_rel "" rel;
     print_string ")"
  )
let print_sauxel =
  (fun (tsq,rel) ->
     Printf.printf "(%s," (MFOTL.string_of_ts tsq);
     Relation.print_rel "" rel;
     print_string ")"
  )

let print_rauxel (j,tsj,rrelsj) =
  Printf.printf "(j=%d,tsj=" j;
  MFOTL.print_ts tsj;
  print_string ",r=";
  Misc.print_dllist print_auxel rrelsj;
  print_string "),"


let print_aauxel (q,tsq,rel) =
  Printf.printf "(%d,%s," q (MFOTL.string_of_ts tsq);
  Relation.print_rel "" rel;
  print_string ")"

let print_inf inf =
  Misc.print_queue print_aauxel inf

let print_predinf str inf =
  print_string str;
  print_inf inf;
  print_newline()

let print_ozinf str inf =
  print_string str;
  if inf.ozlast == Dllist.void then
    print_string "ozlast = None; "
  else
    begin
      let (j,_,_) = Dllist.get_data inf.ozlast in
      Printf.printf "ozlast (index) = %d; " j
    end;
  Misc.print_dllist print_aauxel inf.ozauxrels;
  Sliding.print_stree
    string_of_int
    (Relation.print_rel " ztree = ")
    "; ozinf.ztree = "
    inf.oztree

let print_oinf str inf =
  print_string (str ^ "{");
  if inf.olast == Dllist.void then
    print_string "last = None; "
  else
    begin
      let (ts,_) = Dllist.get_data inf.olast in
      Printf.printf "last (ts) = %s; " (MFOTL.string_of_ts ts)
    end;
  print_string "oauxrels = ";
  Misc.print_dllist print_sauxel inf.oauxrels;
  Sliding.print_stree MFOTL.string_of_ts (Relation.print_rel "") ";\n oinf.tree = " inf.otree;
  print_string "}"


let print_sainf str inf =
  print_string str;
  print_ainf "{srel2 = " inf.sarel2;
  Relation.print_rel "; sres=" inf.sres;
  print_string "; sauxrels=";
  Misc.print_mqueue print_sauxel inf.saauxrels;
  print_string "}"

let print_sinf str inf =
  print_string str;
  print_ainf "{srel2=" inf.srel2  ;
  print_string ", sauxrels=";
  Misc.print_mqueue print_sauxel inf.sauxrels;
  print_string "}"


let print_uinf str inf =
  Printf.printf "%s{first=%b; last=%s; " str inf.ufirst
    (Neval.string_of_cell inf.ulast);
  Relation.print_rel "res=" inf.ures;
  print_string "; raux=";
  Misc.print_dllist print_rauxel inf.raux;
  print_string "; saux=";
  Misc.print_dllist print_auxel inf.saux;
  print_endline "}"

let print_uninf str uninf =
  Printf.printf "%s{last1=%s; last2=%s; " str
    (Neval.string_of_cell uninf.last1) (Neval.string_of_cell uninf.last2);
  print_string "listrel1=";
  Misc.print_dllist print_aauxel uninf.listrel1;
  print_string "; listrel2=";
  Misc.print_dllist print_aauxel uninf.listrel2;
  print_string "}\n"

let print_ezinf str inf =
  Printf.printf "%s{ezlastev = %s; " str (Neval.string_of_cell inf.ezlastev);
  if inf.ezlast == Dllist.void then
    print_string "ezlast = None; "
  else
    begin
      let (_,ts,_) = Dllist.get_data inf.ezlast in
      Printf.printf "elast (ts) = %s; " (MFOTL.string_of_ts ts)
    end;
  print_string "eauxrels=";
  Misc.print_dllist print_aauxel inf.ezauxrels;
  Sliding.print_stree string_of_int (Relation.print_rel "") "; ezinf.eztree = " inf.eztree;
  print_string "}\n"


let print_einf str inf =
  Printf.printf "%s{elastev = %s; " str (Neval.string_of_cell inf.elastev);
  if inf.elast == Dllist.void then
    print_string "elast = None; "
  else
    begin
      let ts = fst (Dllist.get_data inf.elast) in
      Printf.printf "elast (ts) = %s; " (MFOTL.string_of_ts ts)
    end;
  print_string "eauxrels=";
  Misc.print_dllist print_sauxel inf.eauxrels;
  Sliding.print_stree MFOTL.string_of_ts (Relation.print_rel "") "; einf.etree = " inf.etree;
  print_string "}"

let print_einfn str inf =
  print_einf str inf;
  print_newline()


let print_extf str ff =
  let print_spaces d =
    for _i = 1 to d do print_string " " done
  in
  let rec print_f_rec d f =
    print_spaces d;
    (match f with
     | ERel _ ->
       print_string "ERel\n";

     | EPred (p,_,inf) ->
       Predicate.print_predicate p;
       print_string ": inf=";
       print_inf inf;
       print_string "\n"

     | _ ->
       (match f with
        | ENeg f ->
          print_string "NOT\n";
          print_f_rec (d+1) f;

        | EExists (_,f) ->
          print_string "EXISTS\n";
          print_f_rec (d+1) f;

        | EPrev (intv,f,pinf) ->
          print_string "PREVIOUS";
          MFOTL.print_interval intv;
          print_string ": plast=";
          print_string (Neval.string_of_cell pinf.plast);
          print_string "\n";
          print_f_rec (d+1) f

        | ENext (intv,f,ninf) ->
          print_string "NEXT";
          MFOTL.print_interval intv;
          print_string ": init=";
          print_bool ninf.init;
          print_string "\n";
          print_f_rec (d+1) f

        | EOnceA (intv,f,inf) ->
          print_string "ONCE";
          MFOTL.print_interval intv;
          Relation.print_rel ": rel = " inf.ores;
          print_string "; oaauxrels = ";
          Misc.print_mqueue print_sauxel inf.oaauxrels;
          print_string "\n";
          print_f_rec (d+1) f

        | EOnceZ (intv,f,oinf) ->
          print_string "ONCE";
          MFOTL.print_interval intv;
          print_ozinf ": ozinf=" oinf;
          print_f_rec (d+1) f

        | EOnce (intv,f,oinf) ->
          print_string "ONCE";
          MFOTL.print_interval intv;
          print_oinf ": oinf = " oinf;
          print_string "\n";
          print_f_rec (d+1) f

        | EEventuallyZ (intv,f,einf) ->
          print_string "EVENTUALLY";
          MFOTL.print_interval intv;
          print_ezinf ": ezinf=" einf;
          print_f_rec (d+1) f

        | EEventually (intv,f,einf) ->
          print_string "EVENTUALLY";
          MFOTL.print_interval intv;
          print_einf ": einf=" einf;
          print_string "\n";
          print_f_rec (d+1) f

        | _ ->
          (match f with
           | EAnd (_,f1,f2,ainf) ->
             print_ainf "AND: ainf=" ainf.arel;
             print_string "\n";
             print_f_rec (d+1) f1;
             print_f_rec (d+1) f2

           | EOr (_,f1,f2,ainf) ->
             print_ainf "OR: ainf=" ainf.arel;
             print_string "\n";
             print_f_rec (d+1) f1;
             print_f_rec (d+1) f2

           | ESinceA (_,intv,f1,f2,sinf) ->
             print_string "SINCE";
             MFOTL.print_interval intv;
             print_sainf ": sinf = " sinf;
             print_string "\n";
             print_f_rec (d+1) f1;
             print_f_rec (d+1) f2

           | ESince (_,intv,f1,f2,sinf) ->
             print_string "SINCE";
             MFOTL.print_interval intv;
             print_sinf ": sinf=" sinf;
             print_string "\n";
             print_f_rec (d+1) f1;
             print_f_rec (d+1) f2

           | EUntil (_,intv,f1,f2,uinf) ->
             print_string "UNTIL";
             MFOTL.print_interval intv;
             print_uinf ": uinf=" uinf;
             print_f_rec (d+1) f1;
             print_f_rec (d+1) f2

           | ENUntil (_,intv,f1,f2,uninf) ->
             print_string "NUNTIL";
             MFOTL.print_interval intv;
             print_uninf ": uninf=" uninf;
             print_f_rec (d+1) f1;
             print_f_rec (d+1) f2

           | _ -> failwith "[print_formula] internal error"
          );
       );
    );
  in
  print_string str;
  print_f_rec 0 ff








let mqueue_add_last auxrels tsq rel2 =
  if Mqueue.is_empty auxrels then
    Mqueue.add (tsq,rel2) auxrels
  else
    let tslast, rellast =  Mqueue.get_last auxrels in
    if tslast = tsq then
      Mqueue.update_last (tsq, Relation.union rellast rel2) auxrels
    else
      Mqueue.add (tsq,rel2) auxrels

let dllist_add_last auxrels tsq rel2 =
  if Dllist.is_empty auxrels then
    Dllist.add_last (tsq,rel2) auxrels
  else
    let tslast, rellast = Dllist.get_last auxrels in
    if tslast = tsq then
      let _ = Dllist.pop_last auxrels in
      Dllist.add_last (tsq, Relation.union rellast rel2) auxrels
    else
      Dllist.add_last (tsq,rel2) auxrels





(* [saauxrels] consists of those relations that are outside of the
   relevant time window *)
let update_since_all intv tsq inf comp rel1 rel2 =
  inf.sres <- comp inf.sres rel1;
  let auxrels = inf.saauxrels in
  let rec elim () =
    if not (Mqueue.is_empty auxrels) then
      let (tsj,relj) = Mqueue.top auxrels in
      if MFOTL.in_right_ext (MFOTL.ts_minus tsq tsj) intv then
        begin
          ignore (Mqueue.pop auxrels);
          inf.sres <- Relation.union inf.sres (comp relj rel1);
          elim ()
        end
  in
  elim ();

  Mqueue.update_and_delete
    (fun (tsj, relj) -> (tsj, comp relj rel1))
    (fun (_,relj) -> Relation.is_empty relj) (* delete the current node if newrel is empty *)
    auxrels;

  if not (Relation.is_empty rel2) then
    begin
      if MFOTL.in_right_ext MFOTL.ts_null intv then
        inf.sres <- Relation.union inf.sres rel2;
      mqueue_add_last auxrels tsq rel2
    end;

  inf.sres



let update_since intv tsq auxrels comp discard rel1 rel2 =
  let rec elim_old_auxrels () =
    (* remove old elements that felt out of the interval *)
    if not (Mqueue.is_empty auxrels) then
      let (tsj,_relj) = Mqueue.top auxrels in
      if not (MFOTL.in_left_ext (MFOTL.ts_minus tsq tsj) intv) then
        begin
          ignore(Mqueue.pop auxrels);
          elim_old_auxrels()
        end
  in
  elim_old_auxrels ();

  let res = ref Relation.empty in
  Mqueue.update_and_delete
    (fun (tsj,relj) ->
       let newrel = comp relj rel1 in
       if (not discard) && MFOTL.in_right_ext (MFOTL.ts_minus tsq tsj) intv then
         res := Relation.union !res newrel;
       (tsj,newrel)
    )
    (* delete the current node if newrel is empty *)
    (fun (_,relj) -> Relation.is_empty relj)
    auxrels;

  if not (Relation.is_empty rel2) then
    begin
      if (not discard) && MFOTL.in_right_ext MFOTL.ts_null intv then
        res := Relation.union !res rel2;
      mqueue_add_last auxrels tsq rel2
    end;

  !res


let update_once_all intv tsq inf =
  let auxrels = inf.oaauxrels in
  let rec comp () =
    if not (Mqueue.is_empty auxrels) then
      let (tsj,relj) = Mqueue.top auxrels in
      if MFOTL.in_right_ext (MFOTL.ts_minus tsq tsj) intv then
        begin
          ignore (Mqueue.pop auxrels);
          inf.ores <- Relation.union inf.ores relj;
          comp ()
        end
  in
  comp ()




(* It returns the list consisting of the new elements in the new time
   window with respect to the old time window. It is used by once and
   eventually evaluation functions.

   Arguments:
   - [l] the (doubly-linked) list of old elements
   - [last] a pointer to the element of the list from which the
   processing starts
   - [cond] stopping condition
   - [f] a function to be applied on each element
*)
let get_new_elements l last cond f =
  let rec get crt new_last acc =
    let v = Dllist.get_data crt in
    if cond v then
      if Dllist.is_last l crt then
        (f v) :: acc, crt
      else
        get (Dllist.get_next l crt) crt ((f v) :: acc)
    else
      acc, new_last
  in
  if last == Dllist.void then
    get (Dllist.get_first_cell l) Dllist.void []
  else if not (Dllist.is_last l last) then
    get (Dllist.get_next l last) last []
  else
    [], last


(* Remark: we could remove all auxrels that are covered by the tree and
   gain some memory (sooner). However detecting [lw] would be harder. *)
let update_once_zero intv q tsq inf rel2 discard =
  let auxrels = inf.ozauxrels in

  let rec elim_old_ozauxrels () =
    (* remove old elements that fell out of the interval *)
    if not (Dllist.is_empty auxrels) then
      let (_, tsj, _arel) = Dllist.get_first auxrels in
      if not (MFOTL.in_left_ext (MFOTL.ts_minus tsq tsj) intv) then
        begin
          if inf.ozlast != Dllist.void && inf.ozlast == Dllist.get_first_cell auxrels then
            inf.ozlast <- Dllist.void;
          ignore(Dllist.pop_first auxrels);
          elim_old_ozauxrels()
        end
  in
  elim_old_ozauxrels ();

  if not (Relation.is_empty rel2) then
    Dllist.add_last (q,tsq,rel2) inf.ozauxrels;

  if Dllist.is_empty auxrels || discard then
    Relation.empty
  else
    let cond = fun _ -> true in
    let f = fun (j,_,rel) -> (j,rel) in
    let subseq, new_last = get_new_elements auxrels inf.ozlast cond f in
    let lw,_,_ = Dllist.get_first auxrels in
    let rw =
      if subseq = [] then
        let j,_,_ = Dllist.get_data inf.ozlast in j
      else
        begin
          assert (new_last != Dllist.void);
          inf.ozlast <- new_last;
          let rw = fst (List.hd subseq) in
          assert (rw = let j,_,_ = Dllist.get_data new_last in j);
          rw
        end
    in
    if Misc.debugging Dbg_eval then
      begin
        Printf.printf "[update_once_zero] lw = %d rw = %d " lw rw;
        Misc.printnl_list "subseq = " print_auxel subseq;
      end;
    let newt = Sliding.slide string_of_int Relation.union subseq (lw, rw) inf.oztree in
    inf.oztree <- newt;
    Sliding.stree_res newt


let update_once intv tsq inf discard =
  let auxrels = inf.oauxrels in
  let rec elim_old_oauxrels () =
    (* remove old elements that fell out of the interval *)
    if not (Dllist.is_empty auxrels) then
      let (tsj,_) = Dllist.get_first auxrels in
      if not (MFOTL.in_left_ext (MFOTL.ts_minus tsq tsj) intv) then
        begin
          if inf.olast != Dllist.void && inf.olast == Dllist.get_first_cell auxrels then
            inf.olast <- Dllist.void;
          ignore(Dllist.pop_first auxrels);
          elim_old_oauxrels()
        end
  in
  elim_old_oauxrels ();

  (* In the following we distiguish between the new window and the new
     elements: the new window may contain old elements (the old and new
     windows may overlap). *)

  if Dllist.is_empty auxrels || discard then
    Relation.empty
  else
    let lw = fst (Dllist.get_first auxrels) in
    if MFOTL.in_right_ext (MFOTL.ts_minus tsq lw) intv then
      (* the new window is not empty *)
      let cond = fun (tsj,_) -> MFOTL.in_right_ext (MFOTL.ts_minus tsq tsj) intv in
      let subseq, new_last = get_new_elements auxrels inf.olast cond (fun x -> x) in
      let rw =
        if subseq = [] then
          fst (Dllist.get_data inf.olast)
        else
          begin
            assert (new_last != Dllist.void);
            inf.olast <- new_last;
            let rw = fst (List.hd subseq) in
            assert (rw = fst (Dllist.get_data new_last));
            rw
          end
      in
      if Misc.debugging Dbg_eval then
        begin
          Printf.printf "[update_once] lw = %s rw = %s "
            (MFOTL.string_of_ts lw)
            (MFOTL.string_of_ts rw);
          Misc.printnl_list "subseq = " print_sauxel subseq;
        end;
      let newt = Sliding.slide MFOTL.string_of_ts Relation.union subseq (lw, rw) inf.otree in
      inf.otree <- newt;
      Sliding.stree_res newt
    else
      begin
        (* the new window is empty,
           because not even the oldest element satisfies the constraint *)
        inf.otree <- LNode {l = MFOTL.ts_invalid;
                            r = MFOTL.ts_invalid;
                            res = Some (Relation.empty)};
        inf.olast <- Dllist.void;
        Relation.empty
      end





let update_old_until q tsq i intv inf discard  =
  (* eliminate those entries (q-1,reli) from rels;
     return the tuples which hold at q *)
  let elim_old j rels =
    assert(j>=q-1);
    if not (Sk.is_empty rels) then
      let (k,relk) = Sk.get_first rels in
      if k=q-1 then
        begin
          ignore(Sk.pop_first rels);
          if not (Sk.is_empty rels) && fst (Sk.get_first rels) = q then
            let (k',relk') = Sk.pop_first rels in
            assert(k'=q && j>=q);
            let newrelk' = Relation.union relk relk' in
            Sk.add_first (k',newrelk') rels;
            newrelk'
          else
          if (j>q-1) then
            begin
              Sk.add_first (k+1,relk) rels;
              relk
            end
          else
            Relation.empty
        end
      else
        begin
          assert(k>q-1);
          if k=q then
            relk
          else
            Relation.empty
        end
    else (* Sk.is_empty rels = true *)
      Relation.empty
  in


  let rec elim_old_raux () =
    (* remove old elements that fell out of the interval *)
    if not (Sj.is_empty inf.raux) then
      let (j,tsj,_) = Sj.get_first inf.raux in
      if j<q || not (MFOTL.in_right_ext (MFOTL.ts_minus tsj tsq) intv) then
        begin
          ignore(Sj.pop_first inf.raux);
          elim_old_raux()
        end
  in

  elim_old_raux ();

  Sj.iter (
    fun (j,tsj,rrels) ->
      assert(j>=q);
      assert(MFOTL.in_right_ext (MFOTL.ts_minus tsj tsq) intv);
      let relq = elim_old j rrels in
      if (not discard) && not (Relation.is_empty relq) then
        inf.ures <- Relation.union inf.ures relq;
      if Misc.debugging Dbg_eval then
        Relation.print_reln "[update_aux] res: " inf.ures;
  ) inf.raux;

  (* saux holds elements (k,relk) for the last seen index,
     i.e. [i] *)
  assert(i>=q-1);
  if i=q-1 then
    Sk.clear inf.saux
  else
    ignore(elim_old i inf.saux)


(* Auxiliary functions for the f1 Until_I f2 case.

   The saux list contains tuples (k,Sk) (ordered incrementally by k),
   with q <= k <= i, such that the tuples in Sk satisfy f1
   continuously between k and i, and k is minimal (that is, if a tuple
   is in Sk it will not also be in Sk' with k'>k.)

   The raux list contains tuples (j,tj,Lj) (ordered incrementaly by
   j), with q <= j <= i, where Lj is a list of tuples (k,Rk) (ordered
   incrementaly by k), with q <= k <= j, such that the tuples in Rk
   satisfy f2 at j and satisfy f1 continuously between k and j-1, and
   k is minimal (that is, if a tuple is in Rk it will not also be in
   Rk' with j>=k'>k.)

   NOTE: The iteration through raux to eliminate those tuples <k,Sk>
   with k<q (ie. k=q-1) seems unnecessary. If a tuple in Sk satisfies
   f1 continuously from k to j, then it also satisfies f1 continuously
   from q to j.
*)


let combine2 comp j rels rel2 =
  let nrels = Sk.empty() in
  let curr_rel2 = ref rel2 in
  Sk.iter
    (fun (k,rel) ->
       let nrel = comp !curr_rel2 rel in
       if not (Relation.is_empty nrel) then
         Sk.add_last (k,nrel) nrels;
       curr_rel2 := Relation.diff !curr_rel2 nrel;
    ) rels;
  if not (Relation.is_empty !curr_rel2) then
    Sk.add_last (j,!curr_rel2) nrels;
  nrels

let get_relq q rels =
  if not (Sj.is_empty rels) then
    let (k,relk) = Sj.get_first rels in
    if k = q then Some relk
    else None
  else
    None

let update_until q tsq i tsi intv rel1 rel2 inf comp discard =
  if Misc.debugging Dbg_eval then
    print_uinf "[update_until] inf: " inf;
  assert(i >= q);
  let nsaux = combine2 Relation.inter i inf.saux rel1 in
  if (MFOTL.in_right_ext (MFOTL.ts_minus tsi tsq) intv) &&
     not (Relation.is_empty rel2) then
    begin
      let rrels = combine2 comp i inf.saux rel2 in
      Sj.add_last (i,tsi,rrels) inf.raux;
      if not discard then
        match get_relq q rrels with
        | Some rel -> inf.ures <- Relation.union inf.ures rel
        | None -> ()
    end;
  inf.saux <- nsaux


let elim_old_eventually tsq intv inf =
  let auxrels = inf.eauxrels in

  let rec elim_old_eauxrels () =
    (* remove old elements that fell out of the interval *)
    if not (Dllist.is_empty auxrels) then
      let (tsj, _) = Dllist.get_first auxrels in
      if not (MFOTL.in_right_ext (MFOTL.ts_minus tsj tsq) intv) then
        begin
          if inf.elast != Dllist.void && inf.elast == Dllist.get_first_cell auxrels then
            inf.elast <- Dllist.void;
          ignore(Dllist.pop_first auxrels);
          elim_old_eauxrels()
        end
  in

  elim_old_eauxrels ()


let handle_empty_agg_result {agg_op; agg_default} q tsq rel =
  if Relation.is_empty rel then
    (match agg_default with
    | None -> rel  (* aggregation with group-by -> empty relation is fine *)
    | Some default_value ->  (* aggregation without group-by *)
      (match agg_op with
      | Avg | Med | Min | Max ->
        let op_str = MFOTL.string_of_agg_op agg_op in
        let default_str = string_of_cst true default_value in
        Printf.eprintf "WARNING: %s applied on empty relation \
                        at time point %d, timestamp %s! \
                        Resulting value is %s, by (our) convention.\n"
          op_str q (MFOTL.string_of_ts tsq) default_str
      | Cnt | Sum -> ());
      Relation.singleton (Tuple.make_tuple [default_value]))
  else rel


(* Arguments:
   - [f] the current formula
   - [crt] the current evaluation point (an neval cell)
   - [discard] a boolean; if true then the result is not used
               (only a minimal amount of computation should be done);
               it should not be propagated for temporal subformulas
               (pitfall: possible source of bugs)
*)
let rec eval f crt discard =
  let (q,tsq) = Neval.get_data crt in

  if Misc.debugging Dbg_eval then
    begin
      print_extf "\n[eval] evaluating formula\n" f;
      Printf.printf "at (%d,%s) with discard=%b and "
        q (MFOTL.string_of_ts tsq) discard;
      Neval.print_queue "neval=" crt
    end;

  match f with
  | ERel rel -> Some rel

  | EPred (p,_,inf) ->
    if Misc.debugging Dbg_eval then
      begin
        print_string "[eval,Pred] ";
        Predicate.print_predicate p;
        print_predinf  ": " inf
      end;

    let (cq,ctsq,rel) = Queue.pop inf in
    assert (cq = q && ctsq = tsq);
    Some rel

  | ENeg f1 ->
    (match eval f1 crt discard with
     | Some rel ->
       let res =
         if Relation.is_empty rel then (* false? *)
           Relation.singleton (Tuple.make_tuple [])
         else
           Relation.empty (* true *)
       in
       Some res
     | None -> None
    )

  | EExists (comp,f1) ->
    (match eval f1 crt discard with
     | Some rel -> Some (comp rel)
     | None -> None
    )

  | EAnd (comp,f1,f2,inf) ->
    (* we have to store rel1, if f2 cannot be evaluated *)
    let eval_and rel1 =
      if Relation.is_empty rel1 then
        (match eval f2 crt true with
         | Some _ ->
           inf.arel <- None;
           Some rel1
         | None ->
           inf.arel <- Some rel1;
           None
        )
      else
        (match eval f2 crt discard with
         | Some rel2 ->
           inf.arel <- None;
           Some (comp rel1 rel2)
         | None ->
           inf.arel <- Some rel1;
           None
        )
    in
    (match inf.arel with
     | Some rel1 -> eval_and rel1
     | None ->
       (match eval f1 crt discard with
        | Some rel1 -> eval_and rel1
        | None -> None
       )
    )

  | EAggreg (inf, comp, f) ->
    (match eval f crt discard with
     | Some rel ->
       Some (if discard then Relation.empty
         else handle_empty_agg_result inf q tsq (comp rel))
     | None -> None
    )

  | EOr (comp, f1, f2, inf) ->
    (* we have to store rel1, if f2 cannot be evaluated *)
    (match inf.arel with
     | Some rel1 ->
       (match eval f2 crt discard with
        | Some rel2 ->
          inf.arel <- None;
          Some (comp rel1 rel2)
        | None -> None
       )
     | None ->
       (match eval f1 crt discard with
        | Some rel1 ->
          (match eval f2 crt discard with
           | Some rel2 -> Some (comp rel1 rel2)
           | None ->
             inf.arel <- Some rel1;
             None
          )
        | None -> None
       )
    )

  | EPrev (intv,f1,inf) ->
    if Misc.debugging Dbg_eval then
      Printf.printf "[eval,Prev] inf.plast=%s\n%!" (Neval.string_of_cell inf.plast);

    if q = 0 then
      Some Relation.empty
    else
      begin
        let pcrt = Neval.get_next inf.plast in
        let pq, ptsq = Neval.get_data pcrt in
        assert(pq = q-1);
        match eval f1 pcrt discard with
        | Some rel1 ->
          inf.plast <- pcrt;
          if MFOTL.in_interval (MFOTL.ts_minus tsq ptsq) intv then
            Some rel1
          else
            Some Relation.empty
        | None -> None
      end

  | ENext (intv,f1,inf) ->
    if Misc.debugging Dbg_eval then
      Printf.printf "[eval,Next] inf.init=%b\n%!" inf.init;

    if inf.init then
      begin
        match eval f1 crt discard with
        | Some _ -> inf.init <- false
        | _ -> ()
      end;

    if Neval.is_last crt then
      None
    else
      begin
        let ncrt = Neval.get_next crt in
        let nq, ntsq = Neval.get_data ncrt in
        assert (nq = q+1);
        match eval f1 ncrt discard with
        | Some rel1 ->
          if MFOTL.in_interval (MFOTL.ts_minus ntsq tsq) intv then
            Some rel1
          else
            Some Relation.empty
        | None -> None
      end

  | ESinceA (comp,intv,f1,f2,inf) ->
    if Misc.debugging Dbg_eval then
      Printf.printf "[eval,SinceA] q=%d\n%!" q;

    let eval_f1 rel2 comp2 =
      (match eval f1 crt false with
       | Some rel1 ->
         inf.sarel2 <- None;
         Some (comp2 rel1 rel2)
       | None ->
         inf.sarel2 <- Some rel2;
         None
      )
    in

    let update_sauxrels = update_since_all intv tsq inf comp in

    (match inf.sarel2 with
     | Some rel2 -> eval_f1 rel2 update_sauxrels
     | None ->
       (match eval f2 crt false with
        | None -> None
        | Some rel2 -> eval_f1 rel2 update_sauxrels
       )
    )

  | ESince (comp,intv,f1,f2,inf) ->
    if Misc.debugging Dbg_eval then
      Printf.printf "[eval,Since] q=%d\n" q;

    let eval_f1 rel2 comp2 =
      (match eval f1 crt false with
       | Some rel1 ->
         inf.srel2 <- None;
         Some (comp2 rel1 rel2)
       | None ->
         inf.srel2 <- Some rel2;
         None
      )
    in

    let update_sauxrels = update_since intv tsq inf.sauxrels comp discard in

    (match inf.srel2 with
     | Some rel2 -> eval_f1 rel2 update_sauxrels
     | None ->
       (match eval f2 crt false with
        | None -> None
        | Some rel2 -> eval_f1 rel2 update_sauxrels
       )
    )


  | EOnceA ((c,_) as intv, f2, inf) ->
    (match eval f2 crt false with
     | None -> None
     | Some rel2 ->
       if Misc.debugging Dbg_eval then
         Printf.printf "[eval,OnceA] q=%d\n" q;

       if c = CBnd MFOTL.ts_null then
         begin
           inf.ores <- Relation.union inf.ores rel2;
           Some inf.ores
         end
       else
         begin
           if not (Relation.is_empty rel2) then
             mqueue_add_last inf.oaauxrels tsq rel2;

           update_once_all intv tsq inf;
           Some inf.ores
         end
    )

  | EAggOnce (inf, state, f) ->
    (match eval f crt false with
     | Some rel ->
       state#slide tsq rel;
       Some (if discard then Relation.empty
         else handle_empty_agg_result inf q tsq state#get_result)
     | None -> None
    )

  (* We distinguish between whether the left margin of [intv] is
     zero or not, as we need to have two different ways of
     representing the margins of the windows in the tree: when 0
     is not included we can use the timestamps and merge
     relations at equal timestamps; otherwise, when 0 is not
     included, we need to use the timepoints. *)
  | EOnceZ (intv,f2,inf) ->
    (match eval f2 crt false with
     | None -> None
     | Some rel2 ->
       if Misc.debugging Dbg_eval then
         Printf.printf "[eval,OnceZ] q=%d\n" q;

       Some (update_once_zero intv q tsq inf rel2 discard)
    )

  | EOnce (intv,f2,inf) ->
    (match eval f2 crt false with
     | None -> None
     | Some rel2 ->
       if Misc.debugging Dbg_eval then
         Printf.printf "[eval,Once] q=%d\n" q;

       if not (Relation.is_empty rel2) then
         dllist_add_last inf.oauxrels tsq rel2;

       Some (update_once intv tsq inf discard)
    )

  | EUntil (comp,intv,f1,f2,inf) ->
    (* contents of inf:  (f = f1 UNTIL_intv f2)
       ulast:        last cell of neval for which both f1 and f2 are evaluated
       ufirst:       boolean flag indicating if we are at the first
                     iteration after the evaluation of f (i.e. q was
                     just moved); in this case we remove auxiliary
                     relations at old q
       ures:         the current partial result (for f)
       urel2:        the evaluation of f2 at ulast
       raux, saux:   the auxiliary relations
    *)

    if Misc.debugging Dbg_eval then
      begin
        let str = Printf.sprintf "[eval,Until] q=%d inf: " q in
        print_uinf str inf
      end;

    if inf.ufirst then
      begin
        inf.ufirst <- false;
        let (i,_) = Neval.get_data inf.ulast in
        update_old_until q tsq i intv inf discard;
        if Misc.debugging Dbg_eval then
          print_uinf "[eval,Until,after_update] inf: " inf
      end;

    (* we first evaluate f2, and then f1 *)

    let rec evalf1 i tsi rel2 ncrt =
      (match eval f1 ncrt false with
       | Some rel1 ->
         update_until q tsq i tsi intv rel1 rel2 inf comp discard;
         inf.urel2 <- None;
         inf.ulast <- ncrt;
         evalf2 ()
       | None ->
         inf.urel2 <- (Some rel2);
         None
      )

    and evalf2 () =
      if Neval.is_last inf.ulast then
        None
      else
        let ncrt = Neval.get_next inf.ulast in
        let (i,tsi) = Neval.get_data ncrt in
        if not (MFOTL.in_left_ext (MFOTL.ts_minus tsi tsq) intv) then
          (* we have the lookahead, we can compute the result *)
          begin
            if Misc.debugging Dbg_eval then
              Printf.printf "[eval,Until] evaluation possible q=%d tsq=%s\n"
                q (MFOTL.string_of_ts tsq);
            let res = inf.ures in
            inf.ures <- Relation.empty;
            inf.ufirst <- true;
            Some res
          end
        else
          begin
            (match inf.urel2 with
             | Some rel2 -> evalf1 i tsi rel2 ncrt
             | None ->
               (match eval f2 ncrt false with
                | None -> None
                | Some rel2 -> evalf1 i tsi rel2 ncrt
               )
            )
          end
    in
    evalf2()

  | ENUntil (comp,intv,f1,f2,inf) ->
    (* contents of inf:  (f = NOT f1 UNTIL_intv f2)
       ulast1:       last cell of neval for which f1 is evaluated
       ulast2:       last cell of neval for which f2 is evaluated
       listrel1:     list of evaluated relations for f1
       listrel2:     list of evaluated relations for f2

       NOTE: a possible optimization would be to not store empty relations
    *)

    (* evaluates the subformula f as much as possible *)
    let rec eval_subf f list last  =
      if Neval.is_last last then
        last
      else
        let ncrt = Neval.get_next last in
        match eval f ncrt false with
        | None -> last
        | Some rel ->
          (* store the result and try the next time point *)
          let i, tsi = Neval.get_data ncrt in
          Dllist.add_last (i, tsi, rel) list;
          eval_subf f list ncrt
    in

    (* evaluate the two subformulas *)
    inf.last1 <- eval_subf f1 inf.listrel1 inf.last1;
    inf.last2 <- eval_subf f2 inf.listrel2 inf.last2;

    (* checks whether the position to be evaluated is beyond the interval *)
    let has_lookahead last =
      let ncrt =
        if Neval.is_last last then
          last
        else
          Neval.get_next last
      in
      let _, tsi = Neval.get_data ncrt in
      not (MFOTL.in_left_ext (MFOTL.ts_minus tsi tsq) intv)
    in

    if has_lookahead inf.last1 && has_lookahead inf.last2 then
      (* we have the lookahead for both f1 and f2 (to be consistent with Until),
         we can compute the result

         NOTE: we could evaluate earlier with respect to f1, also in Until *)
      begin
        (* we iteratively compute the union of the relations [f1]_j
           with q <= j <= j0-1, where j0 is the first index which
           satisfies the temporal constraint relative to q *)
        let f1union = ref Relation.empty in
        let crt1_j = ref (Dllist.get_first_cell inf.listrel1) in
        let rec iter1 () =
          let j,tsj,relj = Dllist.get_data !crt1_j in
          if j < q then
            begin (* clean up from previous evaluation *)
              assert (j = q-1);
              ignore(Dllist.pop_first inf.listrel1);
              crt1_j := Dllist.get_next inf.listrel1 !crt1_j;
              iter1 ()
            end
          else if not (MFOTL.in_right_ext (MFOTL.ts_minus tsj tsq) intv) then
            begin
              f1union := Relation.union !f1union relj;
              if not (Dllist.is_last inf.listrel1 !crt1_j) then
                begin
                  crt1_j := Dllist.get_next inf.listrel1 !crt1_j;
                  iter1 ()
                end
            end
        in
        iter1 ();

        (* we now iterate through the remaining indexes, updating the
           union, and also computing the result *)
        let res = ref Relation.empty in
        let crt2_j = ref (Dllist.get_first_cell inf.listrel2) in
        let rec iter2 () =
          let j2,tsj2,rel2 = Dllist.get_data !crt2_j in
          if j2 < q || not (MFOTL.in_right_ext (MFOTL.ts_minus tsj2 tsq) intv) then
            begin (* clean up from previous evaluation *)
              ignore(Dllist.pop_first inf.listrel2);
              if not (Dllist.is_last inf.listrel2 !crt2_j) then
                begin
                  crt2_j := Dllist.get_next inf.listrel2 !crt2_j;
                  iter2 ()
                end
            end
          else
            begin
              let j1,_tsj1,rel1 = Dllist.get_data !crt1_j in
              assert(j1 = j2);
              if MFOTL.in_left_ext (MFOTL.ts_minus tsj2 tsq) intv then
                begin
                  let resj = comp rel2 !f1union in
                  res := Relation.union !res resj;
                  f1union := Relation.union !f1union rel1;
                  let is_last1 = Dllist.is_last inf.listrel1 !crt1_j in
                  let is_last2 = Dllist.is_last inf.listrel2 !crt2_j in
                  if (not is_last1) && (not is_last2) then
                    begin
                      crt1_j := Dllist.get_next inf.listrel1 !crt1_j;
                      crt2_j := Dllist.get_next inf.listrel2 !crt2_j;
                      iter2 ()
                    end
                end
            end
        in
        iter2();
        Some !res
      end
    else
      None

  | EEventuallyZ (intv,f2,inf) ->
    (* contents of inf:
       elastev:  Neval.cell  last cell of neval for which f2 is evaluated
       eauxrels: info        the auxiliary relations (up to elastev)
    *)
    if Misc.debugging Dbg_eval then
      print_ezinf "[eval,EventuallyZ] inf: " inf;

    let rec ez_update () =
      if Neval.is_last inf.ezlastev then
        None
      else
        let ncrt = Neval.get_next inf.ezlastev in
        let (i,tsi) = Neval.get_data ncrt in
        (* Printf.printf "[eval,Eventually] e_update: ncrt.i = %d\n%!" i; *)
        if not (MFOTL.in_left_ext (MFOTL.ts_minus tsi tsq) intv) then
          (* we have the lookahead, we can compute the result *)
          begin
            if Misc.debugging Dbg_eval then
              Printf.printf "[eval,EventuallyZ] evaluation possible q=%d tsq=%s tsi=%s\n%!"
                q (MFOTL.string_of_ts tsq) (MFOTL.string_of_ts tsi);

            let auxrels = inf.ezauxrels in
            if Dllist.is_empty auxrels then
              Some Relation.empty
            else if discard then
              begin
                let lw, _, _ = Dllist.get_first auxrels in
                if lw = q then (* at next iteration this first element will be too old *)
                  begin
                    if inf.ezlast != Dllist.void && inf.ezlast == Dllist.get_first_cell auxrels then
                      inf.ezlast <- Dllist.void;
                    ignore(Dllist.pop_first auxrels);
                  end;
                Some Relation.empty
              end
            else
              begin
                if inf.ezlast != Dllist.void && inf.ezlast == Dllist.get_first_cell auxrels then
                  (* TODO: when can such a case occur? *)
                  inf.ezlast <- Dllist.void;

                let lw, _, _ = Dllist.get_first auxrels in
                assert (lw >= q); (* TODO: when lw > q *)
                let cond = fun (_,tsj,_) -> MFOTL.in_left_ext (MFOTL.ts_minus tsj tsq) intv in
                let f = fun (j,_,rel) -> (j,rel) in
                let subseq, new_last = get_new_elements auxrels inf.ezlast cond f in
                let rw =
                  if subseq = [] then
                    (* TODO: why j? when does this case occur? *)
                    let j, _, _  = Dllist.get_data inf.ezlast in j
                  else
                    begin
                      assert (new_last != Dllist.void);
                      inf.ezlast <- new_last;
                      let rw = fst (List.hd subseq) in
                      assert (rw = let j, _, _ = Dllist.get_data new_last in j);
                      rw
                    end
                in

                if Misc.debugging Dbg_eval then
                  begin
                    Printf.printf "[eval,EventuallyZ] lw = %d rw = %d " lw rw;
                    Misc.printnl_list "subseq = " print_auxel subseq;
                  end;

                let newt = Sliding.slide string_of_int Relation.union subseq (lw, rw) inf.eztree in

                if lw = q then (* at next iteration this first element will be too old *)
                  begin
                    if new_last == Dllist.get_first_cell auxrels then
                      inf.ezlast <- Dllist.void;
                    ignore(Dllist.pop_first auxrels);
                  end;

                inf.eztree <- newt;
                Some (Sliding.stree_res newt)
              end
          end
        else (* we don't have the lookahead -> we cannot compute the result *)
          begin
            match eval f2 ncrt false with
            | None -> None
            | Some rel2 ->
              (* we update the auxiliary relations *)
              if not (Relation.is_empty rel2) then
                Dllist.add_last (i,tsi,rel2) inf.ezauxrels;
              inf.ezlastev <- ncrt;
              ez_update ()
          end
    in
    ez_update ()


  | EEventually (intv,f2,inf) ->
    (* contents of inf:
       elastev:  NEval.cell  last cell of neval for which f2 is evaluated
       eauxrels: info        the auxiliary relations (up to elastev)
    *)
    if Misc.debugging Dbg_eval then
      print_einfn "[eval,Eventually] inf: " inf;

    (* we could in principle do this update less often: that is, we
       can do after each evaluation, but we need to find out the
       value of ts_{q+1} *)
    elim_old_eventually tsq intv inf;

    let rec e_update () =
      if Neval.is_last inf.elastev then
        None
      else
        let ncrt = Neval.get_next inf.elastev in
        let (_i,tsi) = Neval.get_data ncrt in
        (* Printf.printf "[eval,Eventually] e_update: ncrt.i = %d\n%!" i; *)
        if not (MFOTL.in_left_ext (MFOTL.ts_minus tsi tsq) intv) then
          (* we have the lookahead, we can compute the result *)
          begin
            if Misc.debugging Dbg_eval then
              Printf.printf "[eval,Eventually] evaluation possible q=%d tsq=%s tsi=%s\n%!"
                q (MFOTL.string_of_ts tsq) (MFOTL.string_of_ts tsi);

            let auxrels = inf.eauxrels in
            if Dllist.is_empty auxrels || discard then
              Some Relation.empty
            else
              let lw, _ = Dllist.get_first auxrels in
              if MFOTL.in_left_ext (MFOTL.ts_minus lw tsq) intv then
                (* the new window is not empty *)
                let cond = fun (tsj,_) -> MFOTL.in_left_ext (MFOTL.ts_minus tsj tsq) intv in
                let subseq, new_last = get_new_elements auxrels inf.elast cond (fun x -> x) in
                let rw =
                  if subseq = [] then
                    fst (Dllist.get_data inf.elast)
                  else
                    begin
                      assert (new_last != Dllist.void);
                      inf.elast <- new_last;
                      let rw = fst (List.hd subseq) in
                      assert (rw = fst (Dllist.get_data new_last));
                      rw
                    end
                in
                if Misc.debugging Dbg_eval then
                  begin
                    Printf.printf "[eval,Eventually] lw = %s rw = %s "
                      (MFOTL.string_of_ts lw)
                      (MFOTL.string_of_ts rw);
                    Misc.printnl_list "subseq = " print_sauxel subseq;
                  end;
                let newt = Sliding.slide MFOTL.string_of_ts Relation.union subseq (lw, rw) inf.etree in
                inf.etree <- newt;
                Some (Sliding.stree_res newt)
              else
                begin
                  (* the new window is empty,
                     because not even the oldest element satisfies the constraint *)
                  inf.etree <- LNode {l = MFOTL.ts_invalid;
                                      r = MFOTL.ts_invalid;
                                      res = Some (Relation.empty)};
                  inf.elast <- Dllist.void;
                  Some Relation.empty
                end
          end
        else
          begin
            match eval f2 ncrt false with
            | None -> None
            | Some rel2 ->
              (* we update the auxiliary relations *)
              if (MFOTL.in_right_ext (MFOTL.ts_minus tsi tsq) intv) &&
                 not (Relation.is_empty rel2) then
                dllist_add_last inf.eauxrels tsi rel2;
              inf.elastev <- ncrt;
              e_update ()
          end
    in
    e_update ()


let add_index f i tsi db =
  let rec update = function
    | EPred (p, comp, inf) ->
      let rel =
        (try
           let t = Db.get_table db p in
           Table.get_relation t
         with Not_found ->
         match Predicate.get_name p with
         | "tp" -> Relation.singleton (Tuple.make_tuple [Int i])
         | "ts" -> Relation.singleton (Tuple.make_tuple [Float tsi])
         | "tpts" ->
           Relation.singleton (Tuple.make_tuple [Int i; Float tsi])
         | _ -> Relation.empty
        )
      in
      let rel = comp rel in
      Queue.add (i,tsi,rel) inf

    | ERel _ -> ()

    | ENeg f1
    | EExists (_,f1)
    | EAggOnce (_,_,f1)
    | EAggreg (_,_,f1)
    | ENext (_,f1,_)
    | EPrev (_,f1,_)
    | EOnceA (_,f1,_)
    | EOnceZ (_,f1,_)
    | EOnce (_,f1,_)
    | EEventuallyZ (_,f1,_)
    | EEventually (_,f1,_) ->
      update f1

    | EAnd (_,f1,f2,_)
    | EOr (_,f1,f2,_)
    | ESinceA (_,_,f1,f2,_)
    | ESince (_,_,f1,f2,_)
    | ENUntil (_,_,f1,f2,_)
    | EUntil (_,_,f1,f2,_) ->
      update f1;
      update f2
  in
  update f


(** This function displays the "results" (if any) obtained after
    analyzing event index [i]. The results are those tuples satisfying
    the formula for some index [q<=i]. *)
let rec show_results closed i q tsq rel =
  if !Misc.stop_at_first_viol && Relation.cardinal rel > 1 then
    let rel2 = Relation.singleton (Relation.choose rel) in
    show_results closed i q tsq rel2
  else if !Misc.verbose then
    if closed then
      Printf.printf "@%s (time point %d): %b\n%!"
        (MFOTL.string_of_ts tsq) q (rel <> Relation.empty)
    else
      begin
        Printf.printf "@%s (time point %d): " (MFOTL.string_of_ts tsq) q;
        Relation.print_reln "" rel
      end
  else
    begin
      if Misc.debugging Dbg_perf then
        Perf.show_results q tsq;
      if rel <> Relation.empty then (* formula satisfied *)
        if closed then (* no free variables *)
          Printf.printf "@%s (time point %d): true\n%!" (MFOTL.string_of_ts tsq) q
        else (* free variables *)
          begin
            Printf.printf "@%s (time point %d): " (MFOTL.string_of_ts tsq) q;
            Relation.print_rel4 "" rel;
            print_newline()
          end
    end



let process_index ff closed last i =
  if !Misc.verbose then
    Printf.printf "At time point %d:\n%!" i;

  let rec eval_loop last =
    let crt = Neval.get_next last in
    let (q, tsq) = Neval.get_data crt in
    if tsq < MFOTL.ts_max then
      match eval ff crt false with
      | Some rel ->
        show_results closed i q tsq rel;
        if !Misc.stop_at_first_viol && not (Relation.is_empty rel) then None
        else if Neval.is_last crt then Some crt
        else eval_loop crt
      | None -> Some last
    else None
  in
  eval_loop last


let add_ext dbschema init_cell f =
  let rec add_ext = function
  | Pred p ->
    EPred (p, Relation.eval_pred p, Queue.create())

  | Equal (t1, t2) ->
    let rel = Relation.eval_equal t1 t2 in
    ERel rel

  | Neg (Equal (t1, t2)) ->
    let rel = Relation.eval_not_equal t1 t2 in
    ERel rel

  | Neg f -> ENeg (add_ext f)

  | Exists (vl, f1) ->
    let ff1 = add_ext f1 in
    let attr1 = MFOTL.free_vars f1 in
    let pos = List.map (fun v -> Misc.get_pos v attr1) vl in
    let pos = List.sort Stdlib.compare pos in
    let comp = Relation.project_away pos in
    EExists (comp,ff1)

  | Or (f1, f2) ->
    let ff1 = add_ext f1 in
    let ff2 = add_ext f2 in
    let attr1 = MFOTL.free_vars f1 in
    let attr2 = MFOTL.free_vars f2 in
    let comp =
      if attr1 = attr2 then
        Relation.union
      else
        let matches = Table.get_matches attr2 attr1 in
        let new_pos = List.map snd matches in
        (* first reorder rel2 *)
        (fun rel1 rel2 ->
           let rel2' = Relation.reorder new_pos rel2 in
           Relation.union rel1 rel2'
        )
    in
    EOr (comp, ff1, ff2, {arel = None})

  | And (f1, f2) ->
    let attr1 = MFOTL.free_vars f1 in
    let attr2 = MFOTL.free_vars f2 in
    let ff1 = add_ext f1 in
    let f2_is_special = Rewriting.is_special_case attr1 attr2 f2 in
    let ff2 =
      if f2_is_special then ERel Relation.empty
      else match f2 with
        | Neg f2' -> add_ext f2'
        | _ -> add_ext f2
    in
    let comp =
      if f2_is_special then
        if Misc.subset attr2 attr1 then
          let filter_cond = Tuple.get_filter attr1 f2 in
          fun rel1 _ -> Relation.filter filter_cond rel1
        else
          let process_tuple = Tuple.get_tf attr1 f2 in
          fun rel1 _ ->
            Relation.fold
              (fun t res -> Relation.add (process_tuple t) res)
              rel1 Relation.empty
      else
        match f2 with
        | Neg _ ->
          if attr1 = attr2 then
            fun rel1 rel2 -> Relation.diff rel1 rel2
          else
            begin
              assert(Misc.subset attr2 attr1);
              let posl = List.map (fun v -> Misc.get_pos v attr1) attr2 in
              fun rel1 rel2 -> Relation.minus posl rel1 rel2
            end

        | _ ->
          let matches1 = Table.get_matches attr1 attr2 in
          let matches2 = Table.get_matches attr2 attr1 in
          if attr1 = attr2 then
            fun rel1 rel2 -> Relation.inter rel1 rel2
          else if Misc.subset attr1 attr2 then
            fun rel1 rel2 -> Relation.natural_join_sc1 matches2 rel1 rel2
          else if Misc.subset attr2 attr1 then
            fun rel1 rel2 -> Relation.natural_join_sc2 matches1 rel1 rel2
          else
            fun rel1 rel2 -> Relation.natural_join matches1 matches2 rel1 rel2
    in
    EAnd (comp, ff1, ff2, {arel = None})

  | Aggreg (y, op, x, glist, Once (intv, f)) as ff ->
    let default =
      if glist = [] then
        let t_y = List.assoc y (Rewriting.check_syntax dbschema ff) in
        Some (MFOTL.agg_default_value op t_y)
      else None
    in
    let attr = MFOTL.free_vars f in
    let posx = Misc.get_pos x attr in
    let eval_x t = Tuple.get_at_pos t posx in
    let posG = List.map (fun z -> Misc.get_pos z attr) glist in
    let state =
      match op with
      | Cnt -> Aggreg.cnt_once intv posG
      | Min -> Aggreg.min_once intv eval_x posG
      | Max -> Aggreg.max_once intv eval_x posG
      | Sum -> Aggreg.sum_once intv eval_x posG
      | Avg -> Aggreg.avg_once intv eval_x posG
      | Med -> Aggreg.med_once intv eval_x posG
    in
    EAggOnce ({agg_op = op; agg_default = default}, state, add_ext f)

  | Aggreg (y, op, x, glist, f) as ff ->
    let default =
      if glist = [] then
        let t_y = List.assoc y (Rewriting.check_syntax dbschema ff) in
        Some (MFOTL.agg_default_value op t_y)
      else None
    in
    let attr = MFOTL.free_vars f in
    let posx = Misc.get_pos x attr in
    let eval_x t = Tuple.get_at_pos t posx in
    let posG = List.map (fun z -> Misc.get_pos z attr) glist in
    let comp =
      match op with
      | Cnt -> Aggreg.cnt posG
      | Min -> Aggreg.min eval_x posG
      | Max -> Aggreg.max eval_x posG
      | Sum -> Aggreg.sum eval_x posG
      | Avg -> Aggreg.avg eval_x posG
      | Med -> Aggreg.med eval_x posG
    in
    EAggreg ({agg_op = op; agg_default = default}, comp, add_ext f)

  | Prev (intv, f) ->
    let ff = add_ext f in
    EPrev (intv, ff, {plast = init_cell})

  | Next (intv, f) ->
    let ff = add_ext f in
    ENext (intv, ff, {init = true})

  | Since (intv,f1,f2) ->
    let attr1 = MFOTL.free_vars f1 in
    let attr2 = MFOTL.free_vars f2 in
    let ef1, neg =
      (match f1 with
       | Neg f1' -> f1',true
       | _ -> f1,false
      )
    in
    let comp =
      if neg then
        let posl = List.map (fun v -> Misc.get_pos v attr2) attr1 in
        assert(Misc.subset attr1 attr2);
        fun relj rel1 -> Relation.minus posl relj rel1
      else
        let matches2 = Table.get_matches attr2 attr1 in
        fun relj rel1 -> Relation.natural_join_sc2 matches2 relj rel1
    in
    let ff1 = add_ext ef1 in
    let ff2 = add_ext f2 in
    if snd intv = Inf then
      let inf = {sres = Relation.empty; sarel2 = None; saauxrels = Mqueue.create()} in
      ESinceA (comp,intv,ff1,ff2,inf)
    else
      let inf = {srel2 = None; sauxrels = Mqueue.create()} in
      ESince (comp,intv,ff1,ff2,inf)

  | Once ((_, Inf) as intv, f) ->
    let ff = add_ext f in
    EOnceA (intv,ff,{ores = Relation.empty;
                     oaauxrels = Mqueue.create()})

  | Once (intv,f) ->
    let ff = add_ext f in
    if fst intv = CBnd MFOTL.ts_null then
      EOnceZ (intv,ff,{oztree = LNode {l = -1;
                                       r = -1;
                                       res = Some (Relation.empty)};
                       ozlast = Dllist.void;
                       ozauxrels = Dllist.empty()})
    else
      EOnce (intv,ff,{otree = LNode {l = MFOTL.ts_invalid;
                                     r = MFOTL.ts_invalid;
                                     res = Some (Relation.empty)};
                      olast = Dllist.void;
                      oauxrels = Dllist.empty()})

  | Until (intv,f1,f2) ->
    let attr1 = MFOTL.free_vars f1 in
    let attr2 = MFOTL.free_vars f2 in
    let ef1, neg =
      (match f1 with
       | Neg f1' -> f1',true
       | _ -> f1,false
      )
    in
    let ff1 = add_ext ef1 in
    let ff2 = add_ext f2 in
    if neg then
      let comp =
        let posl = List.map (fun v -> Misc.get_pos v attr2) attr1 in
        assert(Misc.subset attr1 attr2);
        fun relj rel1 -> Relation.minus posl relj rel1
      in
      let inf = {
        last1 = init_cell;
        last2 = init_cell;
        listrel1 = Dllist.empty();
        listrel2 = Dllist.empty()}
      in
      ENUntil (comp,intv,ff1,ff2,inf)
    else
      let comp =
        let matches2 = Table.get_matches attr2 attr1 in
        fun relj rel1 -> Relation.natural_join_sc2 matches2 relj rel1
      in
      let inf = {ulast = init_cell;
                 ufirst = false;
                 ures = Relation.empty;
                 urel2 = None;
                 raux = Sj.empty();
                 saux = Sk.empty()}
      in
      EUntil (comp,intv,ff1,ff2,inf)


  | Eventually (intv,f) ->
    let ff = add_ext f in
    if fst intv = CBnd MFOTL.ts_null then
      EEventuallyZ (intv,ff,{eztree = LNode {l = -1;
                                             r = -1;
                                             res = Some (Relation.empty)};
                             ezlast = Dllist.void;
                             ezlastev = init_cell;
                             ezauxrels = Dllist.empty()})
    else
      EEventually (intv,ff,{etree = LNode {l = MFOTL.ts_invalid;
                                           r = MFOTL.ts_invalid;
                                           res = Some (Relation.empty)};
                            elast = Dllist.void;
                            elastev = init_cell;
                            eauxrels = Dllist.empty()})

  | _ -> failwith "[add_ext] internal error"
  in
  add_ext f


let resumefile = ref ""
let dumpfile = ref ""
let lastts = ref MFOTL.ts_invalid

(* The arguments are:
   lexbuf - the lexer buffer (holds current state of the scanner)
   ff - the extended MFOTL formula
   closed - true iff [ff] is a ground formula
   neval - the queue of not-yet evaluted indexes/entries
   last - the most recent evaluated index (a cell in the neval queue)
   i - the index of current entry in the log file
   ([i] may be different from the current time point when
   filter_empty_tp is enabled)
*)
let check_log lexbuf ff closed neval last i =
  let finish () =
    if Misc.debugging Dbg_perf then
      Perf.check_log_end i !lastts
  in
  let rec loop ffl last i =
    if Misc.debugging Dbg_perf then
      Perf.check_log i !lastts;
    match Log.get_next_entry lexbuf with
    | Some (tp, ts, db) ->
      if ts >= !lastts then
        begin
          crt_tp := tp;
          crt_ts := ts;
          add_index ff tp ts db;
          ignore (Neval.append (tp, ts) neval);
          let cont_last = process_index ff closed last tp in
          lastts := ts;
          (match cont_last with
          | Some l -> loop ffl l (i + 1)
          | None -> finish ())
        end
      else
      if !Misc.stop_at_out_of_order_ts then
        let msg = Printf.sprintf "[Algorithm.check_log] Error: OUT OF ORDER TIMESTAMP: %s \
                                  (last_ts: %s)" (MFOTL.string_of_ts ts) (MFOTL.string_of_ts !lastts) in
        failwith msg
      else
        begin
          Printf.eprintf "[Algorithm.check_log] skipping OUT OF ORDER TIMESTAMP: %s \
                          (last_ts: %s)\n%!"
            (MFOTL.string_of_ts ts) (MFOTL.string_of_ts !lastts);
          loop ffl last i
        end

    | None -> finish ()
  in
  loop ff last i


let monitor_lexbuf dbschema lexbuf f =
  let neval = Neval.create () in
  let init_cell = Neval.get_last neval in
  let ff = add_ext dbschema init_cell f in
  check_log lexbuf ff (MFOTL.free_vars f = []) neval init_cell 0

let monitor_string dbschema log f =
  (let lexbuf = Lexing.from_string log in
   lastts := MFOTL.ts_invalid;
   crt_tp := -1;
   crt_ts := MFOTL.ts_invalid;
   Log.tp := 0;
   Log.skipped_tps := 0;
   Log.last := false;
   monitor_lexbuf dbschema lexbuf f;
   Lexing.flush_input lexbuf)

let monitor dbschema logfile =
  let lexbuf = Log.log_open logfile in
  monitor_lexbuf dbschema lexbuf


let test_filter logfile f =
  let lexbuf = Log.log_open logfile in
  let rec loop f i =
    match Log.get_next_entry lexbuf with
    | Some (tp,_ts,_db) ->
      loop f tp
    | None ->
      Printf.printf "end of log, processed %d time points\n" (i - 1)
  in
  loop f 0
