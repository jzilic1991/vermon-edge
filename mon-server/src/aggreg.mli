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

(** Computing aggregations over relations and sliding windows. *)

type eval_fun = Tuple.tuple -> Predicate.cst
(** The type of evaluation functions over tuples. *)


(** {1 Single relations} *)

type aggregator = Relation.relation -> Relation.relation
(** An aggregator is a relation transformer. The aggregate value is always
    inserted as a new attribute with index 0.

    For the special case when the input relation is empty and there are no
    grouping attributes, the empty relation is returned. This behavior is
    different from the MFOTL semantics and must be corrected externally. *)

val cnt: int list -> aggregator
(** [cnt gl] is the aggregator that computes the number of tuples for every
    group over the attributes [gl]. *)

val min: eval_fun -> int list -> aggregator
(** [min f gl] is the aggregator that computes the minimum value of [f] for
    every group over the attributes [gl]. *)

val max: eval_fun -> int list -> aggregator
(** [max f gl] is the aggregator that computes the maximum value of [f] for
    every group over the attributes [gl]. *)

val sum: eval_fun -> int list -> aggregator
(** [sum f gl] is the aggregator that computes the sum of values of [f] for
    every group over the attributes [gl]. *)

val avg: eval_fun -> int list -> aggregator
(** [avg f gl] is the aggregator that computes the average of values of [f] for
    every group over the attributes [gl]. *)

val med: eval_fun -> int list -> aggregator
(** [med f gl] is the aggregator that computes the median value of [f] for
    every group over the attributes [gl]. *)


(** {1 Sliding windows} *)

(** Stateful aggregator over a temporal sliding window. The window's dimensions
    are described by an interval. If the interval's lower bound is greater than
    zero, the window is offset towards the past relative to the "current" time.
    We call the current time also the window's anchor. The aggregate value is
    always inserted as a new attribute with index 0. *)
class type window_aggregator =
  object
    method slide: MFOTL.timestamp -> Relation.relation -> unit
    (** [agg#slide ts rel] adds a new time-point with the tuples from [rel] to
        the window represented by [agg]. The window is slid so that its anchor
        aligns with the time-stamp [ts]. *)

    method get_result: Relation.relation
    (** Extract the aggregation result for the current window. *)
  end

val cnt_once: MFOTL.interval -> int list -> window_aggregator
(** [cnt_once intv gl] is the stateful aggregator that computes the number of
    tuples for every group over the attributes [gl]. The window is defined by
    [intv]. *)

val min_once: MFOTL.interval -> eval_fun -> int list -> window_aggregator
(** [min_once intv f gl] is the stateful aggregator that computes the minimum
    value of [f] for every group over the attributes [gl]. The window is defined
    by [intv]. *)

val max_once: MFOTL.interval -> eval_fun -> int list -> window_aggregator
(** [max_once intv f gl] is the stateful aggregator that computes the maximum
    value of [f] for every group over the attributes [gl]. The window is defined
    by [intv]. *)

val sum_once: MFOTL.interval -> eval_fun -> int list -> window_aggregator
(** [sum_once intv f gl] is the stateful aggregator that computes the sum of
    values of [f] for every group over the attributes [gl]. The window is
    defined by [intv]. *)

val avg_once: MFOTL.interval -> eval_fun -> int list -> window_aggregator
(** [avg_once intv f gl] is the stateful aggregator that computes the average of
    values of [f] for every group over the attributes [gl]. The window is
    defined by [intv]. *)

val med_once: MFOTL.interval -> eval_fun -> int list -> window_aggregator
(** [med_once intv f gl] is the stateful aggregator that computes the median
    value of [f] for every group over the attributes [gl]. The window is defined
    by [intv]. *)
