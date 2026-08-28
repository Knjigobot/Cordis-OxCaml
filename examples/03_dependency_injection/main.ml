(* examples/03_dependency_injection/main.ml *)

open Cordis_core
open Cordis_system

module DatabaseService = struct
  type db = { connection_string : string }
  let create conn = { connection_string = conn }
end

module QueryWorkerPlugin = struct
  let name = "query_worker"
  let version = "1.0.0"
  let inject = ["database"]

  let on_init (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "[QueryWorker] Initialized (waiting for 'database' service)..."

  let on_start (ctx : Context.t) =
    let log = Logger.create ctx in
    let db : DatabaseService.db = Service.get_exn ctx "database" in
    Logger.info log "[QueryWorker] Active! Connected to %s" db.connection_string;
    ignore (Events.on ctx "query/exec" (fun (sql : string) ->
      Logger.info log "[QueryWorker] Executing on %s: %s" db.connection_string sql
    ))

  let on_stop (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "[QueryWorker] Database disconnected, worker paused."

  let on_dispose (_ctx : Context.t) = ()
end

let () =
  Printf.printf "=== Example 03: Dynamic Dependency Injection ===\n";
  let ctx = Context.root in
  let log = Logger.create ctx in

  Logger.info log "Step 1: Registering QueryWorker (requires 'database')...";
  let _worker_disp = Registry.register ctx (module QueryWorkerPlugin) in

  Logger.info log "Step 2: Emitting query before database exists (worker is paused)...";
  Events.emit ctx "query/exec" "SELECT * FROM users";

  Logger.info log "Step 3: Providing 'database' service...";
  let db_disp = Service.provide ctx "database" (DatabaseService.create "postgresql://cordis:5432/main") in

  Logger.info log "Step 4: Emitting query now (worker runs query)...";
  Events.emit ctx "query/exec" "SELECT * FROM orders WHERE status = 'pending'";

  Logger.info log "Step 5: Dropping database service (worker pauses smoothly)...";
  db_disp ();

  Events.emit ctx "query/exec" "SELECT * FROM post_mortem";
  Logger.info log "Done."
