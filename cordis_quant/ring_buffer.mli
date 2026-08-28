(** [Cordis_quant.Ring_buffer] - Zero-Allocation In-Place Sliding Window Ring Buffer *)

type 'a t

val create : int -> 'a t
val capacity : 'a t -> int
val length : 'a t -> int
val is_empty : 'a t -> bool
val is_full : 'a t -> bool
val push : 'a t -> 'a -> unit
val get : 'a t -> int -> 'a option
val get_latest : 'a t -> 'a option
val to_list : 'a t -> 'a list
val clear : 'a t -> unit

(** Fast Statistical Operations on Numeric Buffers *)
val mean : float t -> float option
val variance : float t -> float option
val stddev : float t -> float option
