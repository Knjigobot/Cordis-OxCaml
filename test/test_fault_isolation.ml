(* test_fault_isolation.ml - Sandbox Fault Isolation Tests *)

open Cordis_core

let run_tests () =
  Printf.printf "  [TEST] Plugin Sandboxing & Fault Isolation...\n";

  let root_ctx = Context.root in

  let module BrokenPlugin = struct
    let name = "faulty_crawler"
    let version = "0.9.0"
    let inject = []

    let on_init (_ctx : Context.t) = ()
    let on_start (_ctx : Context.t) =
      failwith "Unexpected network timeout / corrupted memory segment"
    let on_stop (_ctx : Context.t) = ()
    let on_dispose (_ctx : Context.t) = ()
  end in

  (* Register faulty plugin *)
  let quarantine_event_received = ref false in
  ignore (Events.on root_ctx "internal/quarantine" (fun (p_name, _reason) ->
    if p_name = "faulty_crawler" then quarantine_event_received := true
  ));

  let disp_faulty = Registry.register root_ctx (module BrokenPlugin) in

  (* Engine should catch the exception and mark plugin as Quarantined *)
  assert (!quarantine_event_received = true);
  match Registry.get_status "faulty_crawler" with
  | Some (Types.Quarantined q) ->
    assert (String.length q.reason > 0);
    assert (q.timestamp > 0.0)
  | _ -> failwith "Expected plugin to be in Quarantined state";

  disp_faulty ();

  Printf.printf "    ✓ Uncaught exception caught without kernel panic.\n";
  Printf.printf "    ✓ Quarantine transition & diagnostic telemetry verified.\n"
