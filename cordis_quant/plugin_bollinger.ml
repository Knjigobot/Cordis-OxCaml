(* plugin_bollinger.ml - Bollinger Bands Plugin Implementation *)

open Market_types
open Cordis_core

type bands = {
  middle : float;
  upper : float;
  lower : float;
  bandwidth : float;
  percent_b : float;
}

module Plugin = struct
  let name = "bollinger_bands"
  let version = "1.0.0"
  let inject = []

  let window_size = 20
  let num_std = 2.0
  let price_buffer = Ring_buffer.create window_size

  let on_init (_ctx : Context.t) =
    Ring_buffer.clear price_buffer

  let on_start (ctx : Context.t) =
    ignore (Events.on ctx "market/tick" (fun (t : tick) ->
      Ring_buffer.push price_buffer t.last_price;
      match Ring_buffer.mean price_buffer, Ring_buffer.stddev price_buffer with
      | Some mu, Some sigma ->
        let upper = mu +. (num_std *. sigma) in
        let lower = mu -. (num_std *. sigma) in
        let bw = if mu > 0.0 then (upper -. lower) /. mu else 0.0 in
        let pb = if (upper -. lower) > 1e-9 then (t.last_price -. lower) /. (upper -. lower) else 0.5 in
        let b = { middle = mu; upper; lower; bandwidth = bw; percent_b = pb } in
        Context.set_dynamic ctx ("coeffect:bollinger:" ^ t.symbol) b;
        Events.emit ctx "indicator/bollinger" (t.symbol, b);

        if t.last_price > upper then
          Events.emit ctx "signal/breakout" (t.symbol, `Upper_Breakout, t.last_price)
        else if t.last_price < lower then
          Events.emit ctx "signal/breakout" (t.symbol, `Lower_Breakout, t.last_price)
      | _ -> ()
    ))

  let on_stop (ctx : Context.t) =
    Context.remove_dynamic ctx "coeffect:bollinger"

  let on_dispose (_ctx : Context.t) =
    Ring_buffer.clear price_buffer
end

let get_latest_bands (ctx : Context.t) (sym : string) : bands option =
  Context.get_dynamic ctx ("coeffect:bollinger:" ^ sym)
