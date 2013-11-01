
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

(** {1 Time Scheduler}

The scheduler can be used to run {b tasks}.  When a task is scheduled, it
returns a future. Cancelling the future allows to cancel the task.

A scheduler is {b not} thread-safe.
*)

type 'a task = unit -> 'a Lwt.t
  (** A task that can be scheduled in the future. It returns a
      future value, but is only evaluated some time in the future.
      A task may be called several times (see for instance {!repeat}) *)

val at : float -> 'a task -> 'a Lwt.t
  (** Run at the given Unix timestamp. If the timestamp is already in
      the past, then the task is run right now. *)

val after : float -> 'a task -> 'a Lwt.t
  (** [after s task] schedules the task to run in [s] seconds. *)

val repeat : ?after:float -> every:float ->
             'a task -> unit Lwt.t
  (** Run the task repeatedly, with a given time period (in seconds).

      @return a future that never returns, unless it is cancelled.
      @param after: delay before the first occurrence of the task occurs
      @param every: period, in seconds, between two repetitions.
  *)

val wait_until : check:(unit -> bool Lwt.t) -> 'a task -> 'a Lwt.t
  (** [wait_until check task] repeatedly calls [check ()], waits for its
      result, and:
      - if the result is true, call the task and return it
      - otherwise loop
  *)

val whenever : check:(unit -> bool Lwt.t) -> 'a task -> unit Lwt.t
  (** Repeated version of {!wait_until}. Once the task is finished,
      it waits again for [check ()] to return [true]. *)

val while_ : check:(unit -> bool Lwt.t) -> unit task -> unit Lwt.t
  (** Runs the task, wait for it to complete, as long as [check ()]
      returns [false]. [check ()] is called before the first iteration. *)
