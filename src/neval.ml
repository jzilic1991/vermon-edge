(*
 * This file is part of MONPOLY.
 *
 * Copyright (C) 2021 ETH Zurich.
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

type cell = {
  tp: int;
  ts: MFOTL.timestamp;
  mutable next: cell;
}

type queue = cell
(* The queue is actually a sentinel cell at the tail end of the queue. This hack
   allows us to implement [insert_after] without a separate reference to the
   queue (i.e., the tail reference it represents). For a value [q] of type
   queue, [q.next] points to the last proper cell. *)

let invalid_tp = -1
let tail_ref_tp = -2

let is_tail_ref c = (c.tp = tail_ref_tp)

let create () =
  let rec c = {tp = invalid_tp; ts = MFOTL.ts_invalid; next = q}
  and q = {tp = tail_ref_tp; ts = MFOTL.ts_invalid; next = c} in q

let get_last q = q.next

let prepend (tp, ts) c = {tp = tp; ts = ts; next = c}

let insert_after (tp, ts) c1 =
  let c3 = c1.next in
  let c2 = {tp = tp; ts = ts; next = c3} in
  c1.next <- c2;
  if is_tail_ref c3 then c3.next <- c2; (* adjust queue tail reference *)
  c2

let append p q = insert_after p (get_last q)

let is_last c = is_tail_ref (c.next)

let is_valid c = (c.tp >= 0)

let get_data c = (c.tp, c.ts)

let get_next c =
  assert (not (is_last c));
  c.next

let string_of_cell c = if c.tp < 0 then "<invalid>"
  else Printf.sprintf "(%d,%s)" c.tp (MFOTL.string_of_ts c.ts)

let print_queue str c =
  print_string str;
  let rec loop c =
    Printf.printf "(%d,%s)" c.tp (MFOTL.string_of_ts c.ts);
    if not (is_last c) then loop c.next
  in
  if is_valid c then loop c
