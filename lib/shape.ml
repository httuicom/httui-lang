(* Structural skeleton of a block's last successful response, as written
   by the executor into storage: objects keep their keys, arrays keep one
   sampled element, scalars are their type name. Path resolution mirrors
   the runtime navigation rules, so a miss reported here means the ref
   would also fail to resolve at run time. The shape is an inference
   from the LAST run — consumers must treat misses as warnings, never
   errors. *)

type t =
  | Scalar of string  (** "string" | "number" | "boolean" | "null" *)
  | Array_ of t option  (** sampled element; [None] = empty array sample *)
  | Object_ of (string * t) list

let rec type_name = function
  | Scalar s -> s
  | Array_ None -> "array"
  | Array_ (Some el) -> "array<" ^ type_name el ^ ">"
  | Object_ _ -> "object"

(* Named refs navigate from an envelope holding the response and the
   execution status, not from the response value itself. *)
let envelope response =
  Object_ [ ("response", response); ("status", Scalar "string") ]

type resolution =
  | Found of t
  | Missing of { index : int; segment : string; available : string list }
      (** segment [index] names no field at its level *)
  | Not_object of { index : int; segment : string; parent : string }
      (** segment [index] tries to enter a scalar *)
  | Opaque  (** verification impossible (e.g. empty array sample) *)

(* DB responses are navigated through a runtime view that, at the
   response level, also accepts a bare column name of the first result's
   first row. Resolution must accept the same names or every legacy ref
   would be flagged. *)
let db_first_row_fields fields =
  match List.assoc_opt "results" fields with
  | Some (Array_ (Some (Object_ rs))) -> (
      match List.assoc_opt "rows" rs with
      | Some (Array_ (Some (Object_ row))) -> `Row row
      | Some (Array_ _) -> `Unverifiable
      | _ -> `No_view)
  | Some (Array_ None) -> `Unverifiable
  | _ -> `No_view

let is_index seg =
  seg <> "" && String.for_all (fun c -> c >= '0' && c <= '9') seg

(* [db] arms the first-row view when the [response] segment is entered
   at depth 0 (named refs); [db_view] is the view state at the current
   level ([$prev] starts directly at the response, so its caller arms
   it at depth 0). *)
let rec walk shape ~db ~db_view i = function
  | [] -> Found shape
  | seg :: rest -> (
      match shape with
      (* a numeric segment consumes one array level; [0]-style index
         access is invisible in the segment list, so any other segment
         enters the array through its sampled element *)
      | Array_ (Some el) ->
          if is_index seg then walk el ~db ~db_view (i + 1) rest
          else walk el ~db ~db_view i (seg :: rest)
      | Array_ None -> Opaque
      | Scalar _ ->
          Not_object { index = i; segment = seg; parent = type_name shape }
      | Object_ fields -> (
          let next_db_view = db && i = 0 && seg = "response" in
          match List.assoc_opt seg fields with
          | Some next -> walk next ~db ~db_view:next_db_view (i + 1) rest
          | None -> (
              if not db_view then
                Missing
                  { index = i; segment = seg; available = List.map fst fields }
              else
                match db_first_row_fields fields with
                | `Row row -> (
                    match List.assoc_opt seg row with
                    | Some next -> walk next ~db ~db_view:false (i + 1) rest
                    | None ->
                        Missing
                          {
                            index = i;
                            segment = seg;
                            available = List.map fst fields @ List.map fst row;
                          })
                | `Unverifiable -> Opaque
                | `No_view ->
                    Missing
                      {
                        index = i;
                        segment = seg;
                        available = List.map fst fields;
                      })))

let resolve_ref ~response ~db segments =
  walk (envelope response) ~db ~db_view:false 0 segments

(* [$prev] roots navigation at the response itself — no envelope, no
   [.response] segment. *)
let resolve_prev ~response ~db segments =
  walk response ~db:false ~db_view:db 0 segments

let fields_of_resolution = function
  | Found shape -> (
      let rec element = function Array_ (Some el) -> element el | s -> s in
      match element shape with Object_ fields -> Some fields | _ -> None)
  | Missing _ | Not_object _ | Opaque -> None

(* fields reachable after [segments] (all complete), for path
   completion; [None] when the level cannot be verified or is not an
   object *)
let fields_at ~response ~db segments =
  fields_of_resolution (resolve_ref ~response ~db segments)

let fields_at_prev ~response ~db segments =
  fields_of_resolution (resolve_prev ~response ~db segments)

let edit_distance a b =
  let la = String.length a and lb = String.length b in
  let d = Array.make_matrix (la + 1) (lb + 1) 0 in
  for i = 0 to la do
    d.(i).(0) <- i
  done;
  for j = 0 to lb do
    d.(0).(j) <- j
  done;
  for i = 1 to la do
    for j = 1 to lb do
      let cost = if a.[i - 1] = b.[j - 1] then 0 else 1 in
      d.(i).(j) <-
        min
          (min (d.(i - 1).(j) + 1) (d.(i).(j - 1) + 1))
          (d.(i - 1).(j - 1) + cost)
    done
  done;
  d.(la).(lb)

(* closest candidate within an edit distance proportional to the
   segment's length — short names only tolerate one edit, or every
   two-letter field would "suggest" another *)
let suggest segment candidates =
  let max_d = if String.length segment <= 4 then 1 else 2 in
  candidates
  |> List.filter_map (fun c ->
      let d = edit_distance segment c in
      if d > 0 && d <= max_d then Some (d, c) else None)
  |> List.sort compare
  |> function
  | [] -> None
  | (_, c) :: _ -> Some c
