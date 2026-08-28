(** [Cordis_system.Timer] - Lifecycle-Bound Timers, Debouncers, and Intervals *)

open Cordis_core.Types
open Cordis_core

val timeout : Context.t -> float -> (unit -> unit) -> disposable
val interval : Context.t -> float -> (unit -> unit) -> disposable
val debounce : Context.t -> float -> ('a -> unit) -> ('a -> unit)
val throttle : Context.t -> float -> ('a -> unit) -> ('a -> unit)
val heartbeat : Context.t -> float -> (float -> unit) -> disposable

(** Manual step function for non-blocking single-threaded event loops *)
val tick : float -> unit
