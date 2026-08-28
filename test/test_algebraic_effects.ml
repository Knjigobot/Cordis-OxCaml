(* test_algebraic_effects.ml - Algebraic Effect Transactions & Rollback Tests *)

open Cordis_core
open Cordis_core.Effect_handler

let run_tests () =
  Printf.printf "  [TEST] OCaml 5 Algebraic Effects & Transaction Rollback...\n";

  let state = ref 10 in
  let rollback_called = ref false in

  (* 1. Failed transaction should rollback *)
  let res = run_transaction (fun () ->
    Effect.perform (Transaction ((fun () -> state := 20), (fun () -> state := 10; rollback_called := true)));
    perform_rollback "Simulated invariant breach"
  ) in

  match res with
  | Ok _ -> failwith "Expected transaction to fail"
  | Error _ ->
    assert (!rollback_called = true);
    assert (!state = 10);

  Printf.printf "    ✓ Transaction rollback unwinding verified.\n"
