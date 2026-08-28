(** [Cordis_quant.Plugin_ma] - Moving Average Momentum Indicator Plugin *)

open Cordis_core

type ma_info = {
  fast_ma : float;
  slow_ma : float;
  trend : [ `Bullish | `Bearish | `Neutral ];
}

module Plugin : Registry.PLUGIN

val get_latest_ma : Context.t -> string -> ma_info option
