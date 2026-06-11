(* Integration test: drives the real httui-lsp binary over stdio with
   JSON-RPC and asserts the diagnostics/hover/completion behavior end to
   end. This is the headless E2E gate for the language features. *)

let failures = ref 0

let check name cond =
  if cond then Printf.printf "ok - %s\n" name
  else begin
    incr failures;
    Printf.printf "FAIL - %s\n" name
  end

let server = "../bin/httui-lsp/httui_lsp.exe"

type client = { ic : in_channel; oc : out_channel }

let spawn_server ?(args = []) () =
  let from_server, server_stdout = Unix.pipe () in
  let server_stdin, to_server = Unix.pipe () in
  let _pid =
    Unix.create_process server
      (Array.of_list (server :: args))
      server_stdin server_stdout Unix.stderr
  in
  Unix.close server_stdout;
  Unix.close server_stdin;
  {
    ic = Unix.in_channel_of_descr from_server;
    oc = Unix.out_channel_of_descr to_server;
  }

let c1 = spawn_server ()

let send_to client json =
  let body = Yojson.Safe.to_string json in
  Printf.fprintf client.oc "Content-Length: %d\r\n\r\n%s" (String.length body)
    body;
  flush client.oc

let recv_from client =
  let len = ref (-1) in
  let rec headers () =
    let line = input_line client.ic in
    let line =
      let n = String.length line in
      if n > 0 && line.[n - 1] = '\r' then String.sub line 0 (n - 1) else line
    in
    if line = "" then ()
    else begin
      (match String.index_opt line ':' with
      | Some i
        when String.lowercase_ascii (String.sub line 0 i) = "content-length" ->
          len :=
            int_of_string
              (String.trim
                 (String.sub line (i + 1) (String.length line - i - 1)))
      | _ -> ());
      headers ()
    end
  in
  headers ();
  Yojson.Safe.from_string (really_input_string client.ic !len)

