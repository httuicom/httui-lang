(* Read-only access to the cached DB column schema (tables → columns → type)
   the app introspects per connection. Powers schema-aware SQL completion in
   ```db-* blocks. Keyed by connection_id — the suffix of the `db-<conn>`
   fence info string. Reads degrade gracefully: no database / read error /
   cold cache all yield [[]] and completion simply offers no tables. *)

(* Returns [Httui_lang.Sql.table]s directly so the completion function can
   consume them without an adapter. *)
module S = Httui_lang.Sql

let schema_query =
  let open Caqti_request.Infix in
  (Caqti_type.string
  ->* Caqti_type.(t4 (option string) string string (option string)))
    "SELECT schema_name, table_name, column_name, data_type FROM schema_cache \
     WHERE connection_id = ? ORDER BY schema_name IS NULL, schema_name, \
     table_name, column_name"

(* Group the column rows (ordered by schema then table) into table records.
   A new table starts whenever (schema_name, table_name) changes. *)
let group_rows rows =
  let finish schema name cols = S.{ schema; name; columns = List.rev cols } in
  let rec go acc current = function
    | [] -> (
        match current with
        | None -> List.rev acc
        | Some (schema, name, cols) -> List.rev (finish schema name cols :: acc)
        )
    | (schema, table_name, column_name, data_type) :: rest -> (
        let col = S.{ name = column_name; data_type } in
        match current with
        | Some (cs, cn, cols) when cs = schema && cn = table_name ->
            go acc (Some (cs, cn, col :: cols)) rest
        | Some (cs, cn, cols) ->
            go (finish cs cn cols :: acc)
              (Some (schema, table_name, [ col ]))
              rest
        | None -> go acc (Some (schema, table_name, [ col ])) rest)
  in
  go [] None rows

let tables_for ~connection_id =
  match Db_conn.connect () with
  | None -> []
  | Some conn -> (
      let module C = (val conn : Caqti_blocking.CONNECTION) in
      match C.collect_list schema_query connection_id with
      | Error _ -> []
      | Ok rows -> group_rows rows)
