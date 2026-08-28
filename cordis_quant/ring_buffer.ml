(* ring_buffer.ml - Sliding Window Ring Buffer Implementation *)

type 'a t = {
  capacity : int;
  buffer : 'a option array;
  mutable head : int;
  mutable count : int;
}

let create (cap : int) : 'a t =
  if cap <= 0 then invalid_arg "Ring_buffer capacity must be > 0";
  {
    capacity = cap;
    buffer = Array.make cap None;
    head = 0;
    count = 0;
  }

let capacity (rb : 'a t) : int = rb.capacity
let length (rb : 'a t) : int = rb.count
let is_empty (rb : 'a t) : bool = rb.count = 0
let is_full (rb : 'a t) : bool = rb.count = rb.capacity

let push (rb : 'a t) (item : 'a) : unit =
  rb.buffer.(rb.head) <- Some item;
  rb.head <- (rb.head + 1) mod rb.capacity;
  if rb.count < rb.capacity then rb.count <- rb.count + 1

let get (rb : 'a t) (idx : int) : 'a option =
  if idx < 0 || idx >= rb.count then None
  else
    let start = (rb.head - rb.count + rb.capacity) mod rb.capacity in
    let pos = (start + idx) mod rb.capacity in
    rb.buffer.(pos)

let get_latest (rb : 'a t) : 'a option =
  if rb.count = 0 then None
  else
    let pos = (rb.head - 1 + rb.capacity) mod rb.capacity in
    rb.buffer.(pos)

let to_list (rb : 'a t) : 'a list =
  let res = ref [] in
  for i = rb.count - 1 downto 0 do
    match get rb i with
    | Some v -> res := v :: !res
    | None -> ()
  done;
  !res

let clear (rb : 'a t) : unit =
  Array.fill rb.buffer 0 rb.capacity None;
  rb.head <- 0;
  rb.count <- 0

let mean (rb : float t) : float option =
  if rb.count = 0 then None
  else
    let sum = ref 0.0 in
    for i = 0 to rb.count - 1 do
      match get rb i with
      | Some v -> sum := !sum +. v
      | None -> ()
    done;
    Some (!sum /. float_of_int rb.count)

let variance (rb : float t) : float option =
  if rb.count < 2 then None
  else match mean rb with
    | None -> None
    | Some m ->
      let sum_sq = ref 0.0 in
      for i = 0 to rb.count - 1 do
        match get rb i with
        | Some v ->
          let diff = v -. m in
          sum_sq := !sum_sq +. (diff *. diff)
        | None -> ()
      done;
      Some (!sum_sq /. float_of_int (rb.count - 1))

let stddev (rb : float t) : float option =
  match variance rb with
  | Some v -> Some (sqrt v)
  | None -> None
