(** [Cordis_core.Types] - Core types, lifecycle states, and exceptions for Cordis-OxCaml *)

type scope_id = int

type disposable = unit -> unit

type effect_token = {
  id : int;
  label : string;
  dispose : disposable;
}

type lifecycle_state =
  | Pending
  | Loading
  | Active
  | Failed of string
  | Disposed
  | Unloading
  | Quarantined of { reason : string; timestamp : float }

val string_of_lifecycle_state : lifecycle_state -> string

type event_dispatch_mode =
  | Emit
  | Serial
  | Bail
  | Waterfall
  | Parallel

val string_of_dispatch_mode : event_dispatch_mode -> string

type log_level =
  | Debug
  | Info
  | Warn
  | Error
  | Fatal

val string_of_log_level : log_level -> string

exception Inactive_scope of string
exception Cyclic_dependency of string list
exception Missing_service of string
exception Plugin_failure of string * string
exception Validation_error of string
