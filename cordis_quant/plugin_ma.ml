(* plugin_ma.ml - Moving Average Plugin Implementation *)

open Market_types
open Cordis_core

type ma_info = {
  fast_ma : float;
  slow_ma : float;
  trend : [ `Bullish | `Bearish | `Neutral ];
}

module Plugin = struct
  let name = "moving_average"
  let version = "1.0.0"
  let inject = []

  let fast_buf = Ring_buffer.create 5
  let slow_buf = Ring_buffer.create 20
  let prev_trend = ref `Neutral

  let on_init (_ctx : Context.t) =
    Ring_buffer.clear fast_buf;
    Ring_buffer.clear slow_buf;
    prev_trend := `Neutral

  let on_start (ctx : Context.t) =
    ignore (Events.on ctx "market/tick" (fun (t : tick) ->
      Ring_buffer.push fast_buf t.last_price;
      Ring_buffer.push slow_buf t.last_price;
      match Ring_buffer.mean fast_buf, Ring_buffer.mean slow_buf with
      | Some fast_val, Some slow_val ->
        let current_trend =
          if fast_val > slow_val then `Bullish
          else if fast_val < slow_val then `Bearish
          else `Neutral
        in
        let info = { fast_ma = fast_val; slow_ma = slow_val; trend = current_trend } in
        Context.set_dynamic ctx ("coeffect:ma:" ^ t.symbol) info;
        Events.emit ctx "indicator/ma" (t.symbol, info);

        if !prev_trend <> current_trend then begin
          prev_trend := current_trend;
          Events.emit ctx "signal/crossover" (t.symbol, current_trend, t.last_price)
        end
      | _ -> ()
    ))

  let on_stop (ctx : Context.t) =
    Context.remove_dynamic ctx "coeffect:ma"

  let on_dispose (_ctx : Context.t) =
    Ring_buffer.clear fast_buf;
    Ring_buffer.clear slow_buf
end

let get_latest_ma (ctx : Context.t) (sym : string) : ma_info option =
  Context.get_dynamic ctx ("coeffect:ma:" ^ sym)
