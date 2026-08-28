(* test_spatiotemporal.ml - Invariant tests for Spatiotemporal Composability *)

open Cordis_core

let run_tests () =
  Printf.printf "  [TEST] Spatiotemporal Invariants & Reversibility...\n";

  (* Test 1: LIFO disposal order *)
  let execution_order = ref [] in
  let root_scope = Scope.root in
  let child = Scope.create ~parent:root_scope "test_child" in
  child.state <- Active;

  ignore (Scope.add_disposable child (fun () -> execution_order := 1 :: !execution_order));
  ignore (Scope.add_disposable child (fun () -> execution_order := 2 :: !execution_order));
  ignore (Scope.add_disposable child (fun () -> execution_order := 3 :: !execution_order));

  Scope.dispose child;

  (* Because it adds 1, then 2, then 3, LIFO unwinding runs 3 first, then 2, then 1 *)
  (* When prepending to execution_order: 3 runs -> [3], 2 runs -> [2; 3], 1 runs -> [1; 2; 3] *)
  assert (!execution_order = [1; 2; 3]);
  assert (Scope.get_state child = Disposed);
  assert (not (Scope.is_active child));

  (* Test 2: Cascading child disposal *)
  let parent_scope = Scope.create ~parent:root_scope "parent" in
  parent_scope.state <- Active;
  let child_scope = Scope.create ~parent:parent_scope "nested_child" in
  child_scope.state <- Active;

  let child_cleaned = ref false in
  ignore (Scope.add_disposable child_scope (fun () -> child_cleaned := true));

  Scope.dispose parent_scope;
  assert (!child_cleaned = true);
  assert (Scope.get_state child_scope = Disposed);

  (* Test 3: Inactive scope assertion *)
  let threw = ref false in
  (try
     ignore (Scope.add_disposable child (fun () -> ()))
   with Inactive_scope _ -> threw := true);
  assert (!threw = true);

  Printf.printf "    ✓ LIFO unwinding order verified.\n";
  Printf.printf "    ✓ Cascading subtree disposal verified.\n";
  Printf.printf "    ✓ Inactive scope boundary assertions verified.\n"
