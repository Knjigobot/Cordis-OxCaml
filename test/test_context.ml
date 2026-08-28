(* test_context.ml - Context Manifold & Spatial Coeffects Tests *)

open Cordis_core

type _ Context.key +=
  | StringKey : string Context.key
  | IntKey : int Context.key
  | FloatKey : float Context.key

let run_tests () =
  Printf.printf "  [TEST] Context Manifold & Spatial Coeffects...\n";

  let ctx = Context.create "test_context" in
  (Context.scope ctx).state <- Active;

  (* 1. GADT Key Storage *)
  Context.set ctx StringKey "hello_cordis";
  Context.set ctx IntKey 42;
  Context.set ctx FloatKey 3.14159;

  assert (Context.get ctx StringKey = Some "hello_cordis");
  assert (Context.get ctx IntKey = Some 42);
  assert (Context.get ctx FloatKey = Some 3.14159);
  assert (Context.has ctx StringKey);

  (* 2. Dynamic extent with_binding *)
  let result = Context.with_binding ctx StringKey "temporary_override" (fun () ->
    assert (Context.get ctx StringKey = Some "temporary_override");
    100
  ) in
  assert (result = 100);
  assert (Context.get ctx StringKey = Some "hello_cordis");

  (* 3. Context Shadowing *)
  let child_ctx = Context.extend ctx ~name:"child_ctx" () in
  (Context.scope child_ctx).state <- Active;
  assert (Context.get child_ctx StringKey = Some "hello_cordis");

  Context.set child_ctx StringKey "shadowed_value";
  assert (Context.get child_ctx StringKey = Some "shadowed_value");
  assert (Context.get ctx StringKey = Some "hello_cordis");

  (* 4. Isolation *)
  let iso_ctx = Context.isolate ctx "database" in
  assert (Context.is_isolated iso_ctx "database");
  assert (not (Context.is_isolated ctx "database"));

  (* 5. Reactive Subscriptions *)
  let observed_val = ref "" in
  let un_sub = Context.subscribe ctx "ticker" (fun v -> observed_val := v) in
  Context.set_dynamic ctx "ticker" "BTC-USD";
  assert (!observed_val = "BTC-USD");

  un_sub ();
  Context.set_dynamic ctx "ticker" "ETH-USD";
  assert (!observed_val = "BTC-USD"); (* Still old value, unsubscribed *)

  Printf.printf "    ✓ Typed GADT coeffect storage verified.\n";
  Printf.printf "    ✓ Dynamic with_binding scope rollback verified.\n";
  Printf.printf "    ✓ Context inheritance and shadowing verified.\n";
  Printf.printf "    ✓ Reactive subscriber notifications verified.\n"
