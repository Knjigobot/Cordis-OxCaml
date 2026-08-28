(* test_hmr.ml - In-Place Hot Module Replacement & Zero-Refresh Reconciler Tests *)

open Cordis_core
open Cordis_system

module Component_v1 = struct
  let name = "dynamic_component"
  let version = "1.0.0"
  let inject = []

  let render_count = ref 0

  let on_init _ = ()
  let on_start ctx =
    ignore (Events.on ctx "component/render" (fun () -> incr render_count))
  let on_stop _ = ()
  let on_dispose _ = render_count := 0
end

module Component_v2 = struct
  let name = "dynamic_component"
  let version = "2.0.0"
  let inject = []

  let render_count_v2 = ref 0

  let on_init _ = ()
  let on_start ctx =
    ignore (Events.on ctx "component/render" (fun () -> render_count_v2 := !render_count_v2 + 10))
  let on_stop _ = ()
  let on_dispose _ = ()
end

let run_tests () =
  Printf.printf "  [TEST] In-Place HMR Zero-Refresh Reconfiguration...\n";

  let ctx = Context.root in
  let hmr = Hmr.create ctx in
  Hmr.start hmr;

  (* 1. Register v1 *)
  ignore (Registry.register ctx (module Component_v1));
  Events.emit ctx "component/render" ();
  assert (!Component_v1.render_count = 1);

  (* 2. Hot-reload to v2 without process restart *)
  let reload_event_received = ref false in
  ignore (Events.on ctx "hmr/reload" (fun (_ev : Hmr.reload_event) ->
    reload_event_received := true
  ));

  Hmr.reload_plugin hmr (module Component_v2);

  assert (!reload_event_received = true);
  assert (Registry.get_status "dynamic_component" = Some Types.Active);

  (* 3. Emit render event -> should ONLY invoke v2 *)
  Events.emit ctx "component/render" ();
  assert (!Component_v1.render_count = 1); (* v1 listener was cleanly disposed! *)
  assert (!Component_v2.render_count_v2 = 10); (* v2 listener executed *)

  Printf.printf "    ✓ In-place plugin replacement verified.\n";
  Printf.printf "    ✓ Previous effect disposal (zero-leak) verified.\n";
  Printf.printf "    ✓ Hot-swapped listener execution verified.\n"
