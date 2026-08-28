(* effect_handler.ml - Algebraic Effects Handler Implementation *)

open Effect
open Effect.Deep
open Types

type _ Effect.t +=
  | Transaction : (unit -> 'a) * (unit -> unit) -> 'a Effect.t
  | Rollback_Transaction : string -> unit Effect.t
  | Get_Coeffect : string -> Obj.t Effect.t

let perform_rollback msg =
  perform (Rollback_Transaction msg)

let request_coeffect (type a) (name : string) : a =
  Obj.magic (perform (Get_Coeffect name))

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
            | _ -> None) }
    in
    Ok res
  with exn ->
    List.iter (fun rb -> try rb () with _ -> ()) !rollbacks;
    Error (Printexc.to_string exn)
