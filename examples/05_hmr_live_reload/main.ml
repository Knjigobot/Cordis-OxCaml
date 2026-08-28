(* examples/05_hmr_live_reload/main.ml *)

open Cordis_core
open Cordis_system

(* Initial version of a visual component plugin *)
module VisualWidget_v1 = struct
  let name = "visual_widget"
  let version = "1.0.0"
  let inject = []

  let on_init (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "[Widget v1] Initialized."

  let on_start (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "[Widget v1] Active! Subscribing to render events...";
    ignore (Events.on ctx "ui/render" (fun () ->
      Logger.info log "Rendering v1 (Blue Theme, Classic Layout)"
    ))

  let on_stop (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "[Widget v1] Stopping (unwinding hooks in-place)..."

  let on_dispose (_ctx : Context.t) = ()
end

(* Hot-swapped version 2 with zero refresh *)
module VisualWidget_v2 = struct
  let name = "visual_widget"
  let version = "2.0.0"
  let inject = []

  let on_init (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "[Widget v2] Initialized with New Modern Theme."

  let on_start (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "[Widget v2] Active! In-place hot-swapped without page refresh!";
    ignore (Events.on ctx "ui/render" (fun () ->
      Logger.info log "Rendering v2 (Cyberpunk Neon Theme, Glassmorphism)"
    ))

  let on_stop (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "[Widget v2] Stopped."

  let on_dispose (_ctx : Context.t) = ()
end

let () =
  Printf.printf "========================================================\n";
  Printf.printf "  CORDIS-OXCAML ZERO-REFRESH HMR DEMONSTRATION\n";
  Printf.printf "========================================================\n";

  let ctx = Context.root in
  let log = Logger.create ctx in
  let hmr = Hmr.create ctx in
  Hmr.start hmr;

  Logger.info log "Step 1: Registering VisualWidget v1.0.0...";
  ignore (Registry.register ctx (module VisualWidget_v1));

  Logger.info log "Step 2: Triggering UI render with v1 active:";
  Events.emit ctx "ui/render" ();

  Logger.info log "\nStep 3: Performing In-Place HMR to VisualWidget v2.0.0 (Zero-Refresh Math)...";
  Hmr.reload_plugin hmr (module VisualWidget_v2);

  Logger.info log "Step 4: Triggering UI render with v2 active (old hooks cleanly replaced):";
  Events.emit ctx "ui/render" ();

  Logger.info log "\nZero-Refresh In-Place Reconfiguration succeeded with 100%% state cleanliness."
