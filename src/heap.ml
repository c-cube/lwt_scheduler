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

(** {1 Heap structure}

Simple implementation from http://en.wikipedia.org/wiki/Skew_heap
*)

type 'a t = {
  mutable tree : 'a tree;
  cmp : 'a -> 'a -> int;
} (** A pairing tree heap with the given comparison function *)
and 'a tree =
  | Empty
  | Node of 'a * 'a tree * 'a tree

let empty ~cmp = {
  tree = Empty;
  cmp;
}

let copy h = { h with tree=h.tree; }

let is_empty h =
  match h.tree with
  | Empty -> true
  | Node _ -> false

let rec union ~cmp t1 t2 = match t1, t2 with
| Empty, _ -> t2
| _, Empty -> t1
| Node (x1, l1, r1), Node (x2, l2, r2) ->
  if cmp x1 x2 <= 0
    then Node (x1, union ~cmp t2 r1, l1)
    else Node (x2, union ~cmp t1 r2, l2)

let insert h x =
  h.tree <- union ~cmp:h.cmp (Node (x, Empty, Empty)) h.tree

let min h = match h.tree with
  | Empty -> raise (Invalid_argument "Heap.min")
  | Node (x, _, _) -> x

let min_opt h = match h.tree with
  | Empty -> None
  | Node (x, _, _) -> Some x

let pop h = match h.tree with
  | Empty -> raise (Invalid_argument "Heap.pop")
  | Node (x, l, r) ->
    h.tree <- union ~cmp:h.cmp l r;
    x

let remove h = ignore (pop h)

let pop_opt h = match h.tree with
  | Empty -> None
  | Node (x, l, r) ->
    h.tree <- union ~cmp:h.cmp l r;
    Some x
