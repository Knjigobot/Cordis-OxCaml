(* test_loader.ml - Declarative Loader & Reconciler Tests *)

open Cordis_core
open Cordis_system.Loader

module PluginA = struct
  let name = "plugin_a"
  let version = "1.0.0"
  let inject = []
  let on_init _ = ()
  let on_start _ = ()
  let on_stop _ = ()
  let on_dispose _ = ()
end

module PluginB = struct
  let name = "plugin_b"
  let version = "1.0.0"
  let inject = ["plugin_a"]
  let on_init _ = ()
  let on_start _ = ()
  let on_stop _ = ()
  let on_dispose _ = ()
end

let run_tests () =
  Printf.printf "  [TEST] Declarative Manifest Loader & Topological DAG...\n";

  let manifest : manifest = [
    { name = "plugin_b"; plugin = (module PluginB); enabled = true; config = Schema.Null };
    { name = "plugin_a"; plugin = (module PluginA); enabled = true; config = Schema.Null };
  ] in

  (* 1. Topological sort puts plugin_a before plugin_b *)
  match topological_sort manifest with
  | Error _ -> failwith "Topological sort failed"
  | Ok sorted ->
    assert (List.length sorted = 2);
    assert ((List.hd sorted).name = "plugin_a");
    assert ((List.nth sorted 1).name = "plugin_b");

  (* 2. Reconcile *)
  let loader = create Context.root in
  let res = reconcile loader manifest in
  assert (res = Ok ());
  assert (Registry.get_status "plugin_a" = Some Types.Active);

  Printf.printf "    ✓ DAG topological sorting verified.\n";
  Printf.printf "    ✓ Manifest reconciliation verified.\n"
