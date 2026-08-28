(* market_feed.ml - Stochastic Market Generator Implementation *)

open Market_types
open Cordis_core

type generator_config = {
  symbol : symbol;
  initial_price : float;
  drift : float;
  volatility : float;
  jump_intensity : float;
  jump_mean : float;
  jump_std : float;
  spread_bps : float;
}

let default_config (sym : symbol) : generator_config = {
  symbol = sym;
  initial_price = 100.0;
  drift = 0.05;
  volatility = 0.20;
  jump_intensity = 0.10;
  jump_mean = 0.0;
  jump_std = 0.02;
  spread_bps = 2.0;
}

type feed = {
  cfg : generator_config;
  mutable current_price : float;
  mutable last_time : float;
}

(* Box-Muller Gaussian sample *)
let rand_gaussian () : float =
  let u1 = max 1e-15 (Random.float 1.0) in
  let u2 = Random.float 1.0 in
  sqrt (-2.0 *. log u1) *. cos (2.0 *. Float.pi *. u2)

let create (cfg : generator_config) : feed = {
  cfg;
  current_price = cfg.initial_price;
  last_time = Unix.gettimeofday ();
}

let next_tick (f : feed) (now : float) : tick =
  let dt = max 0.001 (now -. f.last_time) in
  f.last_time <- now;

  (* 1. Geometric Brownian Motion component *)
  let z = rand_gaussian () in
  let gbm_ret = (f.cfg.drift -. 0.5 *. f.cfg.volatility *. f.cfg.volatility) *. dt
                +. (f.cfg.volatility *. sqrt dt *. z) in

  (* 2. Poisson Jump component *)
  let jump_prob = f.cfg.jump_intensity *. dt in
  let jump_ret =
    if Random.float 1.0 < jump_prob then
      f.cfg.jump_mean +. f.cfg.jump_std *. rand_gaussian ()
    else 0.0
  in

  let next_p = f.current_price *. exp (gbm_ret +. jump_ret) in
  let clean_p = max 0.01 next_p in
  f.current_price <- clean_p;

  let half_spread = clean_p *. (f.cfg.spread_bps /. 20_000.0) in
  let bid = clean_p -. half_spread in
  let ask = clean_p +. half_spread in
  let volume = 1.0 +. floor (Random.float 10.0) in

  {
    symbol = f.cfg.symbol;
    timestamp = now;
    last_price = clean_p;
    bid;
    ask;
    volume;
  }

let start_stream (f : feed) (ctx : Context.t) (interval_sec : float) (duration_sec : float) : unit =
  let start_time = Unix.gettimeofday () in
  let end_time = start_time +. duration_sec in
  let rec loop () =
    let now = Unix.gettimeofday () in
    if now < end_time && Scope.is_active (Context.scope ctx) then begin
      let t = next_tick f now in
      Events.emit ctx "market/tick" t;
      ignore (Cordis_system.Timer.timeout ctx interval_sec loop)
    end
  in
  loop ()
