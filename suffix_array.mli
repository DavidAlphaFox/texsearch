type id = int
type pos = int

type 'a t = 
  { latexs : Latex.t DynArray.t 
  ; opaques : 'a DynArray.t
  ; mutable next_id : id
  ; mutable array : (id * pos) array 
  ; mutable unsorted :  ('a * Latex.t) list }

val create : unit -> 'a t
val add : 'a t -> ('a * Latex.t) list -> unit
val prepare : 'a t -> unit
val find_exact : 'a t -> Latex.t -> 'a list
val find_approx : 'a t -> Latex.t -> int -> (int * 'a) list
