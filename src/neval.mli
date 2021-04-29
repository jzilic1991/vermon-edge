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

(** The neval ("not yet evaluated") queue keeps track of timepoint-timestamp
    pairs that are relevant to the evaluation algorithm.

    The queue is mutable but append-only. There is no pop or remove operation.
    Instead there are many "heads" pointing to different cells in the same
    queue. Using the heads, one can move efficiently from one cell to the next.
    Every head belongs to a unique queue.

    The queue is implemented as a singly linked list with mutable references.
    Cells that are no longer referenced (directly or indirectly from some
    predecessor) are collected by the garbage collector. *)

type cell
(** Reference to a cell ("head"). *)

type queue
(** Reference to the queue ("tail"). *)

val create: unit -> queue
(** Create a new queue, which is initialized with a single invalid cell. *)

val get_last: queue -> cell
(** Return the last cell in the queue, which is never empty (but the cell can be
    invalid). *)

val prepend: int * MFOTL.timestamp -> cell -> cell
(** [prepend p c] inserts a new cell storing the pair [p] before the cell [c].
    Warning: This has the intended behavior only if there is no head before [c].
    The new cell is not visible to such heads. *)

val insert_after: int * MFOTL.timestamp -> cell -> cell
(** [insert_after p c] inserts a new cell storing the pair [p] after the cell
    [c]. Returns the new cell. *)

val append: int * MFOTL.timestamp -> queue -> cell
(** [append p q] adds the pair [p] to the end of the queue. It is equivalent to
    [insert_after p (get_last q)]. *)

val is_last: cell -> bool
(** Test whether a cell is currently the last cell in the queue that it belongs
    to. The result changes from [true] to [false] after [append]ing to the
    queue. *)

val is_valid: cell -> bool
(** Test whether a cell contains a valid timepoint. *)

val get_data: cell -> int * MFOTL.timestamp
(** Return the pair stored in the cell. *)

val get_next: cell -> cell
(** [get_next c] returns a reference to the next cell after [c].
    Precondition: [not (is_last c)]. *)

val string_of_cell: cell -> string
(** Format the cell's content. *)

val print_queue: string -> cell -> unit
(** [print_queue str c] prints [str] followed by the neval queue, starting at
    the cell [c]. *)
