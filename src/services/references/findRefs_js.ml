(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

(** Sort and dedup by loc.

    This will have to be revisited if we ever need to report multiple ref kinds for
    a single location. *)
let sort_and_dedup refs =
  Base.List.dedup_and_sort ~compare:(fun (_, loc1) (_, loc2) -> Loc.compare loc1 loc2) refs

let local_variable_refs scope_info loc =
  match VariableFindRefs.local_find_refs scope_info loc with
  | None -> (None, loc)
  | Some (var_refs, local_def_loc) -> (Some var_refs, local_def_loc)

let parse_contents ~options ~profiling content file_key =
  match Type_contents.parse_contents ~options ~profiling content file_key with
  | (Some (Types_js_types.Parse_artifacts { ast; file_sig; docblock; _ }), _errs) ->
    Ok (ast, file_sig, docblock)
  | (None, errs) ->
    if Flow_error.ErrorSet.is_empty errs then
      Error "Parse skipped"
    else
      Error "Parse unexpectedly failed"

let find_local_refs ~reader ~options ~env ~profiling ~file_input ~line ~col =
  let open Base.Result.Let_syntax in
  let filename = File_input.filename_of_file_input file_input in
  let file_key = File_key.SourceFile filename in
  let loc = Loc.cursor (Some file_key) line col in
  let%bind content = File_input.content_of_file_input file_input in
  let%bind ast_info = parse_contents ~options ~profiling content file_key in
  (* Start by running local variable find references *)
  let (ast, _, _) = ast_info in
  let scope_info = Scope_builder.program ~with_types:true ast in
  let (var_refs, loc) = local_variable_refs scope_info loc in
  (* Then run property find-refs *)
  let%bind prop_refs =
    PropertyFindRefs.find_local_refs
      ~reader
      ~options
      ~env
      ~profiling
      file_key
      ast_info
      scope_info
      loc
  in
  (* If property find-refs returned nothing (for example if we are importing from an untyped
     * module), then fall back on the local refs we computed earlier. *)
  let refs = Base.Option.first_some prop_refs var_refs in
  let refs = Base.Option.map ~f:(fun (name, refs) -> (name, sort_and_dedup refs)) refs in
  Ok refs