let send json = send_to c1 json
let recv () = recv_from c1
let member k json = match json with `Assoc l -> List.assoc_opt k l | _ -> None

let contains hay needle =
  let n = String.length needle in
  let rec go i =
    i + n <= String.length hay && (String.sub hay i n = needle || go (i + 1))
  in
  go 0

let doc_bad =
  "# nota\n\n\
   ```http alias=req1\n\
   GET https://api.example.com/users\n\
   ```\n\n\
   ```http alias=req2\n\
   GET https://x.dev/{{ghost.id}}?u={{req1.body.id}}\n\
   ```\n"

let doc_fixed =
  "# nota\n\n\
   ```http alias=ghost\n\
   GET https://api.example.com/users\n\
   ```\n\n\
   ```http alias=req2\n\
   GET https://x.dev/{{ghost.id}}\n\
   ```\n"

(* [params = None] omits the field entirely — Jsonrpc rejects
   [params: null] (spec-strict) *)
let req ?params id method_ =
  `Assoc
    ([
       ("jsonrpc", `String "2.0"); ("id", `Int id); ("method", `String method_);
     ]
    @ match params with Some p -> [ ("params", p) ] | None -> [])

let notif ?params method_ =
  `Assoc
    ([ ("jsonrpc", `String "2.0"); ("method", `String method_) ]
    @ match params with Some p -> [ ("params", p) ] | None -> [])

let text_doc = `Assoc [ ("uri", `String "file:///t.md") ]

let () =
  (* initialize *)
  send
    (req 1 "initialize"
       ~params:
         (`Assoc
            [
              ("processId", `Null);
              ("rootUri", `Null);
              ("capabilities", `Assoc []);
            ]));
  let init = recv () in
  let caps = Option.bind (member "result" init) (member "capabilities") in
  check "initialize declares hover"
    (Option.bind caps (member "hoverProvider") = Some (`Bool true));
  check "initialize declares completion"
    (Option.is_some (Option.bind caps (member "completionProvider")));
  (* vanilla client did not announce httui.* kinds: the legend must hold
     only the downgraded fallbacks *)
  let legend_types =
    Option.bind
      (Option.bind
         (Option.bind caps (member "semanticTokensProvider"))
         (member "legend"))
      (member "tokenTypes")
  in
  check "vanilla legend downgrades to fallbacks"
    (legend_types
    = Some
        (`List
           [
             `String "keyword";
             `String "parameter";
             `String "property";
             `String "string";
             `String "variable";
           ]));
  send (notif "initialized" ~params:(`Assoc []));

  (* didOpen pushes diagnostics for the unknown alias *)
  send
    (notif "textDocument/didOpen"
       ~params:
         (`Assoc
            [
              ( "textDocument",
                `Assoc
                  [
                    ("uri", `String "file:///t.md");
                    ("languageId", `String "markdown");
                    ("version", `Int 1);
                    ("text", `String doc_bad);
                  ] );
            ]));
  let diag1 = recv () in
  check "publishDiagnostics notification"
    (member "method" diag1 = Some (`String "textDocument/publishDiagnostics"));
  let diags =
    match Option.bind (member "params" diag1) (member "diagnostics") with
    | Some (`List l) -> l
    | _ -> []
  in
  check "one diagnostic for ghost" (List.length diags = 1);
  check "diagnostic message names ghost"
    (match List.nth_opt diags 0 with
    | Some d -> (
        match member "message" d with
        | Some (`String m) -> contains m "ghost"
        | _ -> false)
    | None -> false);

  (* hover over ghost (line 7, character 21) *)
  send
    (req 2 "textDocument/hover"
       ~params:
         (`Assoc
            [
              ("textDocument", text_doc);
              ("position", `Assoc [ ("line", `Int 7); ("character", `Int 21) ]);
            ]));
  let hov = recv () in
  check "hover says unknown"
    (match
       Option.bind
         (Option.bind (member "result" hov) (member "contents"))
         (member "value")
     with
    | Some (`String v) -> contains v "unknown"
    | _ -> false);

  (* completion right after the second {{ (line 7, character 35) *)
  send
    (req 3 "textDocument/completion"
       ~params:
         (`Assoc
            [
              ("textDocument", text_doc);
              ("position", `Assoc [ ("line", `Int 7); ("character", `Int 35) ]);
            ]));
  let comp = recv () in
  check "completion offers req1"
    (match member "result" comp with
    | Some (`List (item :: _)) -> member "label" item = Some (`String "req1")
    | _ -> false);

  (* didChange fixing the alias clears diagnostics *)
  send
    (notif "textDocument/didChange"
       ~params:
         (`Assoc
            [
              ( "textDocument",
                `Assoc [ ("uri", `String "file:///t.md"); ("version", `Int 2) ]
              );
              ( "contentChanges",
                `List [ `Assoc [ ("text", `String doc_fixed) ] ] );
            ]));
  let diag2 = recv () in
  let diags2 =
    match Option.bind (member "params" diag2) (member "diagnostics") with
    | Some (`List l) -> l
    | _ -> [ `Null ]
  in
  check "diagnostics cleared after fix" (diags2 = []);

  (* semantic tokens on the vanilla client: data well-formed *)
  send
    (req 4 "textDocument/semanticTokens/full"
       ~params:(`Assoc [ ("textDocument", text_doc) ]));
  let toks = recv () in
  let data =
    match Option.bind (member "result" toks) (member "data") with
    | Some (`List l) -> l
    | _ -> []
  in
  check "semantic tokens data non-empty, stride 5"
    (List.length data > 0 && List.length data mod 5 = 0);

  (* shutdown / exit *)
  send (req 9 "shutdown");
  let _ = recv () in
  send (notif "exit");

  (* --- second client: announces httui.* kinds and modifiers --- *)
  let c2 = spawn_server () in
  send_to c2
    (req 1 "initialize"
       ~params:
         (`Assoc
            [
              ("processId", `Null);
              ("rootUri", `Null);
              ( "capabilities",
                `Assoc
                  [
                    ( "textDocument",
                      `Assoc
                        [
                          ( "semanticTokens",
                            `Assoc
                              [
                                ("requests", `Assoc [ ("full", `Bool true) ]);
                                ( "tokenTypes",
                                  `List
                                    [
                                      `String "variable";
                                      `String "property";
                                      `String "httui.alias";
                                      `String "httui.env_var";
                                      `String "httui.ref_path";
                                    ] );
                                ( "tokenModifiers",
                                  `List
                                    [
                                      `String "declaration";
                                      `String "unresolved";
                                    ] );
                                ("formats", `List [ `String "relative" ]);
                              ] );
                        ] );
                  ] );
            ]));
  let init2 = recv_from c2 in
  let caps2 = Option.bind (member "result" init2) (member "capabilities") in
  let legend2 =
    match
      Option.bind
        (Option.bind
           (Option.bind caps2 (member "semanticTokensProvider"))
           (member "legend"))
        (member "tokenTypes")
    with
    | Some (`List l) -> l
    | _ -> []
  in
  check "announcing client gets httui.* legend"
    (List.mem (`String "httui.alias") legend2
    && List.mem (`String "httui.ref_path") legend2);
  send_to c2 (notif "initialized" ~params:(`Assoc []));
  send_to c2
    (notif "textDocument/didOpen"
       ~params:
         (`Assoc
            [
              ( "textDocument",
                `Assoc
                  [
                    ("uri", `String "file:///t.md");
                    ("languageId", `String "markdown");
                    ("version", `Int 1);
                    ("text", `String doc_bad);
                  ] );
            ]));
  let _diag = recv_from c2 in
  send_to c2
    (req 2 "textDocument/semanticTokens/full"
       ~params:(`Assoc [ ("textDocument", text_doc) ]));
  let toks2 = recv_from c2 in
  let data2 =
    match Option.bind (member "result" toks2) (member "data") with
    | Some (`List l) -> List.map (function `Int i -> i | _ -> -1) l
    | _ -> []
  in
  (* legend (sorted): httui.alias=0, httui.env_var=1, httui.ref_path=2,
     keyword=3, parameter=4, property=5, string=6. Opening fence of req1
     on line 2: lang [http] at char 3 (keyword), info [alias=] at char 8
     (parameter), declaration [req1] at char 14 (httui.alias, declaration
     bit), then [GET] on line 3 (keyword). *)
  check "tokens start with fence lang, info, alias decl, method"
    (match data2 with
    | 2 :: 3 :: 4 :: 3 :: 0 (* ```http -> lang *) :: 0 :: 5 :: 6 :: 4
      :: 0 (* alias= -> fence info *) :: 0 :: 6 :: 4 :: 0
      :: 1 (* req1 -> alias declaration *) :: 1 :: 0 :: 3 :: 3
      :: 0 (* GET -> method *) :: _ ->
        true
    | _ -> false);
  send_to c2 (req 9 "shutdown");
  let _ = recv_from c2 in
  send_to c2 (notif "exit");

  (* --- third client: --db fixture enriches completion with env keys --- *)
  let db_path, db_exec =
    let path = Filename.temp_file "httui-lsp-test" ".db" in
    Sys.remove path;
    match Caqti_blocking.connect (Uri.of_string ("sqlite3:" ^ path)) with
    | Error e -> failwith (Caqti_error.show e)
    | Ok conn ->
        let module C = (val conn : Caqti_blocking.CONNECTION) in
        let exec sql =
          let open Caqti_request.Infix in
          match C.exec ((Caqti_type.unit ->. Caqti_type.unit) sql) () with
          | Ok () -> ()
          | Error e -> failwith (Caqti_error.show e)
        in
        exec
          "CREATE TABLE environments (id TEXT PRIMARY KEY, name TEXT, \
           is_active INTEGER NOT NULL DEFAULT 0)";
        exec
          "CREATE TABLE env_variables (id TEXT PRIMARY KEY, environment_id \
           TEXT, key TEXT, value TEXT, is_secret INTEGER NOT NULL DEFAULT 0)";
        exec "INSERT INTO environments VALUES ('e1', 'dev', 1)";
        exec "INSERT INTO env_variables VALUES ('v1', 'e1', 'BASE_URL', '', 0)";
        exec
          "INSERT INTO env_variables VALUES ('v2', 'e1', 'API_TOKEN', \
           '__KEYCHAIN__', 1)";
        exec
          "CREATE TABLE block_schema_cache (file_path TEXT NOT NULL, alias \
           TEXT NOT NULL, shape TEXT NOT NULL, cache_schema_version INTEGER \
           NOT NULL, updated_at TEXT, PRIMARY KEY (file_path, alias))";
        exec
          "CREATE TABLE block_results (id INTEGER PRIMARY KEY AUTOINCREMENT, \
           file_path TEXT, block_hash TEXT, alias TEXT, status TEXT, response \
           TEXT, elapsed_ms INTEGER, total_rows INTEGER, executed_at TEXT)";
        (path, exec)
  in
  let c3 = spawn_server ~args:[ "--db"; db_path ] () in
  send_to c3
    (req 1 "initialize"
       ~params:
         (`Assoc
            [
              ("processId", `Null);
              ("rootUri", `Null);
              ("capabilities", `Assoc []);
            ]));
  let _ = recv_from c3 in
  send_to c3 (notif "initialized" ~params:(`Assoc []));
  send_to c3
    (notif "textDocument/didOpen"
       ~params:
         (`Assoc
            [
              ( "textDocument",
                `Assoc
                  [
                    ("uri", `String "file:///t.md");
                    ("languageId", `String "markdown");
                    ("version", `Int 1);
                    ("text", `String doc_bad);
                  ] );
            ]));
  let _ = recv_from c3 in
  send_to c3
    (req 2 "textDocument/completion"
       ~params:
         (`Assoc
            [
              ("textDocument", text_doc);
              ("position", `Assoc [ ("line", `Int 7); ("character", `Int 35) ]);
            ]));
  let comp3 = recv_from c3 in
  let comp3_labels =
    match member "result" comp3 with
    | Some (`List items) -> List.filter_map (fun i -> member "label" i) items
    | _ -> []
  in
  check "completion includes env keys from --db"
    (List.mem (`String "BASE_URL") comp3_labels
    && List.mem (`String "API_TOKEN") comp3_labels
    && List.mem (`String "req1") comp3_labels);
  check "secret env key is marked in detail"
    (match member "result" comp3 with
    | Some (`List items) ->
        List.exists
          (fun i ->
            member "label" i = Some (`String "API_TOKEN")
            && member "detail" i
               = Some (`String "environment variable (secret)"))
          items
    | _ -> false);

  (* --- typed refs: a block run lands a shape, httui/refresh republishes ---
     the row is keyed vault-relative (one of the two writer conventions);
     the server matches it against the URI's absolute path by suffix *)
  db_exec
    "INSERT INTO block_schema_cache VALUES ('t.md', 'req1', \
     '{\"body\":{\"id\":\"number\",\"name\":\"string\"}}', 1, '')";
  send_to c3 (notif "httui/refresh");
  let rdiag = recv_from c3 in
  check "refresh republishes diagnostics"
    (member "method" rdiag = Some (`String "textDocument/publishDiagnostics"));
  let rdiags =
    match Option.bind (member "params" rdiag) (member "diagnostics") with
    | Some (`List l) -> l
    | _ -> []
  in
  (* doc_bad's [{{req1.body.id}}] skips the [response] envelope segment,
     so the fresh shape turns it into a field warning next to the ghost
     error *)
  check "shape adds a field warning" (List.length rdiags = 2);
  check "field warning is severity warning with message"
    (List.exists
       (fun d ->
         member "severity" d = Some (`Int 2)
         &&
         match member "message" d with
         | Some (`String m) -> contains m "not found"
         | _ -> false)
       rdiags);

  (* a correct path is quiet; an open path completes with typed fields *)
  let doc_typed =
    "# nota\n\n\
     ```http alias=req1\n\
     GET https://api.example.com/users\n\
     ```\n\n\
     ```http alias=req2\n\
     GET https://x.dev/{{req1.response.body.id}}?n={{req1.response.\n\
     ```\n"
  in
  send_to c3
    (notif "textDocument/didChange"
       ~params:
         (`Assoc
            [
              ( "textDocument",
                `Assoc [ ("uri", `String "file:///t.md"); ("version", `Int 2) ]
              );
              ( "contentChanges",
                `List [ `Assoc [ ("text", `String doc_typed) ] ] );
            ]));
  let tdiag = recv_from c3 in
  check "valid typed path publishes no diagnostics"
    (Option.bind (member "params" tdiag) (member "diagnostics")
    = Some (`List []));
  send_to c3
    (req 3 "textDocument/completion"
       ~params:
         (`Assoc
            [
              ("textDocument", text_doc);
              ("position", `Assoc [ ("line", `Int 7); ("character", `Int 62) ]);
            ]));
  let comp4 = recv_from c3 in
  check "path completion offers shape fields with type detail"
    (match member "result" comp4 with
    | Some (`List [ item ]) ->
        member "label" item = Some (`String "body")
        && member "detail" item = Some (`String "object")
        && member "kind" item = Some (`Int 5)
    | _ -> false);
  send_to c3
    (req 4 "textDocument/hover"
       ~params:
         (`Assoc
            [
              ("textDocument", text_doc);
              ("position", `Assoc [ ("line", `Int 7); ("character", `Int 39) ]);
            ]));
  let hov4 = recv_from c3 in
  check "hover on a typed leaf shows the field type"
    (match
       Option.bind
         (Option.bind (member "result" hov4) (member "contents"))
         (member "value")
     with
    | Some (`String v) -> contains v "number"
    | _ -> false);

  (* a successful run lands a response row; hover then previews the value *)
  db_exec
    "INSERT INTO block_results (file_path, block_hash, alias, status, \
     response) VALUES ('t.md', 'h1', 'req1', 'success', \
     '{\"body\":{\"id\":42,\"name\":\"ana\"}}')";
  send_to c3
    (req 5 "textDocument/hover"
       ~params:
         (`Assoc
            [
              ("textDocument", text_doc);
              ("position", `Assoc [ ("line", `Int 7); ("character", `Int 39) ]);
            ]));
  let hov5 = recv_from c3 in
  check "hover previews the last value"
    (match
       Option.bind
         (Option.bind (member "result" hov5) (member "contents"))
         (member "value")
     with
    | Some (`String v) -> contains v "last value: `42`"
    | _ -> false);

  send_to c3 (req 9 "shutdown");
  let _ = recv_from c3 in
  send_to c3 (notif "exit");
  (* best effort: on Windows the server may still hold the file *)
  (try Sys.remove db_path with Sys_error _ -> ());

  if !failures > 0 then exit 1
