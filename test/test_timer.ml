(* test_timer.ml - Lifecycle-Bound Timers Tests *)

open Cordis_core
open Cordis_system.Timer

let run_tests () =
  Printf.printf "  [TEST] Lifecycle-Bound Timers & Auto-Cancellation...\n";

  let ctx = Context.create "timer_test" in
  (Context.scope ctx).state <- Active;

  (* 1. Manual Timeout step *)
  let fired = ref false in
  ignore (timeout ctx 1.0 (fun () -> fired := true));

  let t0 = Unix.gettimeofday () in
  tick (t0 +. 0.5);
  assert (!fired = false);

  tick (t0 +. 1.1);
  assert (!fired = true);

  (* 2. Auto-cancellation upon scope disposal *)
  let sub_ctx = Context.extend ctx ~name:"sub_timer" () in
  (Context.scope sub_ctx).state <- Active;

  let sub_fired = ref false in
  ignore (timeout sub_ctx 1.0 (fun () -> sub_fired := true));

  (* Dispose scope before timeout triggers *)
  Scope.dispose (Context.scope sub_ctx);

  tick (t0 +. 2.5);
  assert (!sub_fired = false); (* Cancelled automatically! *)

  Printf.printf "    ✓ Delay threshold triggering verified.\n";
  Printf.printf "    ✓ Auto-cancellation on scope disposal verified.\n"
