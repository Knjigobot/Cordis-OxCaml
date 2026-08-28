(** [Cordis_quant.Market_types] - Quantitative Finance and Execution Models *)

type symbol = string

type timeframe = M1 | M5 | M15 | H1 | D1

val seconds_of_timeframe : timeframe -> float

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
