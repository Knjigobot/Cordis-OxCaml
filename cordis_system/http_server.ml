(* http_server.ml - Dual-Channel Native HTTP 1.1 & SSE Server Implementation *)

open Cordis_core.Types
open Cordis_core

type t = {
  ctx : Context.t;
  host : string;
  port : int;
  static_dir : string option;
  mutable version : float;
  mutable running : bool;
  mutable server_sock : Unix.file_descr option;
  mutable sse_clients : Unix.file_descr list;
}

let create ?(host = "127.0.0.1") ?(port = 8088) ?static_dir (ctx : Context.t) : t =
  let s = {
    ctx;
    host;
    port;
    static_dir;
    version = Unix.gettimeofday ();
    running = false;
    server_sock = None;
    sse_clients = [];
  } in
  ignore (Service.provide ctx "http_server" s);
  s

let port (s : t) : int = s.port
let is_running (s : t) : bool = s.running
let current_version (s : t) : float = s.version

let bump_version (s : t) : unit =
  s.version <- Unix.gettimeofday ();
  let msg = Printf.sprintf "{\"type\":\"version_bump\",\"version\":%.3f}" s.version in
  let sse_msg = Printf.sprintf "data: %s\n\n" msg in
  let valid_clients = ref [] in
  List.iter (fun client_sock ->
    try
      ignore (Unix.write_substring client_sock sse_msg 0 (String.length sse_msg));
      valid_clients := client_sock :: !valid_clients
    with _ ->
      (try Unix.close client_sock with _ -> ())
  ) s.sse_clients;
  s.sse_clients <- !valid_clients

let broadcast_sse (s : t) (data : string) : unit =
  let msg = Printf.sprintf "data: %s\n\n" data in
  let valid_clients = ref [] in
  List.iter (fun client_sock ->
    try
      ignore (Unix.write_substring client_sock msg 0 (String.length msg));
      valid_clients := client_sock :: !valid_clients
    with _ ->
      (try Unix.close client_sock with _ -> ())
  ) s.sse_clients;
  s.sse_clients <- !valid_clients

let handle_client (s : t) (client_sock : Unix.file_descr) : unit =
  let in_ch = Unix.in_channel_of_descr client_sock in
  let line = try input_line in_ch with _ -> "" in
  let parts = String.split_on_char ' ' line in
  match parts with
  | meth :: path :: _ ->
    let clean_path = List.hd (String.split_on_char '?' path) in

    (* 1. Channel A: SSE Live-Sync Stream *)
    if clean_path = "/_cordis_live" || clean_path = "/events" then begin
      let header = "HTTP/1.1 200 OK\r\n" ^
                   "Content-Type: text/event-stream\r\n" ^
                   "Cache-Control: no-cache, no-transform\r\n" ^
                   "Connection: keep-alive\r\n" ^
                   "Access-Control-Allow-Origin: *\r\n\r\n" ^
                   (Printf.sprintf "data: {\"type\":\"connected\",\"status\":\"ready\",\"version\":%.3f}\n\n" s.version) in
      ignore (Unix.write_substring client_sock header 0 (String.length header));
      s.sse_clients <- client_sock :: s.sse_clients
    end

    (* 2. Channel B: Micro-Heartbeat Version Polling Endpoint (Fallback) *)
    else if clean_path = "/_cordis_version" || clean_path = "/version" then begin
      let body = Printf.sprintf "{\"status\":\"ready\",\"version\":%.3f,\"timestamp\":%.3f}"
          s.version (Unix.gettimeofday ()) in
      let resp = Printf.sprintf "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: %d\r\n\r\n%s"
          (String.length body) body in
      ignore (Unix.write_substring client_sock resp 0 (String.length resp));
      Unix.close client_sock
    end

    (* 3. Manifold State Synchronization Snapshot *)
    else if clean_path = "/_cordis_sync" || clean_path = "/api/status" then begin
      let plugins = Registry.list_plugins () in
      let plugin_json = String.concat ", " (List.map (fun (name, ver, st, evs) ->
        Printf.sprintf "{\"name\":\"%s\",\"version\":\"%s\",\"status\":\"%s\",\"events\":%d}"
          name ver (string_of_lifecycle_state st) evs
      ) plugins) in
      let services = Service.list_services () in
      let services_json = String.concat ", " (List.map (fun name -> "\"" ^ name ^ "\"") services) in
      let body = Printf.sprintf "{\"status\":\"ok\",\"version\":%.3f,\"plugins\":[%s],\"services\":[%s]}"
          s.version plugin_json services_json in
      let resp = Printf.sprintf "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: %d\r\n\r\n%s"
          (String.length body) body in
      ignore (Unix.write_substring client_sock resp 0 (String.length resp));
      Unix.close client_sock
    end

    (* 4. Static / Default HTML Response *)
    else begin
      let body = "<!DOCTYPE html><html><head><title>Cordis-OxCaml</title></head><body><h1>Cordis-OxCaml Runtime Active</h1><p>Spatiotemporal Composability Engine Running with Dual-Channel Zero-Refresh Live Sync.</p></body></html>" in
      let resp = Printf.sprintf "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\n\r\n%s"
          (String.length body) body in
      ignore (Unix.write_substring client_sock resp 0 (String.length resp));
      Unix.close client_sock
    end
  | _ ->
    Unix.close client_sock

let start (s : t) : unit =
  if not s.running then begin
    let sock = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
    Unix.setsockopt sock Unix.SO_REUSEADDR true;
    let addr = Unix.inet_addr_of_string s.host in
    Unix.bind sock (Unix.ADDR_INET (addr, s.port));
    Unix.listen sock 16;
    s.server_sock <- Some sock;
    s.running <- true;

    ignore (Thread.create (fun () ->
      while s.running do
        try
          let (client_sock, _) = Unix.accept sock in
          ignore (Thread.create (handle_client s) client_sock)
        with _ -> ()
      done
    ) ())
  end

let stop (s : t) : unit =
  if s.running then begin
    s.running <- false;
    List.iter (fun c -> try Unix.close c with _ -> ()) s.sse_clients;
    s.sse_clients <- [];
    (match s.server_sock with
     | Some sock -> (try Unix.close sock with _ -> ()); s.server_sock <- None
     | None -> ())
  end
