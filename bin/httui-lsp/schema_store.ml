(* Read-only access to the inferred response shapes the executor writes
   for each (file, alias) on successful runs. Queried per request: reads
   are tens of microseconds and shapes change whenever the user runs a
   block. Values never reach this process — a shape carries field names
   and type names only. *)

(* Must match the executor's writer; rows under another version are a
   cache miss and rebuild on the next run. *)
let cache_schema_version = 1

let shapes_query =
  let open Caqti_request.Infix in
  (Caqti_type.int ->* Caqti_type.(t3 string string string))
    "SELECT file_path, alias, shape FROM block_schema_cache WHERE \
     cache_schema_version = ?"

let rec shape_of_json : Yojson.Safe.t -> Httui_lang.Shape.t = function
  | `String s -> Scalar s
  | `List [] -> Array_ None
  | `List (x :: _) -> Array_ (Some (shape_of_json x))
  | `Assoc fields ->
      Object_ (List.map (fun (k, v) -> (k, shape_of_json v)) fields)
  | _ -> Scalar "unknown"

(* Writers disagree on the key: some store the note's absolute path,
   others a vault-relative one. The server only knows the absolute path
   (from the document URI), so a row matches on equality or when the
   absolute path ends in "/" + the stored relative path. The filter runs
   client-side: the table holds one small row per executed alias. *)
let row_matches ~file_path stored =
  (* document URIs yield backslash paths on Windows *)
  let normalize p = String.map (fun c -> if c = '\\' then '/' else c) p in
  let file_path = normalize file_path and stored = normalize stored in
  stored = file_path || String.ends_with ~suffix:("/" ^ stored) file_path

(** [(alias, shape)] pairs inferred for the document at absolute path
    [file_path]; [[]] when no database was configured or the read fails
    (analysis degrades gracefully — shapes are an enrichment, not a requirement)
*)
let shapes_for ~file_path =
  match Db_conn.connect () with
  | None -> []
  | Some conn -> (
      let module C = (val conn : Caqti_blocking.CONNECTION) in
      match C.collect_list shapes_query cache_schema_version with
      | Error _ -> []
      | Ok rows ->
          rows
          |> List.filter_map (fun (stored, alias, shape_json) ->
              if not (row_matches ~file_path stored) then None
              else
                match Yojson.Safe.from_string shape_json with
                | exception _ -> None
                | j -> Some (alias, shape_of_json j)))
