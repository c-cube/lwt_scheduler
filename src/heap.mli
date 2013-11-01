(*
Copyright (c) 2013, Simon Cruanes
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.  Redistributions in binary
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

(** {1 Heap structure} *)

type 'a t
  (** Mutable heap of values of type 'a. *)

val empty : cmp:('a -> 'a -> int) -> 'a t
  (** New empty heap, using the given comparison function to compare values *)

val copy : 'a t -> 'a t
  (** Copy of the heap *)

val is_empty : _ t -> bool
  (** Is the heap empty? *)

val insert : 'a t -> 'a -> unit
  (** Insert a new value in the heap *)

val min : 'a t -> 'a
  (** Smallest value in the heap.
      @raise Invalid_argument if the heap is empty *)

val min_opt : 'a t -> 'a option
  (** Non-raising version of {!min} *)

val pop : 'a t -> 'a
  (** Pop the smallest value from the heap and returns it.
      @raise Invalid_argument if the heap is empty *)

val remove : 'a t -> unit
  (** Remove the top element and discard it.
      @raise Invalid_argument if the heap is empty *)

val pop_opt : 'a t -> 'a option
  (** Same as {!pop}, but returns [None] if the heap is empty *)
