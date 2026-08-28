(* logger.ml - Structured Leveled Logger Implementation *)

open Cordis_core.Types
open Cordis_core

type t = {
  ctx : Context.t;
  mutable min_level : log_level;
  mutable use_json : bool;
}

let level_weight = function
  | Debug -> 0
  | Info -> 1
  | Warn -> 2
  | Error -> 3
  | Fatal -> 4

let ansi_color = function
  | Debug -> "\027[90m" (* Gray *)
  | Info -> "\027[32m"  (* Green *)
  | Warn -> "\027[33m"  (* Yellow *)
  | Error -> "\027[31m" (* Red *)
  | Fatal -> "\027[35m" (* Magenta *)

let ansi_reset = "\027[0m"

let create ?(min_level = Info) ?(use_json = false) (ctx : Context.t) : t =
  { ctx; min_level; use_json }

let set_min_level (l : t) (lvl : log_level) = l.min_level <- lvl
let set_use_json (l : t) (uj : bool) = l.use_json <- uj

let log_message (l : t) (lvl : log_level) (msg : string) : unit =
  if level_weight lvl >= level_weight l.min_level then begin
    let now = Unix.gettimeofday () in
    let tm = Unix.localtime now in
    let time_str = Printf.sprintf "%02d:%02d:%02d.%03d"
        tm.tm_hour tm.tm_min tm.tm_sec (int_of_float ((now -. floor now) *. 1000.0)) in
    let scope_path = Scope.path (Context.scope l.ctx) in
    if l.use_json then begin
      let json_line = Printf.sprintf "{\"time\":\"%s\",\"level\":\"%s\",\"scope\":\"%s\",\"msg\":\"%s\"}\n"
          time_str (string_of_log_level lvl) scope_path (String.escaped msg) in
      output_string stdout json_line;
      flush stdout
    end else begin
      let color = ansi_color lvl in
      Printf.printf "%s%s [%5s] [%s] %s%s\n"
        color time_str (string_of_log_level lvl) scope_path msg ansi_reset;
      flush stdout
    end
  end

let debug l fmt = Printf.ksprintf (log_message l Debug) fmt
let info l fmt = Printf.ksprintf (log_message l Info) fmt
let warn l fmt = Printf.ksprintf (log_message l Warn) fmt
let error l fmt = Printf.ksprintf (log_message l Error) fmt
let fatal l fmt = Printf.ksprintf (log_message l Fatal) fmt
