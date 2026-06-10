(* Single lazily-opened read-only connection to the app database, shared
   by every store in this process. No configured path simply yields no
   connection: analysis runs without storage enrichment. *)

let db_uri = ref None

let configure path =
  db_uri := Some (Uri.of_string ("sqlite3:" ^ path ^ "?busy_timeout=5000"))

let connection = ref None

let connect () =
  match !connection with
  | Some c -> Some c
  | None -> (
      match !db_uri with
      | None -> None
      | Some uri -> (
          match Caqti_blocking.connect uri with
          | Ok c ->
              connection := Some c;
              Some c
          | Error _ -> None))
