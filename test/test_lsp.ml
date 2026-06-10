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

let proc_out, proc_in =
  let from_server, server_stdout = Unix.pipe () in
  let server_stdin, to_server = Unix.pipe () in
  let _pid =
    Unix.create_process server [| server |] server_stdin server_stdout
      Unix.stderr
  in
  Unix.close server_stdout;
  Unix.close server_stdin;
  (Unix.in_channel_of_descr from_server, Unix.out_channel_of_descr to_server)

let send json =
  let body = Yojson.Safe.to_string json in
  Printf.fprintf proc_in "Content-Length: %d\r\n\r\n%s" (String.length body)
    body;
  flush proc_in

let recv () =
  let len = ref (-1) in
  let rec headers () =
    let line = input_line proc_out in
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
  Yojson.Safe.from_string (really_input_string proc_out !len)

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

  (* shutdown / exit *)
  send (req 9 "shutdown");
  let _ = recv () in
  send (notif "exit");
  if !failures > 0 then exit 1
