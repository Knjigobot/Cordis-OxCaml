(** [Cordis_system.Http_server] - Zero-Dependency Native HTTP 1.1 & SSE Live Sync Daemon *)

open Cordis_core.Types
open Cordis_core

type t

val create : ?host:string -> ?port:int -> ?static_dir:string -> Context.t -> t

val start : t -> unit
val stop : t -> unit
val broadcast_sse : t -> string -> unit
val is_running : t -> bool
val port : t -> int
