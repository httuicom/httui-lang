(* httui-lsp — Language Server for httui blocks and references.

   Pure OCaml: an IO shell (stdio framing + JSON-RPC dispatch) around the
   pure [Httui_lang] library. Storage access, when it arrives, is
   read-only by design; the server never touches the OS keychain — secret
   values exist only on the execution path, outside this process. *)

module T = Lsp.Types

let docs : (string, T.DocumentUri.t * string) Hashtbl.t = Hashtbl.create 16

(* --- stdio framing ----------------------------------------------------- *)

let read_message () =
  let len = ref (-1) in
  let rec read_headers () =
    let line = input_line stdin in
    let line =
      let n = String.length line in
      if n > 0 && line.[n - 1] = '\r' then String.sub line 0 (n - 1) else line
    in
    if line = "" then ()
    else begin
      (match String.index_opt line ':' with
      | Some i ->
          let key = String.lowercase_ascii (String.sub line 0 i) in
          if key = "content-length" then
            len :=
              int_of_string
                (String.trim
                   (String.sub line (i + 1) (String.length line - i - 1)))
      | None -> ());
      read_headers ()
    end
  in
  read_headers ();
  if !len < 0 then failwith "missing content-length header";
  really_input_string stdin !len

let write_packet packet =
  let body = Yojson.Safe.to_string (Jsonrpc.Packet.yojson_of_t packet) in
  Printf.printf "Content-Length: %d\r\n\r\n%s" (String.length body) body;
  flush stdout

let respond id json =
  write_packet (Jsonrpc.Packet.Response (Jsonrpc.Response.ok id json))

let respond_error id code message =
  write_packet
    (Jsonrpc.Packet.Response
       (Jsonrpc.Response.error id
          (Jsonrpc.Response.Error.make ~code ~message ())))

let notify method_ json =
  write_packet
    (Jsonrpc.Packet.Notification
       (Jsonrpc.Notification.create ~method_
          ~params:(Jsonrpc.Structured.t_of_yojson json)
          ()))

(* --- analysis glue ------------------------------------------------------ *)

let position_of_offset text off =
  let p = Httui_lang.Doc_position.of_offset text off in
  T.Position.create ~line:p.line ~character:p.character

let range_of_offsets text ~start ~stop =
  T.Range.create
    ~start:(position_of_offset text start)
    ~end_:(position_of_offset text stop)

let offset_of_position text (pos : T.Position.t) =
  Httui_lang.Doc_position.to_offset text
    { line = pos.line; character = pos.character }

(* shapes are read per request/publish: they change whenever the user
   runs a block, and the read is microseconds against a local sqlite *)
let shapes_for_uri uri =
  Schema_store.shapes_for ~file_path:(T.DocumentUri.to_path uri)

let values_for_uri uri =
  Result_store.values_for ~file_path:(T.DocumentUri.to_path uri)

