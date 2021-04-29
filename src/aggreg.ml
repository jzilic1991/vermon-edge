(*
 * This file is part of MONPOLY.
 *
 * Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
 * Contact:  Nokia Corporation (Debmalya Biswas: debmalya.biswas@nokia.com)
 *
 * Copyright (C) 2012, 2021 ETH Zurich.
 * Contact:  ETH Zurich (Joshua Schneider: joshua.schneider@inf.ethz.ch)
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

open Predicate

type eval_fun = Tuple.tuple -> Predicate.cst

type aggregator = Relation.relation -> Relation.relation

(* Generic aggregator for a single relation. *)
let comp_aggreg init update post gl rel =
  if Relation.is_empty rel then rel
  else
    let map = Hashtbl.create 1000 (* TODO(JS): why this value? *) in
    Relation.iter
      (fun t ->
         let g = Tuple.projections gl t in
         try
           let ov = Hashtbl.find map g in
           let nv = update ov t in
           Hashtbl.replace map g nv;
         with
         | Not_found ->
           Hashtbl.add map g (init t);
      ) rel;
    let res = ref Relation.empty in
    Hashtbl.iter
      (fun g v ->
        let t = Tuple.add_first g (post v) in
        res := Relation.add t !res
      ) map;
    !res

let cnt gl =
  let init _t = 1 in
  let update v _t = v + 1 in
  let post v = Int v in
  comp_aggreg init update post gl

let min f gl =
  let update v t = min v (f t) in
  comp_aggreg f update (fun x -> x) gl

let max f gl =
  let update v t = max v (f t) in
  comp_aggreg f update (fun x -> x) gl

let sum f gl =
  let update v t = plus v (f t) in
  comp_aggreg f update (fun x -> x) gl

let avg f gl =
  let init t = (f t, 1) in
  let update (s, c) t = (plus s (f t), c + 1) in
  let post (s, c) = Float (float_of_cst s /. float_of_int c) in
  comp_aggreg init update post gl

let med f gl =
  let init t = ([f t], 1) in
  let update (l, c) t = (f t :: l, c + 1) in
  let post (l, c) =
    let sorted = List.sort Stdlib.compare l in
    Misc.median sorted c Predicate.avg
  in
  comp_aggreg init update post gl


class type fifo_aggregator =
  object
    method add_rel: MFOTL.timestamp -> Relation.relation -> unit
    method evict_until: MFOTL.timestamp -> unit
    method get_result: Relation.relation
  end

(* Stateful aggregation for commutative and invertible operations. *)
class comm_group_aggregator init add remove post intv gl =
  object
    val tw_rels = Queue.create ()
    (* (time-stamp, relation) pairs in window (for bounded intervals) *)

    (* TODO(JS): why these values? *)
    val mset = Hashtbl.create 1000 (* multiplicities of tuples in window *)
    val acc = Hashtbl.create 100 (* current aggregation *)

    method add_rel ts rel =
      if not (MFOTL.is_infinite_interval intv) then
        Queue.push (ts, rel) tw_rels;
      Relation.iter
        (fun t ->
          try
            let m = Hashtbl.find mset t in
            Hashtbl.replace mset t (m + 1)
          with Not_found ->
            Hashtbl.add mset t 1;
            let g = Tuple.projections gl t in
            try
              let ov = Hashtbl.find acc g in
              let nv = add ov t in
              Hashtbl.replace acc g nv
            with Not_found ->
              Hashtbl.add acc g (init t)
        ) rel

    method evict_until ts =
      let evict t =
        let m = Hashtbl.find mset t in
        if m > 1 then
          Hashtbl.replace mset t (m - 1)
        else
          begin
            Hashtbl.remove mset t;
            let g = Tuple.projections gl t in
            let ov = Hashtbl.find acc g in
            match remove ov t with
            | None -> Hashtbl.remove acc g
            | Some nv -> Hashtbl.replace acc g nv
          end
      in
      let rec loop () =
        if not (Queue.is_empty tw_rels) then
          let (tsr, rel) = Queue.top tw_rels in
          let diff = MFOTL.ts_minus ts tsr in
          if not (MFOTL.in_left_ext diff intv) then
            begin
              ignore (Queue.pop tw_rels);
              Relation.iter evict rel;
              loop ()
            end
      in
      loop ()

    method get_result =
      let res = ref Relation.empty in
      Hashtbl.iter
        (fun g v ->
          let t = Tuple.add_first g (post v) in
          res := Relation.add t !res
        ) acc;
      !res
  end

class window_aggregator (inner: fifo_aggregator) intv =
  object
    val non_tw_rels = Queue.create ()
    (* (time-stamp, relation) pairs more recent than current window *)

    method slide ts rel =
      inner#evict_until ts;
      if not (Relation.is_empty rel) then
        Queue.push (ts, rel) non_tw_rels;
      let rec consider_new_rels () =
        if not (Queue.is_empty non_tw_rels) then
          begin
            let (tsr, rel) = Queue.top non_tw_rels in
            let diff = MFOTL.ts_minus ts tsr in
            if not (MFOTL.in_left_ext diff intv) then
              begin
                (* relation already too old for the new time window *)
                ignore (Queue.pop non_tw_rels);
                consider_new_rels ()
              end
            else if MFOTL.in_interval diff intv then
              begin
                (* relation in the interval, so we process it *)
                ignore (Queue.pop non_tw_rels);
                inner#add_rel tsr rel;
                consider_new_rels ()
              end
            (* else, that is, if not (MFOTL.in_right_ext diff intv),
               the relation is too new, so we stop and consider it next time *)
          end
      in
      consider_new_rels ()

    method get_result = inner#get_result
  end

let cnt_once intv gl =
  let init _t = 1 in
  let add v _t = v + 1 in
  let remove v _t = if v = 1 then None else Some (v - 1) in
  let post v = Int v in
  let inner = new comm_group_aggregator init add remove post intv gl in
  new window_aggregator inner intv

(* helper for sum and avg *)
let sum_avg_once post intv f gl =
  let init t = (f t, 1) in
  let add (s, c) t = (plus s (f t), c + 1) in
  let remove (s, c) t = if c = 1 then None else Some (minus s (f t), c - 1) in
  let inner = new comm_group_aggregator init add remove post intv gl in
  new window_aggregator inner intv

let sum_once = sum_avg_once (fun (s, _) -> s)

let avg_once = sum_avg_once (fun (s, c) ->
  Float (float_of_cst s /. float_of_int c))


exception Break

module Cst_map = Map.Make(struct
  type t = cst
  let compare = Stdlib.compare
end)

(* The following precondition should hold: [len] is the sum of all values in
   [mset] *)
let mset_median fmed (mset, len) =
  assert (len <> 0);
  assert (len = Cst_map.fold (fun _ m s -> m + s) mset 0);
  let mid = if len mod 2 = 0 then (len / 2) - 1 else len / 2 in
  let flag = ref false in
  let crt = ref 0 in
  let med = ref (fst (Cst_map.choose mset)) in
  let prev = ref !med in
  try
    Cst_map.iter
      (fun c m ->
        if !flag then
          begin med := fmed !prev c; raise Break end
        else
        if mid < !crt + m then (* c is the (left) median *)
          if len mod 2 = 0 then
            if mid = !crt + m - 1 then
              begin flag := true;  prev := c end
            else
              begin med := fmed c c; raise Break end
          else begin med := fmed c c; raise Break end
        else
          crt := !crt + m
      ) mset;
    failwith "[mset_median] internal error"
  with Break -> !med

let med_once intv f gl =
  let init t = (Cst_map.singleton (f t) 1, 1) in
  let add (mset, c) t =
    let x = f t in
    let mset' = Cst_map.update x
      (function
        | None -> Some 1
        | Some m -> Some (m + 1)
      ) mset
    in
    (mset', c + 1)
  in
  let remove (mset, c) t =
    if c = 1 then None
    else
      let x = f t in
      let mset' = Cst_map.update x
        (function
          | None -> None
          | Some m when m = 1 -> None
          | Some m -> Some (m - 1)
        ) mset
      in
      Some (mset', c - 1)
  in
  let post v = mset_median Predicate.avg v in
  let inner = new comm_group_aggregator init add remove post intv gl in
  new window_aggregator inner intv


(* Stateful aggregator for minimum/maximum.
   is_better x y returns 1 if x better than y, 0 if they are equal, and -1
   otherwise.
   for minimum: x is better than y iff x < y
   for maximum: x is better than y iff x > y *)
class order_aggregator is_better intv f gl =
  object
    (* TODO(JS): why this value? *)
    val table = Hashtbl.create 100

    method add_rel ts rel =
      (* The invariant is:
         if (tsq,v) is before (tsq',v')
         then tsq >= tsq', v' is better or equal than v, and
         we don't have equality in both cases;

         The first condition is ensured by default, as timestamps are
         non-decreasing. We have to enforce the second and third
         consitions. *)
      let rec update_list_new new_val dllist =
        if Dllist.is_empty dllist then
          Dllist.add_first (ts, new_val) dllist
        else
          begin
            let (ts', crt_val) = Dllist.get_first dllist in
            let comp = is_better new_val crt_val in
            if comp > 0 then
              begin
                ignore (Dllist.pop_first dllist);
                update_list_new new_val dllist
              end
            else if comp = 0 then
              begin
                if ts <> ts' then
                  begin
                    ignore (Dllist.pop_first dllist);
                    Dllist.add_first (ts, new_val) dllist
                  end
                  (* else: same element appears previously, no need to update *)
              end
            else
              Dllist.add_first (ts, new_val) dllist
          end
      in
      Relation.iter
        (fun t ->
           let g = Tuple.projections gl t in
           let x = f t in
           try
             let dllist = Hashtbl.find table g in
             update_list_new x dllist
           with Not_found ->
             let dllist = Dllist.singleton (ts, x) in
             Hashtbl.add table g dllist;
        ) rel

    method evict_until ts =
      let rec update_list_old dllist =
        if not (Dllist.is_empty dllist) then
          let ts', _ = Dllist.get_last dllist in
          let diff = MFOTL.ts_minus ts ts' in
          if not (MFOTL.in_left_ext diff intv) then
            begin
              ignore (Dllist.pop_last dllist);
              update_list_old dllist
            end
      in
      Hashtbl.filter_map_inplace
        (fun _ dllist ->
          update_list_old dllist;
          if Dllist.is_empty dllist then None else Some dllist
        ) table

    method get_result =
      let res = ref Relation.empty in
      Hashtbl.iter
        (fun g dllist ->
          let _, x = Dllist.get_last dllist in
          let t = Tuple.add_first g x in
          res := Relation.add t !res
        ) table;
      !res
  end

let min_once intv f gl =
  let is_better x y = -(Stdlib.compare x y) in
  let inner = new order_aggregator is_better intv f gl in
  new window_aggregator inner intv

let max_once intv f gl =
  let is_better x y = Stdlib.compare x y in
  let inner = new order_aggregator is_better intv f gl in
  new window_aggregator inner intv
