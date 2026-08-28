(* timer.ml - Lifecycle-Bound Timers Implementation *)

open Cordis_core.Types
open Cordis_core

type timer_task = {
  id : int;
  scope : Scope.t;
  mutable target_time : float;
  period : float option;
  callback : unit -> unit;
  mutable cancelled : bool;
}

let counter = ref 0
let active_tasks : (int, timer_task) Hashtbl.t = Hashtbl.create 64

let timeout (ctx : Context.t) (delay_sec : float) (callback : unit -> unit) : disposable =
  let sc = Context.scope ctx in
  Scope.assert_active sc;
  incr counter;
  let tid = !counter in
  let now = Unix.gettimeofday () in
  let task = {
    id = tid;
    scope = sc;
    target_time = now +. delay_sec;
    period = None;
    callback;
    cancelled = false;
  } in
  Hashtbl.replace active_tasks tid task;

  let cancel () =
    task.cancelled <- true;
    Hashtbl.remove active_tasks tid
  in
  Scope.add_disposable sc cancel

let interval (ctx : Context.t) (period_sec : float) (callback : unit -> unit) : disposable =
  let sc = Context.scope ctx in
  Scope.assert_active sc;
  incr counter;
  let tid = !counter in
  let now = Unix.gettimeofday () in
  let task = {
    id = tid;
    scope = sc;
    target_time = now +. period_sec;
    period = Some period_sec;
    callback;
    cancelled = false;
  } in
  Hashtbl.replace active_tasks tid task;

  let cancel () =
    task.cancelled <- true;
    Hashtbl.remove active_tasks tid
  in
  Scope.add_disposable sc cancel

let debounce (ctx : Context.t) (delay_sec : float) (fn : 'a -> unit) : ('a -> unit) =
  let sc = Context.scope ctx in
  let current_disp = ref None in
  (fun arg ->
     (match !current_disp with Some d -> d () | None -> ());
     if Scope.is_active sc then
       current_disp := Some (timeout ctx delay_sec (fun () -> fn arg)))

let throttle (ctx : Context.t) (delay_sec : float) (fn : 'a -> unit) : ('a -> unit) =
  let sc = Context.scope ctx in
  let last_run = ref 0.0 in
  (fun arg ->
     if Scope.is_active sc then begin
       let now = Unix.gettimeofday () in
       if now -. !last_run >= delay_sec then begin
         last_run := now;
         fn arg
       end
     end)

let heartbeat (ctx : Context.t) (period_sec : float) (fn : float -> unit) : disposable =
  interval ctx period_sec (fun () -> fn (Unix.gettimeofday ()))

let tick (current_time : float) : unit =
  let to_run = ref [] in
  Hashtbl.iter (fun tid task ->
    if not task.cancelled && Scope.is_active task.scope then begin
      if current_time >= task.target_time then
        to_run := task :: !to_run
    end else
      Hashtbl.remove active_tasks tid
  ) active_tasks;

  List.iter (fun task ->
    if not task.cancelled && Scope.is_active task.scope then begin
      (try task.callback () with _ -> ());
      match task.period with
      | Some p -> task.target_time <- current_time +. p
      | None ->
        task.cancelled <- true;
        Hashtbl.remove active_tasks task.id
    end
  ) !to_run
