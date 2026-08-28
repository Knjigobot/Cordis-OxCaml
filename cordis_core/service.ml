(* service.ml - Dynamic Services Implementation *)

open Types

type service_info = {
  name : string;
  scope : Scope.t;
  instance : Obj.t;
}

let table : (string, service_info) Hashtbl.t = Hashtbl.create 32

let provide (ctx : Context.t) (service_name : string) (instance : 'a) : disposable =
  let sc = Context.scope ctx in
  Scope.assert_active sc;
  let info = {
    name = service_name;
    scope = sc;
    instance = Obj.repr instance;
  } in
  Hashtbl.replace table service_name info;
  Context.set_dynamic ctx ("service:" ^ service_name) instance;
  Events.emit ctx "internal/service" (service_name, `Started);

  let unprovide () =
    (match Hashtbl.find_opt table service_name with
     | Some current when current.scope.uid = sc.uid ->
       Hashtbl.remove table service_name;
       Context.remove_dynamic ctx ("service:" ^ service_name);
       Events.emit ctx "internal/service" (service_name, `Stopped)
     | _ -> ())
  in
  Scope.add_disposable sc unprovide

let get (ctx : Context.t) (service_name : string) : 'a option =
  match Hashtbl.find_opt table service_name with
  | Some info when Scope.is_active info.scope -> Some (Obj.magic info.instance)
  | _ ->
    (match Context.get_dynamic ctx ("service:" ^ service_name) with
     | Some inst -> Some inst
     | None -> None)

let get_exn (ctx : Context.t) (service_name : string) : 'a =
  match get ctx service_name with
  | Some s -> s
  | None -> raise (Missing_service service_name)

let has (ctx : Context.t) (service_name : string) : bool =
  match get ctx service_name with
  | Some _ -> true
  | None -> false

let remove (service_name : string) : unit =
  Hashtbl.remove table service_name

let list_services () : string list =
  Hashtbl.fold (fun name info acc ->
    if Scope.is_active info.scope then name :: acc else acc
  ) table []

let clear_all_services () : unit =
  Hashtbl.clear table
