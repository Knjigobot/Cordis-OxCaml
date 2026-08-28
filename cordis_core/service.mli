(** [Cordis_core.Service] - Dynamic Services and Capability Registry *)

open Types

type service_info = {
  name : string;
  scope : Scope.t;
  instance : Obj.t;
}

val provide : Context.t -> string -> 'a -> disposable
val get : Context.t -> string -> 'a option
val get_exn : Context.t -> string -> 'a
val has : Context.t -> string -> bool
val remove : string -> unit
val list_services : unit -> string list
val clear_all_services : unit -> unit
