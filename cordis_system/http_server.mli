(** [Cordis_system.Http_server] - Dual-Channel Native HTTP 1.1 & SSE Live-Sync Daemon *)

open Cordis_core.Types
open Cordis_core

type t

val create : ?host:string -> ?port:int -> ?static_dir:string -> Context.t -> t

val start : t -> unit
val stop : t -> unit
val broadcast_sse : t -> string -> unit
val bump_version : t -> unit
val current_version : t -> float
val is_running : t -> bool
val port : t -> int
