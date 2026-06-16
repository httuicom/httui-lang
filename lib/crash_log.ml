(** Local crash-log files under [$HOME/.config/httui/crashes], matching the
    desktop's [httui_core::crash_log] convention so its "Crashes" settings panel
    can surface language-server panics alongside the app's own. Files are plain
    text named [<epoch_ms>-<source>.log]; nothing is uploaded. *)

(** [$HOME/.config/httui/crashes], or [None] when [HOME] is unset. *)
let crashes_dir () =
  match Sys.getenv_opt "HOME" with
  | Some home ->
      Some (Filename.concat home (Filename.concat ".config/httui" "crashes"))
  | None -> None

(* Keep a source tag to [A-Za-z0-9_] so it can never inject a path separator
   or break the [<ms>-<source>.log] shape. *)
let sanitize_source s =
  String.map
    (fun c ->
      let ok =
        (c >= 'a' && c <= 'z')
        || (c >= 'A' && c <= 'Z')
        || (c >= '0' && c <= '9')
        || c = '_'
      in
      if ok then c else '_')
    s

let rec mkdir_p dir =
  if dir = "" || dir = "/" || dir = "." || Sys.file_exists dir then ()
  else begin
    mkdir_p (Filename.dirname dir);
    try Unix.mkdir dir 0o755 with Unix.Unix_error (Unix.EEXIST, _, _) -> ()
  end

(** Write [body] as a crash file in [dir], returning its name on success.
    Best-effort: any failure yields [None] and never raises, since this runs
    from a crash path where a second failure must not escalate. *)
let write_to ~dir ~source ~body =
  try
    mkdir_p dir;
    let ms = int_of_float (Unix.gettimeofday () *. 1000.) in
    let name = Printf.sprintf "%d-%s.log" ms (sanitize_source source) in
    (* Binary mode: write bytes verbatim so a crash body is identical on every
       platform (no Windows CRLF translation), matching the desktop's
       byte-exact writer. *)
    let oc = open_out_bin (Filename.concat dir name) in
    output_string oc body;
    close_out oc;
    Some name
  with _ -> None

(** Write to the default crashes directory. [None] if [HOME] is unset or the
    write fails. *)
let write ~source ~body =
  match crashes_dir () with
  | None -> None
  | Some dir -> write_to ~dir ~source ~body
