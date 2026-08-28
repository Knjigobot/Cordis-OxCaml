(* test_lifecycle.ml - Dependency Injection & Dynamic Lifecycle Tests *)

open Cordis_core

let run_tests () =
  Printf.printf "  [TEST] Dynamic Dependency Injection & Lifecycles...\n";

  let root_ctx = Context.root in

  (* Define a plugin that requires the "database" service *)
  let plugin_started = ref false in
  let plugin_stopped = ref false in

  let module DependentPlugin = struct
    let name = "analytics_service"
    let version = "1.0.0"
    let inject = ["database"]

    let on_init (_ctx : Context.t) = ()
    let on_start (_ctx : Context.t) = plugin_started := true
    let on_stop (_ctx : Context.t) = plugin_stopped := true
    let on_dispose (_ctx : Context.t) = ()
  end in

  (* 1. Register plugin before database service exists -> stays Pending *)
  let disp_plugin = Registry.register root_ctx (module DependentPlugin) in
  assert (!plugin_started = false);
  assert (Registry.get_status "analytics_service" = Some Types.Pending);

  (* 2. Provide "database" service -> plugin dynamically activates *)
  let disp_db = Service.provide root_ctx "database" "db_connection_pool" in
  assert (!plugin_started = true);
  assert (Registry.get_status "analytics_service" = Some Types.Active);

  (* 3. Remove "database" service -> plugin dynamically pauses (on_stop) *)
  disp_db ();
  assert (!plugin_stopped = true);
  assert (Registry.get_status "analytics_service" = Some Types.Pending);

  (* 4. Provide "database" service again -> plugin re-activates *)
  plugin_started := false;
  let disp_db2 = Service.provide root_ctx "database" "db_connection_pool_v2" in
  assert (!plugin_started = true);
  assert (Registry.get_status "analytics_service" = Some Types.Active);

  (* Clean up *)
  disp_db2 ();
  disp_plugin ();

  Printf.printf "    ✓ Dependency-gated startup verified.\n";
  Printf.printf "    ✓ Reactive pause/resume upon service state changes verified.\n"
