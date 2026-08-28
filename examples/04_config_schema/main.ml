(* examples/04_config_schema/main.ml *)

open Cordis_core
open Cordis_system
open Cordis_system.Schema

type server_config = {
  host : string;
  port : int;
  enable_tls : bool;
  workers : int;
}

let server_schema = {
  validate = (function
    | Assoc pairs ->
      let host = match List.assoc_opt "host" pairs with
        | Some (String s) -> s
        | _ -> "127.0.0.1"
      in
      let port = match List.assoc_opt "port" pairs with
        | Some (Int i) -> i
        | _ -> 8080
      in
      let enable_tls = match List.assoc_opt "enable_tls" pairs with
        | Some (Bool b) -> b
        | _ -> false
      in
      let workers = match List.assoc_opt "workers" pairs with
        | Some (Int w) -> w
        | _ -> 4
      in
      Ok { host; port; enable_tls; workers }
    | Null -> Ok { host = "127.0.0.1"; port = 8080; enable_tls = false; workers = 4 }
    | _ -> Error "Expected JSON object for server config");
  to_json = (fun cfg ->
    Assoc [
      ("host", String cfg.host);
      ("port", Int cfg.port);
      ("enable_tls", Bool cfg.enable_tls);
      ("workers", Int cfg.workers);
    ]);
  default = Some { host = "127.0.0.1"; port = 8080; enable_tls = false; workers = 4 };
  description = Some "Server configuration specification";
}

let () =
  Printf.printf "=== Example 04: Schemastery Validation and Coercion ===\n";
  let ctx = Context.root in
  let log = Logger.create ctx in

  let raw_json = Assoc [
    ("host", String "0.0.0.0");
    ("port", Int 9000);
    ("enable_tls", Bool true);
  ] in

  match validate server_schema raw_json with
  | Ok cfg ->
    Logger.info log "Validated Config: host=%s, port=%d, tls=%b, workers=%d"
      cfg.host cfg.port cfg.enable_tls cfg.workers;
    let serialized = string_of_json (to_json server_schema cfg) in
    Logger.info log "Serialized JSON: %s" serialized
  | Error err ->
    Logger.error log "Validation Failed: %s" err
