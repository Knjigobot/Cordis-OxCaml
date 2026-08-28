(* scope.ml - Hierarchical Scopes Implementation *)

open Types

type t = {
  uid : scope_id;
  name : string;
  parent : t option;
  mutable children : t list;
  mutable state : lifecycle_state;
  mutable disposables : disposable list;
  inject : string list;
}

let counter = ref 0

let next_uid () =
  incr counter;
  !counter

let root : t = {
  uid = 0;
  name = "root";
  parent = None;
  children = [];
  state = Active;
  disposables = [];
  inject = [];
}

let create ?(parent = root) ?(inject = []) name : t =
  let uid = next_uid () in
  let s = {
    uid;
    name;
    parent = Some parent;
    children = [];
    state = Pending;
    disposables = [];
    inject;
  } in
  parent.children <- s :: parent.children;
  s

let rec is_active (s : t) : bool =
  match s.state with
  | Active ->
    (match s.parent with
     | Some p -> is_active p
     | None -> true)
  | _ -> false

let assert_active (s : t) : unit =
  if not (is_active s) then
    raise (Inactive_scope (Printf.sprintf "Scope '%s' (uid=%d) is inactive (%s)" s.name s.uid (string_of_lifecycle_state s.state)))

let add_disposable (s : t) (d : disposable) : disposable =
  assert_active s;
  let executed = ref false in
  let wrapped () =
    if not !executed then begin
      executed := true;
      try d () with _ -> ()
    end
  in
  s.disposables <- wrapped :: s.disposables;
  wrapped

let add_effect (s : t) ?(label = "effect") (f : unit -> disposable) : disposable =
  assert_active s;
  let cleanup = try f () with exn ->
    raise (Plugin_failure (s.name, Printf.sprintf "Effect '%s' threw: %s" label (Printexc.to_string exn)))
  in
  add_disposable s cleanup

let rec dispose (s : t) : unit =
  if s.state <> Disposed then begin
    s.state <- Unloading;
    (* 1. First dispose all children in reverse *)
    List.iter dispose (List.rev s.children);
    s.children <- [];

    (* 2. Run all disposables in strict LIFO order *)
    let to_run = s.disposables in
    s.disposables <- [];
    List.iter (fun d -> try d () with _ -> ()) to_run;

    (* 3. Detach from parent *)
    (match s.parent with
     | Some p ->
       p.children <- List.filter (fun c -> c.uid <> s.uid) p.children
     | None -> ());

    s.state <- Disposed
  end

let set_state (s : t) (st : lifecycle_state) : unit =
  s.state <- st

let get_state (s : t) : lifecycle_state =
  s.state

let rec path (s : t) : string =
  match s.parent with
  | Some p -> path p ^ "." ^ s.name
  | None -> s.name

let list_children (s : t) : t list =
  s.children
