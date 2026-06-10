(* Read-only access to environment variable NAMES in the app database.
   Values are never read by this process — secret or not, they belong to
   the execution path only. Queried per request: reads were measured in
   the tens of microseconds and the active environment can change while
   the server runs. *)

let keys_query =
  let open Caqti_request.Infix in
  (Caqti_type.unit ->* Caqti_type.(t2 string bool))
    "SELECT v.key, v.is_secret FROM env_variables v JOIN environments e ON \
     e.id = v.environment_id WHERE e.is_active = 1 ORDER BY v.key"

(** [(key, is_secret)] pairs of the active environment; [[]] when no database
    was configured or the read fails (analysis degrades gracefully — env names
    are an enrichment, not a requirement) *)
let keys () =
  match Db_conn.connect () with
  | None -> []
  | Some conn -> (
      let module C = (val conn : Caqti_blocking.CONNECTION) in
      match C.collect_list keys_query () with Ok l -> l | Error _ -> [])
