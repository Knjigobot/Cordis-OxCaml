(** [Cordis_system.Hmr] - Hot Module Replacement & Zero-Refresh In-Place State Reconciler *)

open Cordis_core.Types
open Cordis_core

type reload_event = {
  module_name : string;
  filename : string option;
  timestamp : float;
}

type t

val create : ?base_dir:string -> ?debounce_sec:float -> Context.t -> t

val start : t -> unit
val stop : t -> unit

val reload_plugin : t -> (module Registry.PLUGIN) -> unit
val notify_change : t -> ?filename:string -> string -> unit

val is_watching : t -> bool
