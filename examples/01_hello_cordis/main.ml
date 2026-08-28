(* examples/01_hello_cordis/main.ml *)

open Cordis_core
open Cordis_system

module GreeterPlugin = struct
  let name = "greeter"
  let version = "1.0.0"
  let inject = []

  let on_init (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "Greeter plugin initialized!"

  let on_start (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "Greeter plugin active. Listening for 'user/join' events...";
    ignore (Events.on ctx "user/join" (fun (username : string) ->
      Logger.info log "Welcome to Cordis-OxCaml, %s!" username
    ))

  let on_stop (ctx : Context.t) =
    let log = Logger.create ctx in
    Logger.info log "Greeter plugin stopped."

  let on_dispose (_ctx : Context.t) = ()
end

let () =
  Printf.printf "=== Example 01: Hello Cordis-OxCaml ===\n";
  let ctx = Context.root in
  let _disp = Registry.register ctx (module GreeterPlugin) in

  Events.emit ctx "user/join" "Alice";
  Events.emit ctx "user/join" "Bob";

  Printf.printf "Done.\n"
