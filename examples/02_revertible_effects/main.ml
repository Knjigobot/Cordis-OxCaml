(* examples/02_revertible_effects/main.ml *)

open Cordis_core
open Cordis_system

module AuditLogPlugin = struct
  let name = "audit_logger"
  let version = "1.0.0"
  let inject = []

  let audit_trail = ref []

  let on_init (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "Audit logger initialized."

  let on_start (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "Starting audit hooks...";
    ignore (Events.on ctx "audit/record" (fun (action : string) ->
      audit_trail := action :: !audit_trail;
      Logger.info log "Audited action: %s" action
    ))

  let on_stop (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "Stopping audit hooks."

  let on_dispose (_ctx : Context.t) =
    audit_trail := []
end

let () =
  Printf.printf "=== Example 02: Revertible Effects and Lifecycles ===\n";
  let ctx = Context.root in
  let log = Logger.create ctx in

  Logger.info log "1. Registering AuditLogPlugin...";
  let unregister_plugin = Registry.register ctx (module AuditLogPlugin) in

  Events.emit ctx "audit/record" "User login";
  Events.emit ctx "audit/record" "Transfer funds $5,000";

  Logger.info log "2. Unregistering plugin (all effects reverted automatically)...";
  unregister_plugin ();

  Logger.info log "3. Emitting event after unregistration (should have zero listeners)...";
  Events.emit ctx "audit/record" "Ghost transaction";

  Logger.info log "Clean unwinding complete with zero state residue."
