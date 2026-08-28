(* effect_handler.ml - Algebraic Effects Handler Implementation *)

open Effect
open Effect.Deep
open Types

type _ Effect.t +=
  | Transaction : (unit -> 'a) * (unit -> unit) -> 'a Effect.t
  | Rollback_Transaction : string -> unit Effect.t
  | Get_Coeffect : string -> Obj.t Effect.t
  | Broadcast_Manifold_Delta : string * Obj.t -> unit Effect.t
  | Hot_Reload_Plugin : string * (module Registry.PLUGIN) -> unit Effect.t

let perform_rollback msg =
  perform (Rollback_Transaction msg)

let request_coeffect (type a) (name : string) : a =
  Obj.magic (perform (Get_Coeffect name))

let broadcast_delta (type a) (key : string) (value : a) : unit =
  perform (Broadcast_Manifold_Delta (key, Obj.repr value))

let hot_swap_plugin (id : string) (m : (module Registry.PLUGIN)) : unit =
  perform (Hot_Reload_Plugin (id, m))

let run_transaction (f : unit -> 'a) : ('a, string) result =
  let rollbacks = ref [] in
  try
    let res =
      try_with f ()
        { effc = (fun (type c) (eff : c Effect.t) ->
            match eff with
            | Transaction (action, rollback_fn) ->
              Some (fun (k : (c, _) continuation) ->
                rollbacks := rollback_fn :: !rollbacks;
                let r = action () in
                continue k r)
            | Rollback_Transaction reason ->
              Some (fun (_k : (c, _) continuation) ->
                List.iter (fun rb -> try rb () with _ -> ()) !rollbacks;
                failwith ("Transaction rolled back: " ^ reason))
            | Get_Coeffect name ->
              Some (fun (k : (c, _) continuation) ->
                match Service.get Context.root name with
                | Some inst -> continue k (Obj.repr inst)
                | None -> failwith ("Coeffect not found: " ^ name))
            | Broadcast_Manifold_Delta (k_name, v_obj) ->
              Some (fun (k : (c, _) continuation) ->
                Context.notify_subscribers Context.root k_name v_obj;
                continue k ())
            | Hot_Reload_Plugin (_p_id, p_mod) ->
              Some (fun (k : (c, _) continuation) ->
                Registry.reload Context.root p_mod;
                continue k ())
            | _ -> None) }
    in
    Ok res
  with exn ->
    List.iter (fun rb -> try rb () with _ -> ()) !rollbacks;
    Error (Printexc.to_string exn)
