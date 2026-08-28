(** [Cordis_core.Events] - Revertible Event Bus with Spatiotemporal Dispatch Modes *)

open Types

type 'a handler = 'a -> unit
type ('a, 'b) query_handler = 'a -> 'b option
type 'a transform_handler = 'a -> 'a

val on : Context.t -> string -> 'a handler -> disposable
val once : Context.t -> string -> 'a handler -> disposable
val on_query : Context.t -> string -> ('a, 'b) query_handler -> disposable
val on_transform : Context.t -> string -> 'a transform_handler -> disposable

(** Dispatching Methods *)
val emit : Context.t -> string -> 'a -> unit
val serial : Context.t -> string -> 'a -> 'b option
val bail : Context.t -> string -> 'a -> 'b option
val waterfall : Context.t -> string -> 'a -> 'a
val parallel_dispatch : Context.t -> string -> 'a -> unit

(** Introspection *)
val listener_count : string -> int
val clear_all_events : unit -> unit
