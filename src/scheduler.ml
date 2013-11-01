
(*
copyright (c) 2013, simon cruanes
all rights reserved.

redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.  redistributions in binary
form must reproduce the above copyright notice, this list of conditions and the
following disclaimer in the documentation and/or other materials provided with
the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

(** {1 Time Scheduler} *)

let (>>=) = Lwt.bind

type 'a task = unit -> 'a Lwt.t

type scheduled = {
  run : unit -> unit;   (* which task to run *)
  timestamp : float;    (* time to run the task *)
  id : int;             (* unique id *)
  mutable cancelled : bool; (* cancelled? *)
}

(* compare two scheduled tasks *)
let cmp sc1 sc2 =
  let c = Pervasives.compare sc1.timestamp sc2.timestamp in
  if c <> 0 then c else sc1.id - sc2.id

type t = {
  heap : scheduled Heap.t; (* scheduled tasks *)
  mutable next_id : int;        (* used to generate unique IDs *)
}

let create () =
  let sched = {
    heap = Heap.empty ~cmp;
    next_id = 0;
  } in
  sched

let default = create ()

(* fresh task ID *)
let _next_id sched =
  let n = sched.next_id in
  sched.next_id <- n+1;
  n

(* next time we need to wake up to run some task *)
let _next_time sched =
  try
    let s = Heap.min sched.heap in
    s.timestamp
  with Invalid_argument _ ->
    max_float

(* check whether there are some tasks to run *)
let _check_tasks sched =
  let rec check_min () =
    let continue_ =
      try
        let scheduled = Heap.min sched.heap in
        let now = Unix.gettimeofday () in
        if scheduled.timestamp <= now
          then begin
            (* task happens now. Remove it, and run it if not cancelled *)
            Heap.remove sched.heap;
            if not scheduled.cancelled
              then scheduled.run ();
            true
          end else false
      with Invalid_argument _ -> false
    in
    if continue_ then check_min ()
  in
  check_min ()

(* runs task at given time, or right now if time is passed *)
let _at sched time task =
  let now = Unix.gettimeofday () in
  if time <= now
    then task ()
    else begin
      let next = _next_time sched in
      (* make a cancellable thread that can be started with [promise] *)
      let fut, promise = Lwt.task () in
      (* schedule the task itself *)
      let scheduled = {
        timestamp = time;
        id = _next_id sched;
        run = (fun () -> Lwt.wakeup promise ());
        cancelled = false;
      } in
      Heap.insert sched.heap scheduled;
      (* fut': the future result of the task *)
      let fut' = fut >>= fun () -> task () in
      (* cancel lwt thread -> cancel task *)
      Lwt.on_failure fut' (function
        | Lwt.Canceled -> scheduled.cancelled <- true
        | _ -> ());
      (* if the task is early enough*)
      if time < next
        then begin
          let check = Lwt_unix.sleep (time -. now) in
          Lwt.on_success check (fun () -> _check_tasks sched);
        end;
      fut'
    end

let at ?(sched=default) time task =
  _at sched time task

let after ?(sched=default) duration task =
  let now = Unix.gettimeofday () in
  _at sched (now +. duration) task

let repeat ?(sched=default) ?after ~every task =
  (* recursively do the task *)
  let rec step () =
    Lwt_unix.sleep every >>= fun () ->
    task () >>= fun _ ->
    step ()
  in
  (* start the loop within a cancellable task *)
  let fut, promise = Lwt.task () in
  let fut' = match after with
  | None -> fut >>= fun () -> step()
  | Some duration -> fut >>= fun () -> Lwt_unix.sleep duration >>= fun () -> step()
  in
  Lwt.wakeup promise (); 
  fut'

let wait_until ~check task =
  let rec step () =
    check () >>= function
    | false -> step()
    | true -> task ()
  in
  let fut, promise = Lwt.task () in
  let fut' = fut >>= step in
  Lwt.wakeup promise ();
  fut'

let whenever ~check task =
  let rec step () =
    check () >>= function
    | false -> step()
    | true -> task () >>= fun _ -> step()
  in
  let fut, promise = Lwt.task () in
  let fut' = fut >>= step in
  Lwt.wakeup promise ();
  fut'

let while_ ~check task =
  let rec step () =
    check () >>= function
    | true -> task () >>= fun _ -> step()
    | false -> Lwt.return_unit (* exit loop *)
  in
  let fut, promise = Lwt.task () in
  let fut' = fut >>= step in
  Lwt.wakeup promise ();
  fut'
