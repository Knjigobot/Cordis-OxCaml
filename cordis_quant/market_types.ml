(* market_types.ml - Financial Models Implementation *)

type symbol = string

type timeframe = M1 | M5 | M15 | H1 | D1

let seconds_of_timeframe = function
  | M1 -> 60.0
  | M5 -> 300.0
  | M15 -> 900.0
  | H1 -> 3600.0
  | D1 -> 86400.0

type commodity_contract =
  | ALI_FUT
  | COPPER_FUT
  | ZINC_FUT
  | NICKEL_FUT
  | CRUDE_FUT
  | Custom_Contract of { symbol : string; lot_size : float; tick_size : float; tick_val : float }

type contract_spec = {
  contract_symbol : string;
  name : string;
  exchange : string;
  lot_size : float;
  tick_size : float;
  tick_value : float;
}

let get_contract_spec = function
  | ALI_FUT -> {
      contract_symbol = "ALI_FUT";
      name = "LME Primary Aluminium 3M";
      exchange = "LME";
      lot_size = 25.0;
      tick_size = 0.50;
      tick_value = 12.50;
    }
  | COPPER_FUT -> {
      contract_symbol = "COPPER_FUT";
      name = "LME Grade A Copper";
      exchange = "LME";
      lot_size = 25.0;
      tick_size = 0.50;
      tick_value = 12.50;
    }
  | ZINC_FUT -> {
      contract_symbol = "ZINC_FUT";
      name = "LME SHG Zinc";
      exchange = "LME";
      lot_size = 25.0;
      tick_size = 0.50;
      tick_value = 12.50;
    }
  | NICKEL_FUT -> {
      contract_symbol = "NICKEL_FUT";
      name = "LME Primary Nickel";
      exchange = "LME";
      lot_size = 6.0;
      tick_size = 1.00;
      tick_value = 6.00;
    }
  | CRUDE_FUT -> {
      contract_symbol = "CRUDE_FUT";
      name = "NYMEX WTI Light Sweet Crude";
      exchange = "NYMEX";
      lot_size = 1000.0;
      tick_size = 0.01;
      tick_value = 10.00;
    }
  | Custom_Contract c -> {
      contract_symbol = c.symbol;
      name = c.symbol;
      exchange = "OTC";
      lot_size = c.lot_size;
      tick_size = c.tick_size;
      tick_value = c.tick_val;
    }

let notional_value (c : commodity_contract) (lots : float) (spot_price : float) : float =
  let spec = get_contract_spec c in
  abs_float lots *. spec.lot_size *. spot_price

let calculate_pnl (c : commodity_contract) (lots : float) (current_p : float) (avg_entry_p : float) : float =
  let spec = get_contract_spec c in
  lots *. spec.lot_size *. (current_p -. avg_entry_p)

type tick = {
  symbol : symbol;
  timestamp : float;
  last_price : float;
  bid : float;
  ask : float;
  volume : float;
}

type bar = {
  symbol : symbol;
  timeframe : timeframe;
  open_time : float;
  open_p : float;
  high_p : float;
  low_p : float;
  close_p : float;
  volume : float;
}

type direction = Buy | Sell

type order_type = Market | Limit of float

type order_status =
  | Pending
  | Active
  | Filled of { fill_price : float; fill_time : float }
  | Canceled of string
  | Rejected of string

type order = {
  id : string;
  symbol : symbol;
  direction : direction;
  order_type : order_type;
  qty : float;
  mutable status : order_status;
  created_time : float;
}

type position = {
  symbol : symbol;
  mutable qty : float;
  mutable avg_entry_price : float;
  mutable unrealized_pnl : float;
}

type account = {
  id : string;
  mutable balance : float;
  mutable equity : float;
  mutable margin_used : float;
  mutable free_margin : float;
  leverage : float;
}
