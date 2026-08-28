(* test_schema.ml - Type-Safe Schema Validation Tests *)

open Cordis_system.Schema

let run_tests () =
  Printf.printf "  [TEST] Schemastery Runtime Validation & Serializer...\n";

  (* 1. Integer with min/max and default *)
  let port_schema = int ~default:8080 ~min:1024 ~max:65535 () in

  assert (validate port_schema (Int 8088) = Ok 8088);
  assert (validate port_schema Null = Ok 8080);
  (match validate port_schema (Int 80) with
   | Error _ -> ()
   | Ok _ -> failwith "Port 80 should fail min bound 1024");

  (* 2. String with default *)
  let host_schema = string ~default:"127.0.0.1" () in
  assert (validate host_schema (String "0.0.0.0") = Ok "0.0.0.0");
  assert (validate host_schema Null = Ok "127.0.0.1");

  (* 3. List combinator *)
  let tags_schema = list (string ()) in
  let json_tags = List [String "production"; String "web"; String "us-east"] in
  assert (validate tags_schema json_tags = Ok ["production"; "web"; "us-east"]);

  (* 4. JSON conversion *)
  let serialized = string_of_json (to_json tags_schema ["a"; "b"; "c"]) in
  assert (serialized = "[\"a\", \"b\", \"c\"]");

  Printf.printf "    ✓ Primitive schema boundaries verified.\n";
  Printf.printf "    ✓ Default injection and coercion verified.\n";
  Printf.printf "    ✓ Combinator list & JSON serialization verified.\n"
