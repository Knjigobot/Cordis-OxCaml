(* examples/05_trading_daemon/main.ml *)

open Cordis_core
open Cordis_system
open Cordis_quant

let () =
  Printf.printf "========================================================\n";
  Printf.printf "  TRADIS DAEMON (100%% OXCAML CORDIS RUNTIME)\n";
  Printf.printf "========================================================\n";

  let ctx = Context.root in
  let log = Logger.create ctx in

  Logger.info log "Initializing Cordis-OxCaml Runtime Kernel...";

  (* 1. Start HTTP / SSE Server on port 8088 *)
  let server = Http_server.create ~port:8088 ctx in
  Http_server.start server;
  Logger.info log "Live HTTP/SSE Server running on http://127.0.0.1:8088";

  (* 2. Register Quantitative Indicator Plugins *)
  Logger.info log "Loading Indicator Plugins (Bollinger Bands, Moving Average)...";
  ignore (Registry.register ctx (module Plugin_bollinger.Plugin));
  ignore (Registry.register ctx (module Plugin_ma.Plugin));

  (* 3. Subscribe to Signals and forward to SSE & Log *)
  ignore (Events.on ctx "signal/breakout" (fun (sym, signal_type, price) ->
    let s_str = match signal_type with `Upper_Breakout -> "UPPER BREAKOUT" | `Lower_Breakout -> "LOWER BREAKOUT" in
    Logger.warn log "[SIGNAL] %s on %s at price $%.2f" s_str sym price;
    let json_event = Printf.sprintf "{\"type\":\"signal\",\"symbol\":\"%s\",\"signal\":\"%s\",\"price\":%.2f}" sym s_str price in
    Http_server.broadcast_sse server json_event
  ));

  ignore (Events.on ctx "signal/crossover" (fun (sym, trend, price) ->
    let t_str = match trend with `Bullish -> "GOLDEN CROSS (BULLISH)" | `Bearish -> "DEATH CROSS (BEARISH)" | `Neutral -> "NEUTRAL" in
    Logger.info log "[MA CROSS] %s on %s at price $%.2f" t_str sym price;
    let json_event = Printf.sprintf "{\"type\":\"ma_cross\",\"symbol\":\"%s\",\"trend\":\"%s\",\"price\":%.2f}" sym t_str price in
    Http_server.broadcast_sse server json_event
  ));

  (* 4. Start Stochastic Market Data Feed *)
  Logger.info log "Starting simulated market feed for CRUDE_OIL (CL)...";
  let feed_cfg = Market_feed.default_config "CL" in
  let feed = Market_feed.create feed_cfg in

  (* Generate 25 ticks with live analysis *)
  for _i = 1 to 25 do
    let now = Unix.gettimeofday () in
    let tick = Market_feed.next_tick feed now in
    Events.emit ctx "market/tick" tick;
    let tick_json = Printf.sprintf "{\"type\":\"tick\",\"symbol\":\"%s\",\"price\":%.2f,\"bid\":%.2f,\"ask\":%.2f}"
        tick.symbol tick.last_price tick.bid tick.ask in
    Http_server.broadcast_sse server tick_json;
    Unix.sleepf 0.05
  done;

  Logger.info log "Execution demonstration finished successfully. Stopping server...";
  Http_server.stop server;
  Logger.info log "Tradis Daemon halted cleanly with zero leaks."