let publish_diagnostics uri text =
  let blocks = Httui_lang.Fence_scanner.scan text in
  let diagnostics =
    Httui_lang.Analyze.diagnostics ~shapes:(shapes_for_uri uri) blocks
    |> List.map (fun (d : Httui_lang.Analyze.diagnostic) ->
        T.Diagnostic.create
          ~range:(range_of_offsets text ~start:d.start_ ~stop:d.stop_)
          ~severity:
            (match d.severity with
            | Httui_lang.Analyze.Error -> T.DiagnosticSeverity.Error
            | Httui_lang.Analyze.Warning -> T.DiagnosticSeverity.Warning)
          ~source:"httui" ~message:(`String d.message) ())
  in
  let params = T.PublishDiagnosticsParams.create ~uri ~diagnostics () in
  notify "textDocument/publishDiagnostics"
    (T.PublishDiagnosticsParams.yojson_of_t params)

let doc_updated uri text =
  Hashtbl.replace docs (T.DocumentUri.to_string uri) (uri, text);
  publish_diagnostics uri text

(* --- handlers ----------------------------------------------------------- *)

let params_json (params : Jsonrpc.Structured.t option) =
  match params with Some p -> Jsonrpc.Structured.yojson_of_t p | None -> `Null

(* --- semantic tokens legend (per-client, server-side downgrade) --------- *)

(* Token types are unique per range and clients silently ignore types
   outside their announced capabilities, so the legend is computed at
   initialize: an httui.* kind is registered only when the client
   announced it; otherwise its LSP-standard fallback takes the slot. *)

let legend_types = ref [ "variable"; "property" ]
let legend_modifiers = ref ([] : string list)

let compute_legend ~announced_types ~announced_modifiers =
  let pick preferred fallback =
    if List.mem preferred announced_types then preferred else fallback
  in
  let names =
    [
      pick "httui.alias" "variable";
      pick "httui.env_var" "variable";
      pick "httui.ref_path" "property";
    ]
  in
  legend_types := List.sort_uniq compare names;
  legend_modifiers :=
    List.filter
      (fun m -> List.mem m announced_modifiers)
      [ "declaration"; "unresolved" ]

let type_index (kind : Httui_lang.Semantic_tokens.kind) =
  let name =
    let mem n = List.mem n !legend_types in
    match kind with
    | Httui_lang.Semantic_tokens.Alias ->
        if mem "httui.alias" then "httui.alias" else "variable"
    | Httui_lang.Semantic_tokens.Env_var ->
        if mem "httui.env_var" then "httui.env_var" else "variable"
    | Httui_lang.Semantic_tokens.Ref_path ->
        if mem "httui.ref_path" then "httui.ref_path" else "property"
  in
  let rec idx i = function
    | [] -> 0
    | x :: rest -> if x = name then i else idx (i + 1) rest
  in
  idx 0 !legend_types

let modifier_bits (t : Httui_lang.Semantic_tokens.t) =
  List.fold_left
    (fun bits (i, m) ->
      let active =
        (m = "declaration" && t.declaration)
        || (m = "unresolved" && t.unresolved)
      in
      if active then bits lor (1 lsl i) else bits)
    0
    (List.mapi (fun i m -> (i, m)) !legend_modifiers)

let on_initialize (r : Jsonrpc.Request.t) =
  (try
     let p = T.InitializeParams.t_of_yojson (params_json r.params) in
     match p.capabilities.textDocument with
     | Some td -> (
         match td.semanticTokens with
         | Some st ->
             compute_legend ~announced_types:st.tokenTypes
               ~announced_modifiers:st.tokenModifiers
         | None -> compute_legend ~announced_types:[] ~announced_modifiers:[])
     | None -> compute_legend ~announced_types:[] ~announced_modifiers:[]
   with _ -> compute_legend ~announced_types:[] ~announced_modifiers:[]);
  let capabilities =
    T.ServerCapabilities.create
      ~textDocumentSync:
        (`TextDocumentSyncOptions
           (T.TextDocumentSyncOptions.create ~openClose:true
              ~change:T.TextDocumentSyncKind.Full ()))
      ~hoverProvider:(`Bool true)
      ~completionProvider:
        (T.CompletionOptions.create ~triggerCharacters:[ "{" ] ())
      ~semanticTokensProvider:
        (`SemanticTokensOptions
           (T.SemanticTokensOptions.create
              ~legend:
                (T.SemanticTokensLegend.create ~tokenTypes:!legend_types
                   ~tokenModifiers:!legend_modifiers)
              ~full:(`Bool true) ()))
      ()
  in
  let serverInfo =
    T.InitializeResult.create_serverInfo ~name:"httui-lsp"
      ~version:Httui_lang.Version.v ()
  in
  let result = T.InitializeResult.create ~capabilities ~serverInfo () in
  respond r.id (T.InitializeResult.yojson_of_t result)

let with_doc id uri k =
  match Hashtbl.find_opt docs (T.DocumentUri.to_string uri) with
  | None -> respond id `Null
  | Some (_, text) -> k text

let on_hover (r : Jsonrpc.Request.t) =
  let p = T.HoverParams.t_of_yojson (params_json r.params) in
  with_doc r.id p.textDocument.uri (fun text ->
      let blocks = Httui_lang.Fence_scanner.scan text in
      let offset = offset_of_position text p.position in
      match
        Httui_lang.Analyze.hover_at ~env_keys:(Env_store.keys ())
          ~shapes:(shapes_for_uri p.textDocument.uri)
          ~values:(values_for_uri p.textDocument.uri)
          blocks ~offset
      with
      | None -> respond r.id `Null
      | Some h ->
          let hover =
            T.Hover.create
              ~contents:
                (`MarkupContent
                   (T.MarkupContent.create ~kind:T.MarkupKind.Markdown
                      ~value:h.markdown))
              ~range:(range_of_offsets text ~start:h.h_start ~stop:h.h_stop)
              ()
          in
          respond r.id (T.Hover.yojson_of_t hover))

let on_completion (r : Jsonrpc.Request.t) =
  let p = T.CompletionParams.t_of_yojson (params_json r.params) in
  with_doc r.id p.textDocument.uri (fun text ->
      let blocks = Httui_lang.Fence_scanner.scan text in
      let offset = offset_of_position text p.position in
      let items =
        Httui_lang.Analyze.completion_at ~env_keys:(Env_store.keys ())
          ~shapes:(shapes_for_uri p.textDocument.uri)
          text blocks ~offset
        |> List.map (fun (it : Httui_lang.Analyze.completion_item) ->
            match it.field_type with
            | Some type_ ->
                T.CompletionItem.create ~label:it.label
                  ~kind:T.CompletionItemKind.Field ~detail:type_ ()
            | None ->
                if it.is_env then
                  T.CompletionItem.create ~label:it.label
                    ~kind:T.CompletionItemKind.Constant
                    ~detail:
                      (if it.secret then "environment variable (secret)"
                       else "environment variable")
                    ()
                else
                  T.CompletionItem.create ~label:it.label
                    ~kind:T.CompletionItemKind.Variable ~detail:"block alias" ())
      in
      respond r.id (`List (List.map T.CompletionItem.yojson_of_t items)))

