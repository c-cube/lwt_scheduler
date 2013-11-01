
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

let at time task =
  let now = Unix.gettimeofday() in
  if time <= now
    then task ()
    else Lwt_unix.sleep (time -. now) >>= fun () -> task ()

let after duration task =
  let now = Unix.gettimeofday () in
  at (now +. duration) task

let repeat ?after ~every task =
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
