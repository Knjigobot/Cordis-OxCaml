(** [Cordis_system.Schema] - Type-Safe Runtime Configuration Schemas and Validation *)

type json_value =
  | Null
  | Bool of bool
  | Int of int
  | Float of float
  | String of string
  | List of json_value list
  | Assoc of (string * json_value) list

type 'a t

(** Primitives *)
val string : ?default:string -> ?desc:string -> unit -> string t
val int : ?default:int -> ?min:int -> ?max:int -> ?desc:string -> unit -> int t
val float : ?default:float -> ?min:float -> ?max:float -> ?desc:string -> unit -> float t
val bool : ?default:bool -> ?desc:string -> unit -> bool t

(** Combinators *)
val list : 'a t -> 'a list t
val option : 'a t -> 'a option t
val custom : to_json:('a -> json_value) -> of_json:(json_value -> ('a, string) result) -> ?desc:string -> unit -> 'a t

(** Validation & Serialization *)
val validate : 'a t -> json_value -> ('a, string) result
val validate_exn : 'a t -> json_value -> 'a
val to_json : 'a t -> 'a -> json_value

val string_of_json : json_value -> string
val json_of_string : string -> (json_value, string) result
