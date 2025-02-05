(*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open Reason

(* propagates sources to sinks following a subtype relation *)
val flow : Context.t -> Type.t * Type.use_t -> unit

val flow_t : Context.t -> Type.t * Type.t -> unit

val unify : Context.t -> ?use_op:Type.use_op -> Type.t -> Type.t -> unit

val flow_p :
  Context.t ->
  use_op:Type.use_op ->
  reason ->
  (* lreason *)
  reason ->
  (* ureason *)
  Type.propref ->
  Type.property_type * Type.property_type ->
  unit

val flow_use_op : Context.t -> Type.use_op -> Type.use_t -> Type.use_t

val reposition :
  Context.t ->
  ?trace:Type.trace ->
  ALoc.t ->
  ?desc:reason_desc ->
  ?annot_loc:ALoc.t ->
  Type.t ->
  Type.t

val reposition_reason :
  Context.t -> ?trace:Type.trace -> Reason.reason -> ?use_desc:bool -> Type.t -> Type.t

(* constraint utils *)
val filter_optional : Context.t -> ?trace:Type.trace -> reason -> Type.t -> Type.ident

module Cache : sig
  val summarize_flow_constraint : Context.t -> (string * int) list
end

val get_builtin_typeapp :
  Context.t -> ?trace:Type.trace -> reason -> ?use_desc:bool -> name -> Type.t list -> Type.t

val mk_typeapp_instance_annot :
  Context.t ->
  ?trace:Type.trace ->
  use_op:Type.use_op ->
  reason_op:Reason.reason ->
  reason_tapp:Reason.reason ->
  ?cache:bool ->
  Type.t ->
  Type.t list ->
  Type.t

val mk_typeapp_instance :
  Context.t ->
  ?trace:Type.trace ->
  use_op:Type.use_op ->
  reason_op:Reason.reason ->
  reason_tapp:Reason.reason ->
  Type.t ->
  Type.t list ->
  Type.t

val resolve_spread_list :
  Context.t ->
  use_op:Type.use_op ->
  reason_op:Reason.t ->
  Type.unresolved_param list ->
  Type.spread_resolve ->
  unit

(* polymorphism *)

val subst :
  Context.t -> ?use_op:Type.use_op -> ?force:bool -> Type.t Subst_name.Map.t -> Type.t -> Type.t

val check_polarity :
  Context.t -> ?trace:Type.trace -> Type.typeparam Subst_name.Map.t -> Polarity.t -> Type.t -> unit

(* selectors *)

val eval_selector :
  Context.t ->
  ?trace:Type.trace ->
  annot:bool ->
  reason ->
  Type.t ->
  Type.selector ->
  Type.tvar ->
  int ->
  unit

val visit_eval_id : Context.t -> Type.Eval.id -> (Type.t -> unit) -> unit

(* destructors *)

val eval_evalt :
  Context.t -> ?trace:Type.trace -> Type.t -> Type.defer_use_t -> Type.Eval.id -> Type.t

val mk_type_destructor :
  Context.t ->
  trace:Type.trace ->
  Type.use_op ->
  Reason.reason ->
  Type.t ->
  Type.destructor ->
  Type.Eval.id ->
  bool * Type.t

val eval_keys : Context.t -> trace:Type.trace -> Reason.reason -> Type.t -> Type.t

val mk_possibly_evaluated_destructor :
  Context.t -> Type.use_op -> Reason.reason -> Type.t -> Type.destructor -> Type.Eval.id -> Type.t

(* ... *)

val mk_default : Context.t -> reason -> Type.t Default.t -> Type.t

(* contexts *)

val add_output : Context.t -> ?trace:Type.trace -> Error_message.t -> unit

(* builtins *)

val get_builtin : Context.t -> ?trace:Type.trace -> name -> reason -> Type.t

val get_builtin_result :
  Context.t ->
  ?trace:Type.trace ->
  name ->
  reason ->
  (Type.t, Type.t * Env_api.cacheable_env_error Nel.t) result

val get_builtin_tvar : Context.t -> ?trace:Type.trace -> name -> reason -> Type.ident

val get_builtin_type : Context.t -> ?trace:Type.trace -> reason -> ?use_desc:bool -> name -> Type.t

val get_builtin_module : Context.t -> ?trace:Type.trace -> ALoc.t -> string -> Type.tvar

val set_builtin : Context.t -> name -> Type.t lazy_t -> unit

val mk_instance : Context.t -> ?trace:Type.trace -> reason -> ?use_desc:bool -> Type.t -> Type.t

val mk_typeof_annotation : Context.t -> ?trace:Type.trace -> reason -> Type.t -> Type.t

(* trust *)
val mk_trust_var : Context.t -> ?initial:Trust.trust_qualifier -> unit -> Type.ident

val strengthen_trust : Context.t -> Type.ident -> Trust.trust_qualifier -> Error_message.t -> unit

val widen_obj_type :
  Context.t -> ?trace:Type.trace -> use_op:Type.use_op -> Reason.reason -> Type.t -> Type.t

val possible_concrete_types_for_inspection : Context.t -> Reason.reason -> Type.t -> Type.t list

val singleton_concrete_type_for_inspection : Context.t -> Reason.reason -> Type.t -> Type.t

val possible_concrete_types_for_computed_props : Context.t -> Reason.reason -> Type.t -> Type.t list

val resolve_id : Context.t -> int -> Type.t -> unit

val substitute_mapped_type_distributive_tparams :
  Context.t ->
  Type.trace ->
  use_op:Type.use_op ->
  Subst_name.t option ->
  property_type:Type.t ->
  Type.mapped_type_homomorphic_flag ->
  source:Type.t ->
  Type.t * Type.mapped_type_homomorphic_flag

module FlowJs : Flow_common.S
