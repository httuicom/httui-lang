(* Environment variable NAMES from the vault's file-backed env store.
   Source of truth is [<vault>/envs/<name>.toml] ([vars] + [secrets]
   sections); the active env per vault lives in the per-machine
   user.toml. Only names leave this module — and [secrets] values in
   env files are keychain references by contract, so secret material is
   not even on disk here. Read per request: the files are tiny and the
   active env can change while the server runs. *)

let ( / ) = Filename.concat

(* nearest ancestor of [dir] containing an [envs/] directory *)
let rec find_vault_root dir =
  let envs = dir / "envs" in
  if Sys.file_exists envs && Sys.is_directory envs then Some dir
  else
    let parent = Filename.dirname dir in
    if parent = dir then None else find_vault_root parent

(* Mirrors the resolution used by the app (XDG override, then the
   platform config dir). *)
let user_config_path () =
  let candidates =
    (match Sys.getenv_opt "XDG_CONFIG_HOME" with
      | Some x when x <> "" -> [ x / "httui" / "user.toml" ]
      | _ -> [])
    @ (match Sys.getenv_opt "HOME" with
      | Some h ->
          [
            h / "Library" / "Application Support" / "httui" / "user.toml";
            h / ".config" / "httui" / "user.toml";
          ]
      | None -> [])
    @
    match Sys.getenv_opt "APPDATA" with
    | Some a when a <> "" -> [ a / "httui" / "user.toml" ]
    | _ -> []
  in
  List.find_opt Sys.file_exists candidates

let table_of_file path =
  if not (Sys.file_exists path) then None
  else
    match Toml.Parser.from_filename path with
    | `Ok t -> Some t
    | `Error _ -> None
    | exception _ -> None

let find_key key table =
  Toml.Types.Table.find_opt (Toml.Types.Table.Key.of_string key) table

let sub_table key table =
  match find_key key table with
  | Some (Toml.Types.TTable t) -> Some t
  | _ -> None

(* document URIs yield backslash paths on Windows; the app records
   vault paths the same way, but normalize both sides anyway *)
let normalize p = String.map (fun c -> if c = '\\' then '/' else c) p

(* URI-to-path conversions sometimes keep a leading slash before a
   Windows drive letter ("/C:/x"); the filesystem rejects that form *)
let strip_drive_slash p =
  if
    String.length p >= 3
    && p.[0] = '/'
    && ((p.[1] >= 'A' && p.[1] <= 'Z') || (p.[1] >= 'a' && p.[1] <= 'z'))
    && p.[2] = ':'
  then String.sub p 1 (String.length p - 1)
  else p

let active_env_for ~vault_root =
  Option.bind (user_config_path ()) (fun path ->
      Option.bind (table_of_file path) (fun t ->
          Option.bind (sub_table "active_envs" t) (fun actives ->
              let lookup key =
                match find_key key actives with
                | Some (Toml.Types.TString name) -> Some name
                | _ -> None
              in
              match lookup vault_root with
              | Some name -> Some name
              | None -> (
                  match lookup (normalize vault_root) with
                  | Some name -> Some name
                  | None ->
                      (* Windows paths are case-insensitive and the
                         drive letter case differs between producers.
                         [Key.to_string] quotes non-bare keys, so strip
                         the quotes before comparing. *)
                      let unquote s =
                        let n = String.length s in
                        if n >= 2 && s.[0] = '"' && s.[n - 1] = '"' then
                          String.sub s 1 (n - 2)
                        else s
                      in
                      let want =
                        String.lowercase_ascii (normalize vault_root)
                      in
                      Toml.Types.Table.fold
                        (fun k v acc ->
                          match (acc, v) with
                          | Some _, _ -> acc
                          | None, Toml.Types.TString name
                            when String.lowercase_ascii
                                   (normalize
                                      (unquote
                                         (Toml.Types.Table.Key.to_string k)))
                                 = want ->
                              Some name
                          | None, _ -> None)
                        actives None))))

let names_of_section table section ~secret =
  match sub_table section table with
  | None -> []
  | Some s ->
      Toml.Types.Table.fold
        (fun k _ acc -> (Toml.Types.Table.Key.to_string k, secret) :: acc)
        s []

let names_of_file path =
  match table_of_file path with
  | None -> []
  | Some t ->
      names_of_section t "vars" ~secret:false
      @ names_of_section t "secrets" ~secret:true

(** [(key, is_secret)] pairs of the document's vault active environment
    ([envs/<active>.toml] plus the [.local.toml] override); [[]] when the doc is
    outside a vault, no env is active, or any read fails — analysis degrades
    gracefully, env names are an enrichment, not a requirement. *)
let keys_for ~file_path =
  let file_path = strip_drive_slash file_path in
  match find_vault_root (Filename.dirname file_path) with
  | None -> []
  | Some root -> (
      match active_env_for ~vault_root:root with
      | None -> []
      | Some env ->
          names_of_file (root / "envs" / (env ^ ".toml"))
          @ names_of_file (root / "envs" / (env ^ ".local.toml"))
          |> List.sort_uniq compare
          |> List.fold_left
               (fun acc (k, s) ->
                 match acc with
                 | (k', _) :: _ when k' = k -> acc
                 | _ -> (k, s) :: acc)
               []
          |> List.rev)
