(* events.ml - Revertible Event Bus Implementation *)

open Types

type 'a handler = 'a -> unit
type ('a, 'b) query_handler = 'a -> 'b option
type 'a transform_handler = 'a -> 'a

type listener_entry = {
  id : int;
  scope : Scope.t;
  callback : Obj.t -> Obj.t option;
  is_once : bool;
}

let counter = ref 0
let registry : (string, listener_entry list ref) Hashtbl.t = Hashtbl.create 64

let get_listeners_ref (event_name : string) =
  match Hashtbl.find_opt registry event_name with
  | Some r -> r
  | None ->
    let r = ref [] in
    Hashtbl.add registry event_name r;
    r

let register_raw (ctx : Context.t) (event_name : string) (cb : Obj.t -> Obj.t option) (is_once : bool) : disposable =
  let sc = Context.scope ctx in
  Scope.assert_active sc;
  incr counter;
  let lid = !counter in
  let listeners = get_listeners_ref event_name in
  let entry = {
    id = lid;
    scope = sc;
    callback = cb;
    is_once;
  } in
  listeners := entry :: !listeners;

  let unregister () =
    listeners := List.filter (fun e -> e.id <> lid) !listeners
  in
  Scope.add_disposable sc unregister

let on (ctx : Context.t) (event_name : string) (h : 'a handler) : disposable =
  register_raw ctx event_name (fun obj ->
    h (Obj.magic obj);
    None
  ) false

let once (ctx : Context.t) (event_name : string) (h : 'a handler) : disposable =
  register_raw ctx event_name (fun obj ->
    h (Obj.magic obj);
    None
  ) true

let on_query (ctx : Context.t) (event_name : string) (h : ('a, 'b) query_handler) : disposable =
  register_raw ctx event_name (fun obj ->
    match h (Obj.magic obj) with
    | Some res -> Some (Obj.repr res)
    | None -> None
  ) false

let on_transform (ctx : Context.t) (event_name : string) (h : 'a transform_handler) : disposable =
  register_raw ctx event_name (fun obj ->
    let updated = h (Obj.magic obj) in
    Some (Obj.repr updated)
  ) false

let emit (ctx : Context.t) (event_name : string) (payload : 'a) : unit =
  let listeners = get_listeners_ref event_name in
  let active = List.filter (fun e -> Scope.is_active e.scope) !listeners in
  let to_remove = ref [] in
  List.iter (fun entry ->
    (try ignore (entry.callback (Obj.repr payload)) with _ -> ());
    if entry.is_once then to_remove := entry.id :: !to_remove
  ) (List.rev active);
  if !to_remove <> [] then
    listeners := List.filter (fun e -> not (List.mem e.id !to_remove)) !listeners

let serial (ctx : Context.t) (event_name : string) (payload : 'a) : 'b option =
  let listeners = get_listeners_ref event_name in
  let active = List.filter (fun e -> Scope.is_active e.scope) !listeners in
  let to_remove = ref [] in
  let rec loop = function
    | [] -> None
    | entry :: rest ->
      if entry.is_once then to_remove := entry.id :: !to_remove;
      let res = try entry.callback (Obj.repr payload) with _ -> None in
      match res with
      | Some v -> Some (Obj.magic v)
      | None -> loop rest
  in
  let result = loop (List.rev active) in
  if !to_remove <> [] then
    listeners := List.filter (fun e -> not (List.mem e.id !to_remove)) !listeners;
  result

let bail (ctx : Context.t) (event_name : string) (payload : 'a) : 'b option =
  serial ctx event_name payload

let waterfall (ctx : Context.t) (event_name : string) (initial_payload : 'a) : 'a =
  let listeners = get_listeners_ref event_name in
  let active = List.filter (fun e -> Scope.is_active e.scope) !listeners in
  let to_remove = ref [] in
  let current = ref (Obj.repr initial_payload) in
  List.iter (fun entry ->
    if entry.is_once then to_remove := entry.id :: !to_remove;
    match try entry.callback !current with _ -> None with
    | Some updated -> current := updated
    | None -> ()
  ) (List.rev active);
  if !to_remove <> [] then
    listeners := List.filter (fun e -> not (List.mem e.id !to_remove)) !listeners;
  Obj.magic !current

let parallel_dispatch (ctx : Context.t) (event_name : string) (payload : 'a) : unit =
  emit ctx event_name payload

let listener_count (event_name : string) : int =
  match Hashtbl.find_opt registry event_name with
  | Some r -> List.length (List.filter (fun e -> Scope.is_active e.scope) !r)
  | None -> 0

let clear_all_events () : unit =
  Hashtbl.clear registry