let on_semantic_tokens (r : Jsonrpc.Request.t) =
  let p = T.SemanticTokensParams.t_of_yojson (params_json r.params) in
  with_doc r.id p.textDocument.uri (fun text ->
      let blocks = Httui_lang.Fence_scanner.scan text in
      let tokens = Httui_lang.Semantic_tokens.of_blocks blocks in
      let data =
        let prev_line = ref 0 and prev_char = ref 0 in
        List.concat_map
          (fun (t : Httui_lang.Semantic_tokens.t) ->
            let pos = Httui_lang.Doc_position.of_offset text t.t_start in
            let length =
              Httui_lang.Doc_position.utf16_units text ~from:t.t_start
                ~until:t.t_stop
            in
            let dl = pos.line - !prev_line in
            let dc =
              if dl = 0 then pos.character - !prev_char else pos.character
            in
            prev_line := pos.line;
            prev_char := pos.character;
            [ dl; dc; length; type_index t.kind; modifier_bits t ])
          tokens
      in
      let result = T.SemanticTokens.create ~data:(Array.of_list data) () in
      respond r.id (T.SemanticTokens.yojson_of_t result))

let shutdown_received = ref false

let handle_request (r : Jsonrpc.Request.t) =
  match r.method_ with
  | "initialize" -> on_initialize r
  | "textDocument/hover" -> on_hover r
  | "textDocument/completion" -> on_completion r
  | "textDocument/semanticTokens/full" -> on_semantic_tokens r
  | "shutdown" ->
      shutdown_received := true;
      respond r.id `Null
  | m -> respond_error r.id Jsonrpc.Response.Error.Code.MethodNotFound m

let handle_notification (n : Jsonrpc.Notification.t) =
  match n.method_ with
  | "initialized" -> ()
  | "textDocument/didOpen" ->
      let p = T.DidOpenTextDocumentParams.t_of_yojson (params_json n.params) in
      doc_updated p.textDocument.uri p.textDocument.text
  | "textDocument/didChange" -> (
      let p =
        T.DidChangeTextDocumentParams.t_of_yojson (params_json n.params)
      in
      (* Full sync: the last change event carries the whole document. *)
      match List.rev p.contentChanges with
      | last :: _ -> doc_updated p.textDocument.uri last.text
      | [] -> ())
  | "textDocument/didClose" ->
      let p = T.DidCloseTextDocumentParams.t_of_yojson (params_json n.params) in
      Hashtbl.remove docs (T.DocumentUri.to_string p.textDocument.uri)
  | "exit" -> exit (if !shutdown_received then 0 else 1)
  (* custom: the client signals that a block ran, so inferred shapes may
     have changed — re-publish diagnostics for every open document *)
  | "httui/refresh" ->
      Hashtbl.iter (fun _ (uri, text) -> publish_diagnostics uri text) docs
  | _ -> ()

(* --- main loop ---------------------------------------------------------- *)

let () =
  (* --db <path>: app database for environment variable NAMES (read-only
     enrichment; the server runs fine without it) *)
  (let rec parse = function
     | "--db" :: path :: rest ->
         Db_conn.configure path;
         parse rest
     | _ :: rest -> parse rest
     | [] -> ()
   in
   parse (Array.to_list Sys.argv));
  set_binary_mode_in stdin true;
  set_binary_mode_out stdout true;
  try
    while true do
      let body = read_message () in
      (* one malformed message must not kill the session — skip it and
         keep serving (EOF still ends the loop) *)
      try
        let json = Yojson.Safe.from_string body in
        match Jsonrpc.Packet.t_of_yojson json with
        | Jsonrpc.Packet.Request r -> handle_request r
        | Jsonrpc.Packet.Notification n -> handle_notification n
        | _ -> ()
      with
      | End_of_file -> raise End_of_file
      | _ -> ()
    done
  with End_of_file -> ()
