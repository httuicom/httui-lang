(* JSON values from a block's last successful response, supplied by the
   caller as pure data (the IO shell parses storage JSON into this ADT).
   Navigation is STRICT — it mirrors the runtime resolver exactly, so a
   [None] here simply means "no value preview", never a diagnostic. *)

type t =
  | Null
  | Bool of bool
  | Number of string  (** verbatim literal — no float round-trip *)
  | String of string
  | Array_ of t list
  | Object_ of (string * t) list

let is_index seg =
  seg <> "" && String.for_all (fun c -> c >= '0' && c <= '9') seg

(* db view at the response level: results/messages/stats pass through,
   a numeric segment indexes [results], a bare key reads the first
   result's first row *)
let db_view_get fields seg =
  let results =
    match List.assoc_opt "results" fields with
    | Some (Array_ rs) -> rs
    | _ -> []
  in
  if List.mem seg [ "results"; "messages"; "stats" ] then
    List.assoc_opt seg fields
  else if is_index seg then List.nth_opt results (int_of_string seg)
  else
    match results with
    | Object_ first :: _ -> (
        match List.assoc_opt "rows" first with
        | Some (Array_ (Object_ row :: _)) -> List.assoc_opt seg row
        | _ -> None)
    | _ -> None

let rec nav value ~db_view i = function
  | [] -> Some value
  | seg :: rest -> (
      match value with
      | Object_ fields when db_view -> (
          match db_view_get fields seg with
          | Some next -> nav next ~db_view:false (i + 1) rest
          | None -> None)
      | Object_ fields -> (
          match List.assoc_opt seg fields with
          | Some next -> nav next ~db_view:false (i + 1) rest
          | None -> None)
      | Array_ items when is_index seg -> (
          match List.nth_opt items (int_of_string seg) with
          | Some next -> nav next ~db_view:false (i + 1) rest
          | None -> None)
      | _ -> None)

let resolve_ref ~response ~status ~db segments =
  match segments with
  | "response" :: rest -> nav response ~db_view:db 0 rest
  | [ "status" ] -> Some (String status)
  | _ -> None

let resolve_prev ~response ~db segments = nav response ~db_view:db 0 segments

(* compact single-line rendering, truncated for hover use *)
let preview ?(max_len = 120) value =
  let buf = Buffer.create 64 in
  let full = ref true in
  let add s = if Buffer.length buf <= max_len then Buffer.add_string buf s in
  let rec go = function
    | Null -> add "null"
    | Bool b -> add (string_of_bool b)
    | Number n -> add n
    | String s -> add (Printf.sprintf "%S" s)
    | Array_ items ->
        add "[";
        List.iteri
          (fun i v ->
            if i > 0 then add ", ";
            go v)
          items;
        add "]"
    | Object_ fields ->
        add "{";
        List.iteri
          (fun i (k, v) ->
            if i > 0 then add ", ";
            add (k ^ ": ");
            go v)
          fields;
        add "}"
  in
  go value;
  if Buffer.length buf > max_len then full := false;
  let s = Buffer.contents buf in
  if !full then s else String.sub s 0 max_len ^ "…"
