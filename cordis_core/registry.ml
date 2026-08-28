(* registry.ml - Plugin System with Fault Isolation Implementation *)

open Types

module type PLUGIN = sig
  val name : string
  val version : string
  val inject : string list
  val on_init : Context.t -> unit
  val on_start : Context.t -> unit
  val on_stop : Context.t -> unit
  val on_dispose : Context.t -> unit
end

type plugin_entry = {
  plugin_module : (module PLUGIN);
  name : string;
  version : string;
  scope : Scope.t;
  ctx : Context.t;
  inject : string list;
  mutable error_count : int;
  mutable processed_events : int;
}

let table : (string, plugin_entry) Hashtbl.t = Hashtbl.create 32
let service_listener_registered = ref false

let check_dependencies (ctx : Context.t) (inject : string list) : bool =
  List.for_all (fun s_name -> Service.has ctx s_name) inject

let start_plugin_if_ready (entry : plugin_entry) : unit =
  let (module P) = entry.plugin_module in
  if entry.scope.state = Pending || entry.scope.state = Loading then begin
    if check_dependencies entry.ctx entry.inject then begin
      try
        entry.scope.state <- Active;
        P.on_start entry.ctx;
        Events.emit entry.ctx "internal/plugin_started" entry.name
      with exn ->
        entry.error_count <- entry.error_count + 1;
        let err_msg = Printexc.to_string exn in
        entry.scope.state <- Quarantined { reason = err_msg; timestamp = Unix.gettimeofday () };
        Events.emit entry.ctx "internal/quarantine" (entry.name, err_msg)
    end else begin
      entry.scope.state <- Pending
    end
  end

let stop_plugin (entry : plugin_entry) : unit =
  let (module P) = entry.plugin_module in
  if entry.scope.state = Active then begin
    (try P.on_stop entry.ctx with _ -> ());
    entry.scope.state <- Pending;
    Events.emit entry.ctx "internal/plugin_stopped" entry.name
  end

let ensure_service_listener (root_ctx : Context.t) =
  if not !service_listener_registered then begin
    service_listener_registered := true;
    ignore (Events.on root_ctx "internal/service" (fun (s_name, action) ->
      Hashtbl.iter (fun _ entry ->
        if List.mem s_name entry.inject then begin
          match action with
          | `Started -> start_plugin_if_ready entry
          | `Stopped -> stop_plugin entry
        end
      ) table
    ))
  end

let register (ctx : Context.t) (m : (module PLUGIN)) : disposable =
  let (module P) = m in
  let plugin_name = P.name in
  ensure_service_listener ctx;

  (* Create dedicated child scope for this plugin *)
  let plugin_scope = Scope.create ~parent:(Context.scope ctx) ~inject:P.inject plugin_name in
  let plugin_ctx = Context.create ~parent:ctx ~scope:plugin_scope plugin_name in

  let entry = {
    plugin_module = m;
    name = plugin_name;
    version = P.version;
    scope = plugin_scope;
    ctx = plugin_ctx;
    inject = P.inject;
    error_count = 0;
    processed_events = 0;
  } in
  Hashtbl.replace table plugin_name entry;

  (* Lifecycle: on_init *)
  (try
     P.on_init plugin_ctx
   with exn ->
     entry.error_count <- entry.error_count + 1;
     let err_msg = Printexc.to_string exn in
     plugin_scope.state <- Quarantined { reason = err_msg; timestamp = Unix.gettimeofday () };
     Events.emit ctx "internal/quarantine" (plugin_name, err_msg));

  (* Check if dependencies are fulfilled and start *)
  start_plugin_if_ready entry;

  let unregister_fn () =
    match Hashtbl.find_opt table plugin_name with
    | Some e when e.scope.uid = plugin_scope.uid ->
      stop_plugin e;
      (try P.on_dispose plugin_ctx with _ -> ());
      Scope.dispose plugin_scope;
      Hashtbl.remove table plugin_name
    | _ -> ()
  in
  Scope.add_disposable (Context.scope ctx) unregister_fn

let unregister (plugin_name : string) : unit =
  match Hashtbl.find_opt table plugin_name with
  | Some entry ->
    let (module P) = entry.plugin_module in
    stop_plugin entry;
    (try P.on_dispose entry.ctx with _ -> ());
    Scope.dispose entry.scope;
    Hashtbl.remove table plugin_name
  | None -> ()

let reload (ctx : Context.t) (m : (module PLUGIN)) : unit =
  let (module P) = m in
  unregister P.name;
  ignore (register ctx m)

let enable (plugin_name : string) : bool =
  match Hashtbl.find_opt table plugin_name with
  | Some entry ->
    if entry.scope.state <> Active then begin
      start_plugin_if_ready entry;
      true
    end else true
  | None -> false

let disable (plugin_name : string) : bool =
  match Hashtbl.find_opt table plugin_name with
  | Some entry ->
    stop_plugin entry;
    true
  | None -> false

let get_status (plugin_name : string) : lifecycle_state option =
  match Hashtbl.find_opt table plugin_name with
  | Some entry -> Some entry.scope.state
  | None -> None

let list_plugins () : (string * string * lifecycle_state * int) list =
  Hashtbl.fold (fun _ entry acc ->
    (entry.name, entry.version, entry.scope.state, entry.processed_events) :: acc
  ) table []

let clear_all_plugins () : unit =
  Hashtbl.iter (fun _ entry ->
    let (module P) = entry.plugin_module in
    (try P.on_stop entry.ctx with _ -> ());
    (try P.on_dispose entry.ctx with _ -> ());
    Scope.dispose entry.scope
  ) table;
  Hashtbl.clear table
