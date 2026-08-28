(** [Cordis_core.Registry] - First-Class Module Plugin System with Fault Isolation *)

open Types

module type PLUGIN = sig
  val name : string
  val version : string
  val inject : string list
  val on_init : Context.t -> unit
  val on_start : Context.t -> unit
  val on_stop : Context.t -> unit
  val on_dispose : Context.t -> unit
end

type plugin_entry = {
  plugin_module : (module PLUGIN);
  name : string;
  version : string;
  scope : Scope.t;
  ctx : Context.t;
  inject : string list;
  mutable error_count : int;
  mutable processed_events : int;
}

val register : Context.t -> (module PLUGIN) -> disposable
val unregister : string -> unit
val reload : Context.t -> (module PLUGIN) -> unit
val enable : string -> bool
val disable : string -> bool
val get_status : string -> lifecycle_state option
val list_plugins : unit -> (string * string * lifecycle_state * int) list
val clear_all_plugins : unit -> unit
