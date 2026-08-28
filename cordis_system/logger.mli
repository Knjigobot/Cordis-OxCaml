(** [Cordis_system.Logger] - Structured Leveled Logger with Scope Hierarchy *)

open Cordis_core.Types
open Cordis_core

type t

val create : ?min_level:log_level -> ?use_json:bool -> Context.t -> t

val debug : t -> ('a, unit, string, unit) format4 -> 'a
val info : t -> ('a, unit, string, unit) format4 -> 'a
val warn : t -> ('a, unit, string, unit) format4 -> 'a
val error : t -> ('a, unit, string, unit) format4 -> 'a
val fatal : t -> ('a, unit, string, unit) format4 -> 'a

val set_min_level : t -> log_level -> unit
val set_use_json : t -> bool -> unit
