(* Read-only access to the latest successful response per (file, alias),
   feeding hover value previews. Metadata is scanned first and the body
   fetched per matching row; bodies above the size cap are skipped so
   hover latency stays flat. *)

let size_cap = 524_288

let meta_query =
  let open Caqti_request.Infix in
  (Caqti_type.unit ->* Caqti_type.(t3 int string string))
    "SELECT id, file_path, alias FROM block_results WHERE alias IS NOT NULL \
     AND status = 'success' ORDER BY id DESC"

let body_query =
  let open Caqti_request.Infix in
  (Caqti_type.(t2 int int) ->? Caqti_type.(t2 string string))
    "SELECT status, response FROM block_results WHERE id = ? AND \
     LENGTH(response) <= ?"

let rec value_of_json : Yojson.Safe.t -> Httui_lang.Json_value.t = function
  | `Null -> Null
  | `Bool b -> Bool b
  | `Int i -> Number (string_of_int i)
  | `Intlit s -> Number s
  | `Float f -> Number (Yojson.Safe.to_string (`Float f))
  | `String s -> String s
  | `List l -> Array_ (List.map value_of_json l)
  | `Assoc fields ->
      Object_ (List.map (fun (k, v) -> (k, value_of_json v)) fields)

(** [(alias, (response, status))] for the latest successful run of each alias in
    the document at absolute path [file_path]; degrades to [[]] like the other
    stores *)
let values_for ~file_path =
  match Db_conn.connect () with
  | None -> []
  | Some conn -> (
      let module C = (val conn : Caqti_blocking.CONNECTION) in
      match C.collect_list meta_query () with
      | Error _ -> []
      | Ok rows ->
          let latest =
            List.fold_left
              (fun acc (id, stored, alias) ->
                if
                  Schema_store.row_matches ~file_path stored
                  && not (List.mem_assoc alias acc)
                then (alias, id) :: acc
                else acc)
              [] rows
          in
          latest
          |> List.filter_map (fun (alias, id) ->
              match C.find_opt body_query (id, size_cap) with
              | Ok (Some (status, response)) -> (
                  match Yojson.Safe.from_string response with
                  | exception _ -> None
                  | j -> Some (alias, (value_of_json j, status)))
              | _ -> None))
