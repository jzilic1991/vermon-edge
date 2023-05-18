(*
 * This file is part of MONPOLY.
 *
 * Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
 * Contact:  Nokia Corporation (Debmalya Biswas: debmalya.biswas@nokia.com)
 *
 * Copyright (C) 2012 ETH Zurich.
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


type var = string
type cst =
  | Int of int
  | Str of string
  | Float of float

type tcst = TInt | TStr | TFloat

(* type term =  *)
(*   | Var of var *)
(*   | Cst of cst *)
(*   | Plus of term * term *)
(* user defined function symbol *)
(* | FSymb of (string * term list * (cst list -> cst)) *)

type 'a eterm =
  | Var of 'a
  | Cst of cst
  | F2i of 'a eterm
  | I2f of 'a eterm
  | Plus of 'a eterm * 'a eterm
  | Minus of 'a eterm * 'a eterm
  | UMinus of 'a eterm
  | Mult of 'a eterm * 'a eterm
  | Div of 'a eterm * 'a eterm
  | Mod of 'a eterm * 'a eterm

type term = var eterm


(* predicate = name, arity, and list of arguments *)
type predicate = var * int * term list

(* restriction hints
   we assume that rigid predicates are binary
   hence a restiction hint is a pair of positions
*)
(* type rhint = int * int *) (* TODO: not used, remove? *)

let make_predicate (name,args) =
  (name, List.length args, args)


let get_info p = p
let get_name (name,_ar,_args) = name
let get_args (_name,_ar,args) = args


let type_of_cst = function
  | Int _ -> TInt
  | Str _ -> TStr
  | Float _ -> TFloat

(* TODO: should we return a set instead? *)
let rec tvars = function
  | Var v -> [v]
  | Cst _c -> []
  | F2i t | I2f t | UMinus t -> tvars t
  | Plus (t1, t2)
  | Minus (t1, t2)
  | Mult (t1, t2)
  | Div (t1, t2)
  | Mod (t1, t2)
    -> (tvars t1) @ (tvars t2)


let fresh_var fv =
  let rec search v =
    let var = "_x" ^ (string_of_int v) in
    if List.exists (fun x -> x = var) fv then search (v+1) else var
  in
  search 1

let fresh_var_mapping fv vs =
  let _, m = List.fold_left (fun (fv, m) old_v ->
      let new_v = fresh_var fv
      in (new_v :: fv, (old_v, new_v) :: m)
    ) (fv, []) vs
  in m

let mk_subst m = List.map (fun (v, v') -> (v, Var v')) m

let rec substitute_vars m = function
  | Var v as t -> (try List.assoc v m with Not_found -> t)
  | Cst _c as t -> t
  | F2i t -> F2i (substitute_vars m t)
  | I2f t -> I2f (substitute_vars m t)
  | UMinus t -> UMinus (substitute_vars m t)
  | Plus (t1, t2) -> Plus (substitute_vars m t1, substitute_vars m t2)
  | Minus (t1, t2) -> Minus (substitute_vars m t1, substitute_vars m t2)
  | Mult (t1, t2) -> Mult (substitute_vars m t1, substitute_vars m t2)
  | Div (t1, t2) -> Div (substitute_vars m t1, substitute_vars m t2)
  | Mod (t1, t2) -> Mod (substitute_vars m t1, substitute_vars m t2)


let eval_eterm f t =
  let rec eval = function
    | Cst c -> c
    | Var x -> f x
    | I2f t -> (match eval t with
        | Int c -> Float (float_of_int c)
        | _ -> failwith "[Predicate.eval_eterm, i2f] wrong types")
    | F2i t -> (match eval t with
        | Float c -> Int (int_of_float c)
        | _ -> failwith "[Predicate.eval_eterm, f2i] wrong types")
    | Plus (t1, t2) ->
      (match eval t1, eval t2 with
       | Int c1, Int c2 -> Int (c1 + c2)
       | Float c1, Float c2 -> Float (c1 +. c2)
       | _ -> failwith "[Predicate.eval_eterm, +] wrong types")
    | Minus (t1, t2) ->
      (match eval t1, eval t2 with
       | Int c1, Int c2 -> Int (c1 - c2)
       | Float c1, Float c2 -> Float (c1 -. c2)
       | _ -> failwith "[Predicate.eval_eterm, binary -] wrong types")
    | Mult (t1, t2) ->
      (match eval t1, eval t2 with
       | Int c1, Int c2 -> Int (c1 * c2)
       | Float c1, Float c2 -> Float (c1 *. c2)
       | _ -> failwith "[Predicate.eval_eterm, *] wrong types")
    | Div (t1, t2) ->
      (match eval t1, eval t2 with
       | Int c1, Int c2 -> Int (c1 / c2)
       | Float c1, Float c2 -> Float (c1 /. c2)
       | _ -> failwith "[Predicate.eval_eterm, /] wrong types")
    | Mod (t1, t2) ->
      (match eval t1, eval t2 with
       | Int c1, Int c2 -> Int (c1 mod c2)
       | _ -> failwith "[Predicate.eval_eterm, mod] wrong types")
    | UMinus t ->
      (match eval t with
       | Int c -> Int (- c)
       | Float c -> Float (-. c)
       | _ -> failwith "[Predicate.eval_eterm, unary -] wrong type")
  in
  eval t


let eval_term assign =
  eval_eterm (fun x -> List.assoc x assign)

(* evaluate ground term *)
let eval_gterm t = eval_term [] t


let avg a b =
  match a, b with
  | Int x, Int y -> Float (((float_of_int x) +. (float_of_int y)) /. 2.)
  | Float x, Float y -> Float ((x+.y)/.2.)
  | _ -> failwith "[Predicate.avg] type error"

let plus a b =
  match a, b with
  | Int x, Int y -> Int (x+y)
  | Float x, Float y -> Float (x+.y)
  | _ -> failwith "[Predicate.plus] type error"

let minus a b =
  match a, b with
  | Int x, Int y -> Int (x-y)
  | Float x, Float y -> Float (x-.y)
  | _ -> failwith "[Predicate.minus] type error"

let float_of_cst = function
  | Int x -> float_of_int x
  | Float x -> x
  | _ -> failwith "[Predicate.float_of_cst] type error"


(* TODO: should we return a set instead? *)
let pvars (p:predicate) =
  let get_vars l = List.fold_left (fun vars t -> vars @ (tvars t)) [] l in
  Misc.remove_duplicates (get_vars (get_args p))




let cst_smaller c c' =
  match c,c' with
  | Int a, Int a' -> a < a'
  | Str a, Str a' -> a < a'
  | _ -> failwith "[Predicate.cst_smaller] incomparable constants"

let _cst_smaller_eq c c' =
  match c,c' with
  | Int a, Int a' -> a <= a'
  | Str a, Str a' -> a <= a'
  | _ -> failwith "[Predicate.cst_smaller_eq] incomparable constants"


let int_of_cst = function
  | Int n -> n
  | _ -> failwith "[Predicate.int_of_cst]"

let print_var = print_string

let print_tcst t =
  match t with
  | TInt -> print_string "int"
  | TStr -> print_string "string"
  | TFloat -> print_string "float"

let string_of_var var =
  var

let string_of_cst qm c =
  match c with
  | Int i -> string_of_int i
  | Float f -> Printf.sprintf "%g" f
  | Str s ->
    if s = "" then "\"\""
    else if qm then
      if s.[0] = '\"' && s.[(String.length s)-1] = '\"' then s
      else "\"" ^ s ^ "\""
    else s


let print_cst qm c = print_string (string_of_cst qm c)



let string_of_term term =
  let add_paren str = "(" ^ str ^ ")" in
  let rec t2s b term =
    let b', str = match term with
      | Var v -> true, v
      | Cst c -> true, string_of_cst true c
      | F2i t ->  false, "f2i(" ^ (t2s true t) ^ ")"
      | I2f t ->  false, "i2f(" ^ (t2s true t) ^ ")"
      | UMinus t ->  false, "-" ^ (t2s' t)
      | Plus (t1, t2) -> false, (t2s' t1) ^ " + " ^ (t2s' t2)
      | Minus (t1, t2) -> false, (t2s' t1) ^ " - " ^ (t2s' t2)
      | Mult (t1, t2) -> false, (t2s' t1) ^ " * " ^ (t2s' t2)
      | Div (t1, t2) -> false, (t2s' t1) ^ " / " ^ (t2s' t2)
      | Mod (t1, t2) -> false, (t2s' t1) ^ " mod " ^ (t2s' t2)
    in
    (* we don't add parentheses for the top-most operator, nor around
       constants and variables *)
    if b || b' then str else add_paren str
  and
    t2s' term = t2s false term
  in
  t2s true term

let print_term t = print_string (string_of_term t)

let string_of_predicate (p,_ar,args) =
  string_of_var p ^ Misc.string_of_list string_of_term args

let print_predicate (p,_ar,args) =
  print_var p;
  Misc.print_list print_term args

let print_vartypes_list vartypes_list =
  Misc.print_list_ext "" "" ", "
    (fun (v,t) ->
       print_string (v ^ ":");
       match t with
       | TInt -> print_string "int"
       | TStr -> print_string "string"
       | TFloat -> print_string "float"
    )
    vartypes_list;
  print_newline()
