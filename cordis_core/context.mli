(** [Cordis_core.Context] - Spatial Coeffect Context Manifold and Dynamic Environment *)

open Types

type 'a key = ..

type any_key = Key : 'a key -> any_key

type t

val root : t
val create : ?parent:t -> ?scope:Scope.t -> string -> t
val scope : t -> Scope.t
val name : t -> string

(** Typed GADT Coeffect Operations *)
val get : t -> 'a key -> 'a option
val get_exn : t -> 'a key -> 'a
val set : t -> 'a key -> 'a -> unit
val has : t -> 'a key -> bool
val remove : t -> 'a key -> unit
val with_binding : t -> 'a key -> 'a -> (unit -> 'b) -> 'b

(** Dynamic String Coeffect Operations *)
val get_dynamic : t -> string -> 'a option
val set_dynamic : t -> string -> 'a -> unit
val has_dynamic : t -> string -> bool
val remove_dynamic : t -> string -> unit

(** Revertible Effects & Scoped Lifecycles *)
val effect : t -> ?label:string -> (unit -> disposable) -> disposable
val defer : t -> disposable -> unit

(** Context Inheritance & Isolation *)
val extend : t -> ?name:string -> ?inject:string list -> unit -> t
val isolate : t -> string -> t
val is_isolated : t -> string -> bool

(** Reactive Subscriptions *)
val subscribe : t -> string -> ('a -> unit) -> disposable
val notify_subscribers : t -> string -> 'a -> unit
