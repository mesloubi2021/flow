(*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open Ty_normalizer_env

type error_kind =
  | BadMethodType
  | BadBoundT
  | BadCallProp
  | BadClassT
  | BadMappedType
  | BadThisClassT
  | BadPoly
  | BadTypeAlias
  | BadTypeApp
  | BadInlineInterfaceExtends
  | BadInternalT
  | BadInstanceT
  | BadEvalT
  | BadUse
  | ShadowTypeParam
  | UnexpectedTypeCtor of string
  | UnsupportedTypeCtor
  | UnsupportedUseCtor
  | RecursionLimit

type error = error_kind * string

val error_to_string : error -> string

module Lookahead : sig
  type t =
    | Recursive
    | LowerBounds of Type.t list

  val peek : Context.t -> Type.t -> t
end

val from_type : options:options -> genv:genv -> Type.t -> (Ty.elt, error) result

val from_scheme : options:options -> genv:genv -> Type.TypeScheme.t -> (Ty.elt, error) result

(* The following differ from mapping `from_type` on each input as it folds over
   the input elements of the input propagating the state (caches) after each
   transformation to the next element. *)
val from_types :
  options:options -> genv:genv -> ('a * Type.t) list -> ('a * (Ty.elt, error) result) list

val from_schemes :
  options:options ->
  genv:genv ->
  ('a * Type.TypeScheme.t) list ->
  ('a * (Ty.elt, error) result) list

val fold_hashtbl :
  options:options ->
  genv:genv ->
  f:('a -> 'loc * (Ty.elt, error) result -> 'a) ->
  g:('b -> Type.TypeScheme.t) ->
  htbl:('loc, 'b) Hashtbl.t ->
  'a ->
  'a

val expand_members :
  force_instance:bool -> options:options -> genv:genv -> Type.TypeScheme.t -> (Ty.t, error) result

val expand_literal_union : options:options -> genv:genv -> Type.TypeScheme.t -> (Ty.t, error) result

(* A debugging facility for getting quick string representations of Type.t *)
val debug_string_of_t : Context.t -> Type.t -> string
