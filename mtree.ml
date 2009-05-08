type id = string

type node =
  { id : id
  ; latex : Latex.t
  ; suffixes : Latex.element array }

let node_of id latex =
    { id = id
    ; latex = latex
    ; suffixes = Edit.suffixes latex }

let query_dist a b = Edit.left_edit_distance a.suffixes b.suffixes

type branch =
  { neither : mtree
  ; left : mtree
  ; right : mtree
  ; both : mtree }

and mtree =
  | Empty
  | Element of node
  | Branch of node * node * int * branch

let empty = Empty

let empty_branch =
  { left = empty
  ; both = empty
  ; right = empty
  ; neither = empty }

let rec add e mtree =
(*   print_string "\n"; flush stdout; *)
  let rec addE mtree =
(*     print_string "."; flush stdout; *)
    match mtree with
    | Empty -> Element e
    | Element e' ->
        Branch (e, e', (query_dist e e'), empty_branch)
    | Branch (l,r,radius,branch) ->
        let branch = match ((query_dist e l) < radius, (query_dist e r) < radius) with
          | (false,false) -> {branch with neither = addE branch.neither}
          | (true, false) -> {branch with left    = addE branch.left}
          | (false,true ) -> {branch with right   = addE branch.right}
          | (true, true ) -> {branch with both    = addE branch.both} in
        Branch (l,r,radius,branch) in
   addE mtree

let delete id mtree = mtree
(*  let rec del mtree =
    match mtree with
    | Empty -> Empty
    | Element e ->
        if e.id = id
        then Empty
        else Element e
    | Branch (l,r,radius,branch) ->

          let branch = match ((dist e l) < radius, (dist e r) < radius) with
            | (false,false) -> {branch with neither = addE branch.neither}
            | (true, false) -> {branch with left    = addE branch.left}
            | (false,true ) -> {branch with right   = addE branch.right}
            | (true, true ) -> {branch with both    = addE branch.both} in
          Branch (l,r,radius,branch) in
   addE mtree*)

type search =
  { target : node
  ; unsearched : (mtree, int) Pqueue.t
  ; sorting : (id, int) Pqueue.t
  ; sorted : (id, int) Pqueue.t
  ; min_dist : int}

let search latex mtree =
  let e = node_of "" latex in
  { target = e
  ; unsearched =
      (match mtree with
        | Empty -> Pqueue.empty
        | _ -> Pqueue.add mtree 0 Pqueue.empty)
  ; sorting = Pqueue.empty
  ; sorted = Pqueue.empty
  ; min_dist = 0 }

let insert_result e dist cutoff search =
  if dist < cutoff
  then
    if dist < search.min_dist
    then {search with sorted = Pqueue.add e dist search.sorted}
    else {search with sorting = Pqueue.add e dist search.sorting}
  else search

let update_min_dist dist search =
  let min_dist = max search.min_dist dist in
  let (safe_results,rest) = Pqueue.split_at_priority min_dist search.sorting in
  {search with sorted = search.sorted @ safe_results; sorting = rest; min_dist = min_dist}

let next_search_node cutoff search =
  if search.min_dist > cutoff
  then None
  else
    match Pqueue.pop search.unsearched with
      | None -> None
      | Some ((mtree,dist),unsearched) ->
          Some (mtree, update_min_dist dist {search with unsearched = unsearched})

type result =
  | More of (id * int) list * search
  | Last of (id * int) list

let next k cutoff search =
  let rec loop search =
    match Pqueue.split_at_length k (search.sorted) with
      (* We have enough results to return *)
      | Some (results,rest) -> More (results, {search with sorted = rest})
      (* We need to carry on searching *)
      | None ->
          match next_search_node cutoff search with
            (* Nothing left to search *)
            | None ->
                (match search.sorting with
                  | [] -> Last (Pqueue.to_list search.sorted)
                  | _ -> loop {search with sorted = Pqueue.append search.sorted search.sorting; sorting = Pqueue.empty})
            (* Search in mtree *)
            | Some (mtree,search) ->
                match mtree with
                  | Empty -> loop search
                  | Element e -> loop (insert_result e.id (query_dist search.target e) cutoff search)
                  | Branch (l,r,radius,branch) ->
                      let distL = query_dist search.target l in
                      let distR = query_dist search.target r in
                      loop
                      (insert_result l.id distL cutoff
                      (insert_result r.id distR cutoff
                      {search with unsearched =
                        (Pqueue.add branch.neither 0
                        (Pqueue.add branch.left (distL - radius)
                        (Pqueue.add branch.right (distR - radius)
                        (Pqueue.add branch.both ((max distL distR) - radius)
                        search.unsearched))))})) in
  loop search

let print mtree =
  let rec loop space mtree =
    print_string space;
    match mtree with
      | Empty -> print_string "( )\n"
      | Element _ -> print_string "(*)\n"
      | Branch (_,_,radius,branch) ->
          print_int radius; print_string "|\\\n";
          let space = "  "^space in
          loop space branch.neither;
          loop space branch.left;
          loop space branch.right;
          loop space branch.both in
  loop "" mtree