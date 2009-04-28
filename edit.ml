open Util
open Tree
open Metric

let rec edit_distance cached fL fR =
  match (fL,fR) with
    | ([], []) -> 0.0
    | ([], cR::csR) -> 1.0
(*        (match cR with
          | Branch (labelR,children) ->
              (metric None (Some labelR)) +. (cached [] (children @ csR)))*)
    | (cL::csL, []) -> 1.0
(*        (match cL with
          | Branch (labelL,children) ->
              (metric (Some labelL) None) +. (cached (children @ csL) []))*)
    | (cL::csL, cR::csR) ->
        minimum [
          match cR with
            | Branch (labelR,childrenR) ->
                (metric None (Some labelR)) +. (cached fL (childrenR @ csR)) ;
          match cL with
            | Branch (labelL,childrenL) ->
                (metric (Some labelL) None) +. (cached (childrenL @ csL) fR) ;
          match (cL,cR) with
            | (Branch (labelL,childrenL), Branch (labelR,childrenR)) ->
                (metric (Some labelL) (Some labelR)) +. (cached (childrenL @ csL) (childrenR @ csR)) ]

let rec left_edit_distance cached fL fR =
  match (fL,fR) with
    | ([], []) -> 0.0
    | ([], csR) -> 1.0
(*        (match cR with
          | Branch (labelR,children) ->
              (metric None (Some labelR)) +. (cached [] (children @ csR)))*)
    | (csL, []) -> Metric.cost_of_forest csL
    | (cL::csL, cR::csR) ->
        minimum [
          match cR with
            | Branch (labelR,childrenR) ->
                (metric None (Some labelR)) +. (cached fL (childrenR @ csR)) ;
          match cL with
            | Branch (labelL,childrenL) ->
                (metric (Some labelL) None) +. (cached (childrenL @ csL) fR) ;
          match (cL,cR) with
            | (Branch (labelL,childrenL), Branch (labelR,childrenR)) ->
                (metric (Some labelL) (Some labelR)) +. (cached (childrenL @ csL) (childrenR @ csR)) ]