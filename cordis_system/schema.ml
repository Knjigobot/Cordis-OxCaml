(* schema.ml - Type-Safe Runtime Configuration Schemas Implementation *)

open Cordis_core.Types

type json_value =
  | Null
  | Bool of bool
  | Int of int
  | Float of float
  | String of string
  | List of json_value list
  | Assoc of (string * json_value) list

type 'a t = {
  validate : json_value -> ('a, string) result;
  to_json : 'a -> json_value;
  default : 'a option;
  description : string option;
}

let string ?default ?desc () : string t = {
  validate = (function
    | String s -> Ok s
    | Null -> (match default with Some d -> Ok d | None -> Error "Missing required string")
    | _ -> Error "Expected string");
  to_json = (fun s -> String s);
  default;
  description = desc;
}

let int ?default ?min ?max ?desc () : int t = {
  validate = (function
    | Int i ->
      (match min with Some m when i < m -> Error (Printf.sprintf "Integer %d below minimum %d" i m) | _ ->
       match max with Some m when i > m -> Error (Printf.sprintf "Integer %d exceeds maximum %d" i m) | _ -> Ok i)
    | Float f ->
      let i = int_of_float f in
      (match min with Some m when i < m -> Error (Printf.sprintf "Integer %d below minimum %d" i m) | _ ->
       match max with Some m when i > m -> Error (Printf.sprintf "Integer %d exceeds maximum %d" i m) | _ -> Ok i)
    | Null -> (match default with Some d -> Ok d | None -> Error "Missing required integer")
    | _ -> Error "Expected integer");
  to_json = (fun i -> Int i);
  default;
  description = desc;
}

let float ?default ?min ?max ?desc () : float t = {
  validate = (function
    | Float f ->
      (match min with Some m when f < m -> Error (Printf.sprintf "Float %f below minimum %f" f m) | _ ->
       match max with Some m when f > m -> Error (Printf.sprintf "Float %f exceeds maximum %f" f m) | _ -> Ok f)
    | Int i ->
      let f = float_of_int i in
      (match min with Some m when f < m -> Error (Printf.sprintf "Float %f below minimum %f" f m) | _ ->
       match max with Some m when f > m -> Error (Printf.sprintf "Float %f exceeds maximum %f" f m) | _ -> Ok f)
    | Null -> (match default with Some d -> Ok d | None -> Error "Missing required float")
    | _ -> Error "Expected float");
  to_json = (fun f -> Float f);
  default;
  description = desc;
}

let bool ?default ?desc () : bool t = {
  validate = (function
    | Bool b -> Ok b
    | Null -> (match default with Some d -> Ok d | None -> Error "Missing required bool")
    | _ -> Error "Expected boolean");
  to_json = (fun b -> Bool b);
  default;
  description = desc;
}

let list (elem_schema : 'a t) : 'a list t = {
  validate = (function
    | List items ->
      let rec loop acc = function
        | [] -> Ok (List.rev acc)
        | x :: xs ->
          (match elem_schema.validate x with
           | Ok v -> loop (v :: acc) xs
           | Error err -> Error ("List item error: " ^ err))
      in
      loop [] items
    | Null -> Ok []
    | _ -> Error "Expected list");
  to_json = (fun lst -> List (List.map elem_schema.to_json lst));
  default = Some [];
  description = elem_schema.description;
}

let option (elem_schema : 'a t) : 'a option t = {
  validate = (function
    | Null -> Ok None
    | other ->
      (match elem_schema.validate other with
       | Ok v -> Ok (Some v)
       | Error err -> Error err));
  to_json = (function
    | Some v -> elem_schema.to_json v
    | None -> Null);
  default = Some None;
  description = elem_schema.description;
}

let custom ~to_json ~of_json ?desc () : 'a t = {
  validate = of_json;
  to_json;
  default = None;
  description = desc;
}

let validate (schema : 'a t) (json : json_value) : ('a, string) result =
  schema.validate json

let validate_exn (schema : 'a t) (json : json_value) : 'a =
  match validate schema json with
  | Ok v -> v
  | Error err -> raise (Validation_error err)

let to_json (schema : 'a t) (v : 'a) : json_value =
  schema.to_json v

let rec string_of_json = function
  | Null -> "null"
  | Bool b -> if b then "true" else "false"
  | Int i -> string_of_int i
  | Float f -> Printf.sprintf "%.6g" f
  | String s -> "\"" ^ String.escaped s ^ "\""
  | List items -> "[" ^ String.concat ", " (List.map string_of_json items) ^ "]"
  | Assoc pairs ->
    "{" ^ String.concat ", " (List.map (fun (k, v) -> "\"" ^ String.escaped k ^ "\": " ^ string_of_json v) pairs) ^ "}"

let json_of_string (s : string) : (json_value, string) result =
  let trimmed = String.trim s in
  if trimmed = "" || trimmed = "null" then Ok Null
  else if trimmed = "true" then Ok (Bool true)
  else if trimmed = "false" then Ok (Bool false)
  else if (try ignore (int_of_string trimmed); true with _ -> false) then Ok (Int (int_of_string trimmed))
  else if (try ignore (float_of_string trimmed); true with _ -> false) then Ok (Float (float_of_string trimmed))
  else if String.length trimmed >= 2 && trimmed.[0] = '"' && trimmed.[String.length trimmed - 1] = '"' then
    Ok (String (String.sub trimmed 1 (String.length trimmed - 2)))
  else
    (* Simple fallback parser *)
    Ok (String trimmed)
