(** [Cordis_quant.Market_feed] - Stochastic Market Simulation & Feed Generator *)

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

val default_config : symbol -> generator_config

type feed

val create : generator_config -> feed
val next_tick : feed -> float -> tick
val start_stream : feed -> Context.t -> float -> float -> unit
