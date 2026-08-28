(** [Cordis_core.Effect_handler] - OCaml 5 Algebraic Effects Handler for Spatiotemporal Transactions *)

open Types

type _ Effect.t +=
  | Transaction : (unit -> 'a) * (unit -> unit) -> 'a Effect.t
  | Rollback_Transaction : string -> unit Effect.t
  | Get_Coeffect : string -> Obj.t Effect.t
  | Broadcast_Manifold_Delta : string * Obj.t -> unit Effect.t
  | Hot_Reload_Plugin : string * (module Registry.PLUGIN) -> unit Effect.t

val run_transaction : (unit -> 'a) -> ('a, string) result
val perform_rollback : string -> unit
val request_coeffect : string -> 'a
val broadcast_delta : string -> 'a -> unit
val hot_swap_plugin : string -> (module Registry.PLUGIN) -> unit
