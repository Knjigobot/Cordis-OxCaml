(* hmr.ml - Hot Module Replacement & Zero-Refresh Reconciler Implementation *)

open Cordis_core.Types
open Cordis_core

type reload_event = {
  module_name : string;
  filename : string option;
  timestamp : float;
}

type t = {
  ctx : Context.t;
  base_dir : string;
  debounce_sec : float;
  mutable watching : bool;
  mutable last_reload : (string, float) Hashtbl.t;
}

let create ?(base_dir = ".") ?(debounce_sec = 0.15) (ctx : Context.t) : t =
  let hmr_scope = Scope.create ~parent:(Context.scope ctx) "hmr" in
  let hmr_ctx = Context.create ~parent:ctx ~scope:hmr_scope "hmr" in
  {
    ctx = hmr_ctx;
    base_dir;
    debounce_sec;
    watching = false;
    last_reload = Hashtbl.create 16;
  }

let is_watching (h : t) : bool = h.watching

let reload_plugin (h : t) (m : (module Registry.PLUGIN)) : unit =
  let (module P) = m in
  let mod_name = P.name in
  let now = Unix.gettimeofday () in

  (* Debounce rapid successive reload triggers *)
  let should_run = match Hashtbl.find_opt h.last_reload mod_name with
    | Some last_t when now -. last_t < h.debounce_sec -> false
    | _ -> true
  in

  if should_run then begin
    Hashtbl.replace h.last_reload mod_name now;

    (* 1. In-place Hot Module Replacement using Cordis Spatiotemporal Unwinding *)
    Registry.reload h.ctx m;

    let ev = { module_name = mod_name; filename = None; timestamp = now } in
    Events.emit h.ctx "hmr/reload" ev;

    (* 2. If Http_server is active in context, broadcast zero-refresh in-place patch *)
    let patch_json = Printf.sprintf "{\"type\":\"hmr_patch\",\"module\":\"%s\",\"timestamp\":%.3f}"
        mod_name now in
    (match Service.get h.ctx "http_server" with
     | Some server_obj ->
       (* Dynamic dispatch to server broadcast without hard coupling *)
       let server : Http_server.t = Obj.magic server_obj in
       Http_server.broadcast_sse server patch_json
     | None -> ());

    (match Service.get h.ctx "logger" with
     | Some log_obj ->
       let log : Logger.t = Obj.magic log_obj in
       Logger.info log "[HMR ZERO-REFRESH] In-place hot reloaded plugin '%s' at %.3f" mod_name now
     | None -> ())
  end

let notify_change (h : t) ?filename (mod_name : string) : unit =
  let now = Unix.gettimeofday () in
  let ev = { module_name = mod_name; filename; timestamp = now } in
  Events.emit h.ctx "hmr/change" ev

let start (h : t) : unit =
  if not h.watching then begin
    h.watching <- true;
    ignore (Service.provide h.ctx "hmr" h)
  end

let stop (h : t) : unit =
  if h.watching then begin
    h.watching <- false;
    Service.remove "hmr"
  end
