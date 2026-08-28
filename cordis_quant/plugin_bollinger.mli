(** [Cordis_quant.Plugin_bollinger] - Bollinger Bands Spatiotemporal Indicator Plugin *)

open Cordis_core

type bands = {
  middle : float;
  upper : float;
  lower : float;
  bandwidth : float;
  percent_b : float;
}

module Plugin : Registry.PLUGIN

val get_latest_bands : Context.t -> string -> bands option
