(* loader.ml - Declarative Plugin Manifest & Dynamic Dependency Reconciler Implementation *)

open Cordis_core.Types
open Cordis_core

type plugin_spec = {
  name : string;
  plugin : (module Registry.PLUGIN);
  enabled : bool;
  config : Schema.json_value;
}

type manifest = plugin_spec list

type t = {
  ctx : Context.t;
  mutable active_manifest : manifest;
}

let create (ctx : Context.t) : t =
  let loader_scope = Scope.create ~parent:(Context.scope ctx) "loader" in
  let loader_ctx = Context.create ~parent:ctx ~scope:loader_scope "loader" in
  { ctx = loader_ctx; active_manifest = [] }

let topological_sort (specs : manifest) : (manifest, string list) result =
  let spec_map = Hashtbl.create 16 in
  List.iter (fun s -> Hashtbl.add spec_map s.name s) specs;

  let visited = Hashtbl.create 16 in
  let rec_stack = Hashtbl.create 16 in
  let result = ref [] in
  let cycle_found = ref None in

  let rec dfs name path =
    if Hashtbl.mem rec_stack name then begin
      cycle_found := Some (List.rev (name :: path));
      false
    end else if not (Hashtbl.mem visited name) then begin
      Hashtbl.add visited name true;
      Hashtbl.add rec_stack name true;
      match Hashtbl.find_opt spec_map name with
      | Some spec ->
        let (module P) = spec.plugin in
        let ok = List.for_all (fun dep ->
          if Hashtbl.mem spec_map dep then dfs dep (name :: path)
          else true (* external service *)
        ) P.inject in
        Hashtbl.remove rec_stack name;
        if ok then begin
          result := spec :: !result;
          true
        end else false
      | None ->
        Hashtbl.remove rec_stack name;
        true
    end else true
  in

  let all_ok = List.for_all (fun s ->
    if not (Hashtbl.mem visited s.name) then dfs s.name [] else true
  ) specs in

  if all_ok then Ok (List.rev !result)
  else match !cycle_found with
    | Some cycle -> Error cycle
    | None -> Error ["Unknown cycle"]

let reconcile (l : t) (target : manifest) : (unit, string) result =
  match topological_sort target with
  | Error cycle -> Error (Printf.sprintf "Cyclic plugin dependency detected: %s" (String.concat " -> " cycle))
  | Ok sorted_target ->
    let current_map = Hashtbl.create 16 in
    List.iter (fun s -> Hashtbl.add current_map s.name s) l.active_manifest;

    let target_map = Hashtbl.create 16 in
    List.iter (fun s -> Hashtbl.add target_map s.name s) sorted_target;

    (* 1. Unregister plugins that were removed or disabled *)
    List.iter (fun cur ->
      match Hashtbl.find_opt target_map cur.name with
      | None ->
        Registry.unregister cur.name;
        Events.emit l.ctx "loader/unloaded" cur.name
      | Some tgt when not tgt.enabled && cur.enabled ->
        Registry.unregister cur.name;
        Events.emit l.ctx "loader/disabled" cur.name
      | _ -> ()
    ) l.active_manifest;

    (* 2. Register or reload plugins in topological order *)
    List.iter (fun tgt ->
      if tgt.enabled then begin
        match Hashtbl.find_opt current_map tgt.name with
        | None ->
          ignore (Registry.register l.ctx tgt.plugin);
          Events.emit l.ctx "loader/loaded" tgt.name
        | Some cur when not cur.enabled ->
          ignore (Registry.register l.ctx tgt.plugin);
          Events.emit l.ctx "loader/enabled" tgt.name
        | Some _ -> ()
      end
    ) sorted_target;

    l.active_manifest <- sorted_target;
    Events.emit l.ctx "loader/reconcile_done" ();
    Ok ()

let current_manifest (l : t) : manifest = l.active_manifest
