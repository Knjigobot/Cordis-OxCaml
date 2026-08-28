(** [Cordis_core.Scope] - Hierarchical execution scopes, LIFO disposables, and lifecycle tracking *)

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

val root : t
val create : ?parent:t -> ?inject:string list -> string -> t
val add_disposable : t -> disposable -> disposable
val add_effect : t -> ?label:string -> (unit -> disposable) -> disposable
val dispose : t -> unit
val is_active : t -> bool
val assert_active : t -> unit
val set_state : t -> lifecycle_state -> unit
val get_state : t -> lifecycle_state
val path : t -> string
val list_children : t -> t list
