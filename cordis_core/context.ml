(* context.ml - Spatial Coeffect Context Implementation *)

open Types

type 'a key = ..

type any_key = Key : 'a key -> any_key

type subscriber_entry = {
  sub_id : int;
  callback : Obj.t -> unit;
}

type t = {
  scope : Scope.t;
  name : string;
  parent : t option;
  bindings : (any_key, Obj.t) Hashtbl.t;
  dynamic_store : (string, Obj.t) Hashtbl.t;
  isolated_namespaces : (string, string) Hashtbl.t;
  subscribers : (string, subscriber_entry list ref) Hashtbl.t;
}

let root_scope = Scope.root

let root : t = {
  scope = root_scope;
  name = "root";
  parent = None;
  bindings = Hashtbl.create 64;
  dynamic_store = Hashtbl.create 64;
  isolated_namespaces = Hashtbl.create 16;
  subscribers = Hashtbl.create 32;
}

let create ?parent ?scope name : t =
  let p = match parent with Some p -> p | None -> root in
  let sc = match scope with
    | Some s -> s
    | None -> Scope.create ~parent:p.scope name
  in
  {
    scope = sc;
    name;
    parent = Some p;
    bindings = Hashtbl.create 32;
    dynamic_store = Hashtbl.create 32;
    isolated_namespaces = Hashtbl.create 8;
    subscribers = Hashtbl.create 16;
  }

let scope (ctx : t) : Scope.t = ctx.scope
let name (ctx : t) : string = ctx.name

let rec get : type a. t -> a key -> a option =
  fun ctx k ->
    match Hashtbl.find_opt ctx.bindings (Key k) with
    | Some v -> Some (Obj.magic v)
    | None ->
      (match ctx.parent with
       | Some p -> get p k
       | None -> None)

let get_exn (type a) (ctx : t) (k : a key) : a =
  match get ctx k with
  | Some v -> v
  | None -> raise (Not_found)

let notify_subscribers (ctx : t) (key_name : string) (value : 'a) : unit =
  let rec notify_up c =
    (match Hashtbl.find_opt c.subscribers key_name with
     | Some subs_ref ->
       List.iter (fun entry ->
         try entry.callback (Obj.repr value) with _ -> ()
       ) !subs_ref
     | None -> ());
    match c.parent with
    | Some p -> notify_up p
    | None -> ()
  in
  notify_up ctx

let set (type a) (ctx : t) (k : a key) (v : a) : unit =
  Scope.assert_active ctx.scope;
  Hashtbl.replace ctx.bindings (Key k) (Obj.repr v)

let rec has : type a. t -> a key -> bool =
  fun ctx k ->
    if Hashtbl.mem ctx.bindings (Key k) then true
    else match ctx.parent with
      | Some p -> has p k
      | None -> false

let remove (type a) (ctx : t) (k : a key) : unit =
  Hashtbl.remove ctx.bindings (Key k)

let with_binding (type a b) (ctx : t) (k : a key) (v : a) (f : unit -> b) : b =
  let prev_val = get ctx k in
  set ctx k v;
  Fun.protect ~finally:(fun () ->
    match prev_val with
    | Some pv -> set ctx k pv
    | None -> remove ctx k
  ) f

let rec get_dynamic (ctx : t) (k : string) : 'a option =
  match Hashtbl.find_opt ctx.dynamic_store k with
  | Some v -> Some (Obj.magic v)
  | None ->
    (match ctx.parent with
     | Some p -> get_dynamic p k
     | None -> None)

let set_dynamic (ctx : t) (k : string) (v : 'a) : unit =
  Scope.assert_active ctx.scope;
  Hashtbl.replace ctx.dynamic_store k (Obj.repr v);
  notify_subscribers ctx k v

let rec has_dynamic (ctx : t) (k : string) : bool =
  if Hashtbl.mem ctx.dynamic_store k then true
  else match ctx.parent with
    | Some p -> has_dynamic p k
    | None -> false

let remove_dynamic (ctx : t) (k : string) : unit =
  Hashtbl.remove ctx.dynamic_store k

let effect (ctx : t) ?(label = "effect") (f : unit -> disposable) : disposable =
  Scope.add_effect ctx.scope ~label f

let defer (ctx : t) (d : disposable) : unit =
  ignore (Scope.add_disposable ctx.scope d)

let extend (ctx : t) ?name ?(inject = []) () : t =
  let n = match name with Some s -> s | None -> ctx.name ^ ".child" in
  let sc = Scope.create ~parent:ctx.scope ~inject n in
  create ~parent:ctx ~scope:sc n

let isolate (ctx : t) (ns : string) : t =
  let child = extend ctx ~name:(ctx.name ^ ".iso(" ^ ns ^ ")") () in
  let tag = Printf.sprintf "iso_%s_%d" ns (Scope.next_uid ()) in
  Hashtbl.replace child.isolated_namespaces ns tag;
  child

let is_isolated (ctx : t) (ns : string) : bool =
  Hashtbl.mem ctx.isolated_namespaces ns

let sub_counter = ref 0

let subscribe (ctx : t) (key_name : string) (callback : 'a -> unit) : disposable =
  Scope.assert_active ctx.scope;
  incr sub_counter;
  let sid = !sub_counter in
  let subs_ref = match Hashtbl.find_opt ctx.subscribers key_name with
    | Some r -> r
    | None ->
      let r = ref [] in
      Hashtbl.add ctx.subscribers key_name r;
      r
  in
  let entry = { sub_id = sid; callback = (fun obj -> callback (Obj.magic obj)) } in
  subs_ref := entry :: !subs_ref;
  let unsubscribe () =
    subs_ref := List.filter (fun e -> e.sub_id <> sid) !subs_ref
  in
  Scope.add_disposable ctx.scope unsubscribe
