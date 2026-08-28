(* types.ml - Core Types Implementation *)

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

let string_of_lifecycle_state = function
  | Pending -> "Pending"
  | Loading -> "Loading"
  | Active -> "Active"
  | Failed msg -> "Failed: " ^ msg
  | Disposed -> "Disposed"
  | Unloading -> "Unloading"
  | Quarantined q -> Printf.sprintf "Quarantined(at=%.3f, reason=%s)" q.timestamp q.reason

type event_dispatch_mode =
  | Emit
  | Serial
  | Bail
  | Waterfall
  | Parallel

let string_of_dispatch_mode = function
  | Emit -> "emit"
  | Serial -> "serial"
  | Bail -> "bail"
  | Waterfall -> "waterfall"
  | Parallel -> "parallel"

type log_level =
  | Debug
  | Info
  | Warn
  | Error
  | Fatal

let string_of_log_level = function
  | Debug -> "DEBUG"
  | Info -> "INFO"
  | Warn -> "WARN"
  | Error -> "ERROR"
  | Fatal -> "FATAL"

exception Inactive_scope of string
exception Cyclic_dependency of string list
exception Missing_service of string
exception Plugin_failure of string * string
exception Validation_error of string
