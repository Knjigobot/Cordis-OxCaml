(* test_events.ml - Revertible Event Bus Tests *)

open Cordis_core

let run_tests () =
  Printf.printf "  [TEST] Revertible Event Bus & Dispatch Modes...\n";

  let ctx = Context.create "event_test_ctx" in
  (Context.scope ctx).state <- Active;

  (* 1. Emit mode *)
  let count = ref 0 in
  let unreg1 = Events.on ctx "custom/ping" (fun () -> incr count) in
  let unreg2 = Events.on ctx "custom/ping" (fun () -> incr count) in
  Events.emit ctx "custom/ping" ();
  assert (!count = 2);

  unreg1 ();
  Events.emit ctx "custom/ping" ();
  assert (!count = 3);
  unreg2 ();

  (* 2. Once mode *)
  let once_count = ref 0 in
  ignore (Events.once ctx "custom/once" (fun () -> incr once_count));
  Events.emit ctx "custom/once" ();
  Events.emit ctx "custom/once" ();
  assert (!once_count = 1);

  (* 3. Bail / Serial mode *)
  ignore (Events.on_query ctx "custom/query" (fun (x : int) -> if x < 10 then None else Some (x * 2)));
  ignore (Events.on_query ctx "custom/query" (fun (x : int) -> Some (x + 5)));

  let res1 = Events.bail ctx "custom/query" 15 in
  assert (res1 = Some 30);
  let res2 = Events.bail ctx "custom/query" 4 in
  assert (res2 = Some 9);

  (* 4. Waterfall pipeline mode *)
  ignore (Events.on_transform ctx "custom/pipe" (fun (x : int) -> x + 10));
  ignore (Events.on_transform ctx "custom/pipe" (fun (x : int) -> x * 2));
  let final_val = Events.waterfall ctx "custom/pipe" 5 in
  (* (5 + 10) * 2 = 30 *)
  assert (final_val = 30);

  (* 5. Automatic cleanup on scope disposal *)
  let sub_scope = Scope.create ~parent:(Context.scope ctx) "sub_event" in
  sub_scope.state <- Active;
  let sub_ctx = Context.create ~parent:ctx ~scope:sub_scope "sub_ctx" in

  let sub_fired = ref false in
  ignore (Events.on sub_ctx "scoped/event" (fun () -> sub_fired := true));
  Events.emit ctx "scoped/event" ();
  assert (!sub_fired = true);

  sub_fired := false;
  Scope.dispose sub_scope;
  Events.emit ctx "scoped/event" ();
  assert (!sub_fired = false);

  Printf.printf "    ✓ Emit, Once, Bail, and Waterfall modes verified.\n";
  Printf.printf "    ✓ Automatic unregistration upon scope disposal verified.\n"
